import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

/// These are guided adjustments on the TV, never simulated on/off states.
class VideoOptionButton extends StatelessWidget {
  const VideoOptionButton({required this.captions, super.key});
  final bool captions;
  Future<void> _show(BuildContext context, bool captions) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171717),
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  captions ? 'Legendas no YouTube' : 'Opções do vídeo',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  captions
                      ? 'Pause o vídeo e selecione CC na tela da TV. Escolha o idioma ou desative as legendas. A opção depende das legendas disponíveis no vídeo.'
                      : 'Na tela do vídeo, abra a engrenagem do YouTube. Ali você escolhe Qualidade e Velocidade. A velocidade pode não estar disponível em todas as TVs.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Use as setas e OK do controle para escolher na TV.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  child: RemoteKey(
                    onPressed: () {
                      context.sendTvKey(KeyCodes.KEY_PAUSE);
                      Navigator.of(sheet).pop();
                    },
                    child: const Text('Pausar vídeo e voltar ao controle'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheet).pop(),
                  child: const Text('Voltar sem pausar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 48,
    child: RemoteKey(
      label: captions ? 'Legendas' : 'Opções do vídeo',
      onPressed: () => _show(context, captions),
      child: Icon(
        captions ? Icons.closed_caption_outlined : Icons.tune,
        size: 22,
        color: Colors.white70,
      ),
    ),
  );
}
