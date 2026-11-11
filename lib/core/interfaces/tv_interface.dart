import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/connection_state.dart';
import 'package:remote/core/models/disconnection_type.dart';

/// Base interface for every TV brand implementation.
abstract class TVInterface {
  String? get host;
  String? get mac;
  String? get deviceName;
  String? get modelName;

  bool get isConnected;
  ConnectionState get connectionState;

  Future<void> connect({String appName});
  void disconnect();
  Future<void> ensureConnection();

  Future<void> sendKey(KeyCodes key);

  void setOnDisconnectedCallback(void Function(DisconnectionType) callback);
  void setOnConnectionStateChangedCallback(
    void Function(ConnectionState) callback,
  );
}
