import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

/// Familiar, equally sized transport keys below the navigation controls.
class MediaControls extends StatelessWidget {
  const MediaControls({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget key(IconData icon, String label, KeyCodes code) => Expanded(
      child: SizedBox(
        height: 48,
        child: RemoteKey(
          label: label,
          onPressed: () => context.sendTvKey(code),
          child: Icon(icon, size: 26, color: Colors.white),
        ),
      ),
    );
    return Row(
      children: [
        key(Icons.fast_rewind, l.rewind, KeyCodes.KEY_REWIND),
        const SizedBox(width: 8),
        key(Icons.play_arrow, l.play, KeyCodes.KEY_PLAY),
        const SizedBox(width: 8),
        key(Icons.pause, l.pause, KeyCodes.KEY_PAUSE),
        const SizedBox(width: 8),
        key(Icons.fast_forward, l.fastForward, KeyCodes.KEY_FF),
      ],
    );
  }
}
