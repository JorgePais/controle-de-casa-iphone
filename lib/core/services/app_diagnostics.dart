import 'package:flutter/services.dart';

/// Local only. Recording must never interrupt the action being diagnosed.
class AppDiagnostics {
  static const _channel = MethodChannel(
    'br.com.controledecasa.app/diagnostics',
  );

  static Future<void> record(String key, String message) async {
    try {
      await _channel.invokeMethod<void>('record', {
        'key': key,
        'message': message.length > 8000 ? message.substring(0, 8000) : message,
      });
    } catch (_) {
      // Unsupported platforms and logging failures must not affect the app.
    }
  }

  static Future<String> read() async {
    try {
      return await _channel.invokeMethod<String>('read') ?? 'Sem registros.';
    } catch (_) {
      return 'Não foi possível ler o diagnóstico neste aparelho.';
    }
  }
}
