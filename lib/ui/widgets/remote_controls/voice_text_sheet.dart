import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/core/services/voice_input.dart';

class VoiceTextSheet extends StatefulWidget {
  const VoiceTextSheet({this.voice, super.key});
  final VoiceInput? voice;
  @override
  State<VoiceTextSheet> createState() => _VoiceTextSheetState();
}

class _VoiceTextSheetState extends State<VoiceTextSheet>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  late final VoiceInput _voice = widget.voice ?? PhoneVoiceInput.instance;
  late final String? _host;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _host = context.read<TvConnectionBloc>().state.device?.host;
  }

  bool _listening = false;
  bool _sending = false;
  String? _message;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_voice.cancel());
      if (mounted) setState(() => _listening = false);
    }
  }

  Future<void> _listen() async {
    if (_listening) {
      await _voice.cancel();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _message = null;
    });
    try {
      final ready = await _voice.start(
        onText: (text) {
          if (mounted) {
            _text.text = text;
            setState(() {});
          }
        },
        onDone: () {
          if (mounted) setState(() => _listening = false);
        },
        onError: (message) {
          if (mounted) {
            setState(() {
              _listening = false;
              _message = message;
            });
          }
        },
      );
      if (!mounted) {
        await _voice.cancel();
        return;
      }
      if (!ready) {
        setState(() {
          _listening = false;
          _message =
              'Reconhecimento de voz indisponível. Permita o microfone ou digite abaixo.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _message =
              'Não foi possível iniciar o microfone. Você pode digitar abaixo.';
        });
      }
    }
  }

  Future<void> _send(bool submit) async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending || _host == null) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await _voice.cancel();
      if (!mounted) return;
      await context.read<TvConnectionBloc>().sendText(
        text,
        expectedHost: _host,
        submit: submit,
      );
      if (mounted) {
        setState(() {
          _listening = false;
          _message = submit
              ? 'Texto enviado e busca solicitada na TV.'
              : 'Texto enviado ao campo aberto na TV.';
        });
        _text.clear();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Não foi possível completar o envio. Abra o campo de busca na TV e confira se o texto já apareceu antes de tentar novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_voice.cancel());
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Falar ou escrever',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Abra a busca ou um campo de texto na TV. Fale, revise e envie para esse campo.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _sending ? null : _listen,
              icon: Icon(_listening ? Icons.stop : Icons.mic),
              label: Text(_listening ? 'Parar de ouvir' : 'Falar agora'),
            ),
            TextField(
              controller: _text,
              enabled: !_sending && !_listening,
              minLines: 1,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Texto para a TV',
                hintText: 'Fale ou digite aqui',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O reconhecimento usa o serviço de voz do celular. O envio depende do campo aberto aceitar texto remoto.',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_message!),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _sending || _listening || _text.text.trim().isEmpty
                        ? null
                        : () => _send(false),
                    child: const Text('Enviar texto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _sending || _listening || _text.text.trim().isEmpty
                        ? null
                        : () => _send(true),
                    child: Text(_sending ? 'Enviando…' : 'Buscar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
