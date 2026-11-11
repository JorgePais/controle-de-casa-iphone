import 'dart:developer';
import 'dart:io';

import 'package:wake_on_lan/wake_on_lan.dart';

/// Sends Wake-on-LAN magic packets.
///
/// Most Samsung TVs from 2018+ support WoL on the same subnet — useful
/// when the user picks a known TV that the OS reports as offline.
class WakeOnLanService {
  WakeOnLanService({bool? allowBroadcast, this.port = 9})
    : _allowBroadcast = allowBroadcast ?? !Platform.isIOS;

  final bool _allowBroadcast;
  final int port;

  Future<bool> wake({
    required String mac,
    String broadcastIp = '255.255.255.255',
  }) async {
    final macValidation = MACAddress.validate(mac);
    if (!macValidation.state) {
      log('WoL: invalid MAC $mac (${macValidation.error})');
      return false;
    }
    final ipValidation = IPAddress.validate(broadcastIp);
    if (!ipValidation.state) {
      log('WoL: invalid broadcast $broadcastIp (${ipValidation.error})');
      return false;
    }
    // Free iOS signing cannot grant Apple's restricted broadcast entitlement.
    // A unicast packet is only a best effort: the TV/router must retain reachability.
    if (!_allowBroadcast && broadcastIp.split('.').last == '255') return false;

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      try {
        socket.broadcastEnabled = _allowBroadcast;
        final packet = WakeOnLAN(
          IPAddress(broadcastIp),
          MACAddress(mac),
        ).magicPacket();
        for (var i = 0; i < 3; i++) {
          if (socket.send(packet, InternetAddress(broadcastIp), port) !=
              packet.length) {
            throw StateError('Wake packet was not sent');
          }
          if (i < 2) {
            await Future<void>.delayed(const Duration(milliseconds: 120));
          }
        }
      } finally {
        socket.close();
      }
      log('WoL: magic packet sent to $mac via $broadcastIp');
      return true;
    } catch (e) {
      log('WoL: send failed: $e');
      return false;
    }
  }
}
