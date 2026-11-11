import 'dart:developer';

import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/interfaces/tv_app_control.dart';
import 'package:remote/core/interfaces/tv_input_control.dart';
import 'package:remote/core/interfaces/tv_interface.dart';
import 'package:remote/core/interfaces/tv_text_control.dart';
import 'package:remote/core/interfaces/tv_volume_control.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/services/lg/lg_buttons.dart';
import 'package:remote/services/lg/lg_tv_service.dart';

/// LG webOS implementation of [TVInterface]. Key mapping lives in
/// `lg_buttons.dart`; keys with no webOS equivalent are logged and ignored.
class LGTV
    implements
        TVInterface,
        TvInputControl,
        TvVolumeControl,
        TvAppControl,
        TvTextControl {
  LGTV({
    required String host,
    String? mac,
    String? deviceName,
    String? modelName,
    String? clientKey,
    String? pinnedCertificateSha256,
  }) : _service = LgTvService(
         host: host,
         clientKey: clientKey,
         pinnedCertificateSha256: pinnedCertificateSha256,
       ),
       _host = host,
       _mac = mac,
       _deviceName = deviceName,
       _modelName = modelName;

  final LgTvService _service;
  final String _host;
  String? _mac;
  List<String> wakeAddresses = const [];
  final String? _deviceName;
  final String? _modelName;

  @override
  String? get host => _host;
  @override
  String? get mac => _mac;
  @override
  String? get deviceName => _deviceName;
  @override
  String? get modelName => _modelName;

  @override
  bool get isConnected => _service.isConnected;

  @override
  ConnectionState get connectionState => _service.isConnected
      ? ConnectionState.connected
      : ConnectionState.disconnected;

  String? get clientKey => _service.clientKey;

  @override
  void setOnDisconnectedCallback(void Function(DisconnectionType) callback) {
    _service.onDisconnected = callback;
  }

  @override
  void setOnConnectionStateChangedCallback(
    void Function(ConnectionState) callback,
  ) {
    // Bloc layer derives state — no callback required.
  }

  void setOnClientKeyReceivedCallback(void Function(String key) callback) {
    _service.onClientKeyReceived = callback;
  }

  void setOnCertificatePinnedCallback(void Function(String sha256) callback) {
    _service.onCertificatePinned = callback;
  }

  @override
  Future<void> connect({String appName = 'Smart TV Remote'}) async {
    await _service.connect();
    try {
      wakeAddresses = await _service.wakeMacs();
      if (_mac == null && wakeAddresses.isNotEmpty) _mac = wakeAddresses.first;
    } catch (_) {
      // Older firmware may not expose network information. Pairing stays usable.
    }
  }

  @override
  void disconnect() => _service.disconnect();

  @override
  Future<void> ensureConnection() async {
    if (!_service.isConnected) await _service.connect();
  }

  @override
  Future<void> sendKey(KeyCodes key) async {
    await ensureConnection();
    if (key == KeyCodes.KEY_POWER) {
      await _service.power();
      return;
    }
    final media = lgMediaCommandFor(key);
    if (media != null) {
      await _service.media(media);
      return;
    }
    final button = lgButtonFor(key);
    if (button != null) {
      await _service.sendButton(button);
      return;
    }
    log('LG: no webOS mapping for ${key.name}, ignored');
  }

  Future<void> launchApp(String appId) => _service.launchApp(appId);

  @override
  Future<void> openYouTube() => _service.launchApp('youtube.leanback.v4');
  @override
  Future<void> openNetflix() => _service.launchApp('netflix');
  @override
  Future<void> openPrimeVideo() => _service.launchApp('amazon');
  @override
  Future<void> openDisneyPlus() =>
      _service.launchApp('com.disney.disneyplus-prod');

  @override
  Future<void> insertText(String text) => _service.insertText(text);

  @override
  Future<void> submitText() => _service.submitText();

  @override
  Future<int?> volume() => _service.volume();

  @override
  Future<void> setVolume(int value) => _service.setVolume(value);

  @override
  Future<List<TvInput>> inputs() async {
    final response = await _service.request('ssap://tv/getExternalInputList');
    final devices = response['devices'] as List<dynamic>? ?? [];
    return [
      for (final device in devices.whereType<Map<String, dynamic>>())
        if (device['id'] is String)
          TvInput(
            id: device['id'] as String,
            label: (device['label'] ?? device['id']).toString(),
          ),
    ];
  }

  @override
  Future<void> selectInput(String id) async {
    await _service.request('ssap://tv/switchInput', payload: {'inputId': id});
  }
}
