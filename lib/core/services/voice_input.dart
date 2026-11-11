import 'package:speech_to_text/speech_to_text.dart';

abstract interface class VoiceInput {
  Future<bool> start({
    required void Function(String) onText,
    required void Function() onDone,
    required void Function(String) onError,
  });
  Future<void> cancel();
}

/// One recognizer for the app; permission and listening begin only on a tap.
class PhoneVoiceInput implements VoiceInput {
  PhoneVoiceInput._();
  static final PhoneVoiceInput instance = PhoneVoiceInput._();
  final SpeechToText _speech = SpeechToText();
  int _generation = 0;
  void Function(String)? _error;
  void Function()? _done;
  @override
  Future<bool> start({
    required void Function(String) onText,
    required void Function() onDone,
    required void Function(String) onError,
  }) async {
    final generation = ++_generation;
    _error = onError;
    _done = onDone;
    final ready = await _speech.initialize(
      options: [SpeechToText.androidNoBluetooth],
      onError: (error) => _error?.call(
        'Não foi possível reconhecer a fala. Verifique a permissão do microfone ou digite o texto.',
      ),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _done?.call();
      },
    );
    if (!ready || generation != _generation) return false;
    final locales = await _speech.locales();
    final portuguese = locales.where(
      (locale) => locale.localeId.replaceAll('-', '_').toLowerCase() == 'pt_br',
    );
    final system = await _speech.systemLocale();
    if (generation != _generation) return false;
    await _speech.listen(
      onResult: (result) {
        if (generation == _generation) onText(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: portuguese.isNotEmpty
            ? portuguese.first.localeId
            : system?.localeId,
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 4),
        cancelOnError: true,
      ),
    );
    return true;
  }

  @override
  Future<void> cancel() async {
    _generation++;
    _done = null;
    _error = null;
    await _speech.cancel();
  }
}
