import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/core/models/tv_device.dart';
import 'package:remote/core/models/tv_mac.dart';
import 'package:remote/core/services/known_tvs_storage.dart';
import 'package:remote/core/services/tv_token_storage.dart';
import 'package:remote/core/services/wake_on_lan_service.dart';
import 'package:remote/implementations/lg_tv.dart';
import 'package:remote/implementations/samsung_tv.dart';
import 'package:remote/services/mdns/bonjour_discovery_service.dart';
import 'package:remote/services/upnp/ssdp_discovery_service.dart';

/// Single coordinator for discovery, connect, send-key, and disconnect.
///
/// The UI talks to a `TvConnectionBloc`; that bloc talks to this repository.
/// Brand specifics (Samsung WSS v2, LG WebOS) live in `lib/implementations/`;
/// the brand is picked per device with [TvBrand.fromDevice].
class TvRepository {
  TvRepository({
    required TvTokenStorage tokenStorage,
    required KnownTvsStorage knownTvsStorage,
    required WakeOnLanService wakeOnLanService,
    required SsdpDiscoveryService ssdpDiscoveryService,
    required BonjourDiscoveryService bonjourDiscoveryService,
    this.wakeRetryDelay = const Duration(seconds: 3),
    this.wakeAttempts = 4,
    bool? isIOS,
  }) : _tokenStorage = tokenStorage,
       _isIOS = isIOS ?? Platform.isIOS,
       _knownTvsStorage = knownTvsStorage,
       _wol = wakeOnLanService,
       _ssdp = ssdpDiscoveryService,
       _bonjour = bonjourDiscoveryService;

  final Duration wakeRetryDelay;
  final int wakeAttempts;
  final bool _isIOS;

  final TvTokenStorage _tokenStorage;
  final KnownTvsStorage _knownTvsStorage;
  final WakeOnLanService _wol;
  final SsdpDiscoveryService _ssdp;
  final BonjourDiscoveryService _bonjour;

  int _sessionEpoch = 0;
  TVInterface? _current;
  TVDevice? _currentDevice;

  TVInterface? get current => _current;
  TVDevice? get currentDevice => _currentDevice;

  /// Runs SSDP and Bonjour sweeps in parallel and merges the results by
  /// host, so a set seen by both shows up once with the richer record.
  Future<List<TVDevice>> discoverAll() async {
    final results = await Future.wait<List<TVDevice>>([
      // Native Bonjour can browse declared services without the restricted
      // multicast entitlement. Raw SSDP cannot on a free iOS profile.
      if (!_isIOS) _sweep('SSDP', _ssdp.discoverAll),
      _sweep('Bonjour', _bonjour.discoverAll),
    ]);
    return TVDevice.mergeByHost([for (final list in results) ...list]);
  }

  /// One discovery sweep; a failure costs its results, never the scan.
  Future<List<TVDevice>> _sweep(
    String name,
    Future<List<TVDevice>> Function() run,
  ) async {
    try {
      return await run();
    } catch (e) {
      log('$name discovery failed: $e');
      return const [];
    }
  }

  /// Connect to [device]. If the TV refuses the connection and we have
  /// its MAC, send a WoL magic packet and retry once.
  Future<TVDevice> configureWake(TVDevice device, String mac) async {
    final normalized = normalizeTvMac(mac);
    if (normalized == null) throw ArgumentError('Informe um MAC válido da TV.');
    final updated = device.copyWith(mac: normalized);
    await _knownTvsStorage.save(updated);
    return updated;
  }

  Future<void> connect(
    TVDevice device, {
    void Function(DisconnectionType)? onDisconnected,
    bool wakeFirst = false,
  }) async {
    await disconnect();
    final epoch = _sessionEpoch;
    final matches = _knownTvsStorage.loadAll().where(
      (saved) => saved.host == device.host,
    );
    final saved = matches.isEmpty ? null : matches.first;
    final target = device.copyWith(
      mac: device.mac ?? saved?.mac,
      additionalInfo: {...?saved?.additionalInfo, ...device.additionalInfo},
    );
    if (!wakeFirst) {
      try {
        await _doConnect(target, onDisconnected: onDisconnected, epoch: epoch);
        return;
      } catch (error) {
        if (!_isRefusedError(error)) rethrow;
      }
    }
    final addresses = <String>{
      if (normalizeTvMac(target.mac) != null) normalizeTvMac(target.mac)!,
      ...((target.additionalInfo['wakeMacs'] as List?) ?? [])
          .whereType<String>()
          .map(normalizeTvMac)
          .whereType<String>(),
    };
    if (addresses.isEmpty) {
      throw StateError(
        'A TV não respondeu e o MAC ainda não está configurado. Toque em Ligar TV para informar o MAC Wi-Fi.',
      );
    }
    var sent = false;
    for (final address in addresses) {
      final delivered = _isIOS
          ? await _wol.wake(mac: address, broadcastIp: target.host ?? '')
          : await _wol.wake(mac: address);
      sent = delivered || sent;
    }
    if (!sent) {
      throw StateError(
        'Não foi possível enviar o comando de ligar. Confira o Wi-Fi do celular e o MAC da TV.',
      );
    }
    for (var attempt = 0; attempt < wakeAttempts; attempt++) {
      if (epoch != _sessionEpoch) throw StateError('Conexão cancelada.');
      await Future<void>.delayed(wakeRetryDelay);
      if (epoch != _sessionEpoch) throw StateError('Conexão cancelada.');
      try {
        await _doConnect(target, onDisconnected: onDisconnected, epoch: epoch);
        return;
      } catch (error) {
        if (!_isRefusedError(error)) rethrow;
      }
    }
    throw StateError(
      _isIOS
          ? 'A TV não respondeu ao comando de ligar pelo iPhone. Esse recurso depende da TV e da rede; ligue a TV pelo controle físico para conectar e confira se o IP mudou.'
          : 'O comando de ligar foi enviado, mas a TV não respondeu. Confira Ligar via Wi-Fi na TV, o MAC e se o IP mudou.',
    );
  }

  Future<void> _doConnect(
    TVDevice device, {
    void Function(DisconnectionType)? onDisconnected,
    int? epoch,
  }) async {
    final brand = TvBrand.fromDevice(device);
    final identifier = _identifierFor(device);
    final tokenKey = identifier != null
        ? _tokenKeyFor(brand, identifier)
        : null;
    final hostKey = device.host == null
        ? null
        : _tokenKeyFor(brand, device.host!);
    final savedToken = tokenKey != null
        ? _tokenStorage.load(tokenKey) ??
              (hostKey == null ? null : _tokenStorage.load(hostKey))
        : null;
    void onDisconnect(DisconnectionType type) => onDisconnected?.call(type);

    final TVInterface tv;
    switch (brand) {
      case TvBrand.samsung:
        final samsung = SamsungTV(
          host: device.host,
          mac: device.mac,
          deviceName: device.deviceName,
          modelName: device.modelName,
          token: savedToken,
        )..setOnDisconnectedCallback(onDisconnect);
        if (tokenKey != null) {
          samsung.setOnTokenReceivedCallback((token) {
            unawaited(_tokenStorage.save(tokenKey, token));
          });
        }
        tv = samsung;
      case TvBrand.lg:
        final host = device.host;
        if (host == null || host.isEmpty) {
          throw ArgumentError('LG TVs need an IP address to connect');
        }
        final certKey = tokenKey != null ? 'cert:$tokenKey' : null;
        final lg = LGTV(
          host: host,
          mac: device.mac,
          deviceName: device.deviceName,
          modelName: device.modelName,
          clientKey: savedToken,
          pinnedCertificateSha256: certKey != null
              ? _tokenStorage.load(certKey) ??
                    (hostKey == null
                        ? null
                        : _tokenStorage.load('cert:$hostKey'))
              : null,
        )..setOnDisconnectedCallback(onDisconnect);
        if (tokenKey != null) {
          lg.setOnClientKeyReceivedCallback((key) {
            unawaited(_tokenStorage.save(tokenKey, key));
          });
        }
        if (certKey != null) {
          lg.setOnCertificatePinnedCallback((fingerprint) {
            unawaited(_tokenStorage.save(certKey, fingerprint));
          });
        }
        tv = lg;
    }

    await tv.connect();
    if (epoch != null && epoch != _sessionEpoch) {
      tv.disconnect();
      throw StateError('Conexão cancelada.');
    }

    // The HTTP info response may have surfaced a MAC the user didn't have.
    final resolved = device.copyWith(
      mac: tv.mac ?? device.mac,
      manufacturer: device.manufacturer ?? brand.manufacturer,
      additionalInfo: {
        ...device.additionalInfo,
        if (tv is LGTV && tv.wakeAddresses.isNotEmpty)
          'wakeMacs': tv.wakeAddresses,
      },
    );

    // The device is keyed by MAC once one is known. If we paired under the
    // host-only key, carry the token over so the next connect doesn't prompt.
    final resolvedIdentifier = _identifierFor(resolved);
    if (tokenKey != null &&
        resolvedIdentifier != null &&
        resolvedIdentifier != identifier) {
      final token = _tokenStorage.load(tokenKey);
      if (token != null) {
        await _tokenStorage.save(
          _tokenKeyFor(brand, resolvedIdentifier),
          token,
        );
      }
    }

    if (tokenKey != null &&
        resolvedIdentifier != null &&
        resolvedIdentifier != identifier) {
      final pin = _tokenStorage.load('cert:$tokenKey');
      if (pin != null) {
        await _tokenStorage.save(
          'cert:${_tokenKeyFor(brand, resolvedIdentifier)}',
          pin,
        );
      }
    }
    _current = tv;
    _currentDevice = resolved;
    await _knownTvsStorage.save(resolved);
    await _knownTvsStorage.saveLastUsed(resolved);
  }

  bool _isRefusedError(Object error) {
    final m = error.toString().toLowerCase();
    return m.contains('connection refused') ||
        m.contains('errno = 111') ||
        m.contains('failed host lookup') ||
        m.contains('timeout') ||
        m.contains('timed out') ||
        m.contains('unreachable') ||
        m.contains('no route to host');
  }

  Future<void> sendKey(KeyCodes key) async {
    final tv = _current;
    if (tv == null) {
      throw StateError('No active TV connection');
    }
    await tv.sendKey(key);
  }

  Future<void> disconnect() async {
    _sessionEpoch++;
    _current?.disconnect();
    _current = null;
    _currentDevice = null;
  }

  /// Drops everything remembered about [device]: pairing token or client
  /// key, pinned certificate, and the known-TV entry. If it is the active
  /// connection, that is closed too.
  Future<void> forget(TVDevice device) async {
    // Credentials may have been saved under the host before the MAC was
    // known, so clear every alias, not just the preferred identifier.
    final aliases = {
      device.mac,
      device.host,
    }.whereType<String>().where((id) => id.isNotEmpty);
    for (final identifier in aliases) {
      for (final brand in TvBrand.values) {
        final key = _tokenKeyFor(brand, identifier);
        await _tokenStorage.clear(key);
        await _tokenStorage.clear('cert:$key');
      }
    }
    await _knownTvsStorage.remove(device);
    final last = _knownTvsStorage.loadLastUsed();
    if (last != null && last.host == device.host) {
      await _knownTvsStorage.clearLastUsed();
    }
    if (_currentDevice != null && _currentDevice!.host == device.host) {
      await disconnect();
    }
  }

  Future<void> forgetCurrent() async {
    final device = _currentDevice;
    if (device != null) {
      await forget(device);
    }
    await disconnect();
    await _knownTvsStorage.clearLastUsed();
  }

  List<TVDevice> knownTvs() => _knownTvsStorage.loadAll();
  TVDevice? lastUsed() => _knownTvsStorage.loadLastUsed();

  /// Samsung tokens keep the bare identifier so existing installs keep
  /// their pairing; other brands are namespaced.
  String _tokenKeyFor(TvBrand brand, String identifier) => switch (brand) {
    TvBrand.samsung => identifier,
    TvBrand.lg => 'lg:$identifier',
  };

  String? _identifierFor(TVDevice device) {
    final mac = device.mac;
    if (mac != null && mac.isNotEmpty) return mac;
    final host = device.host;
    if (host != null && host.isNotEmpty) return host;
    return null;
  }
}
