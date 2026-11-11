import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

class ColorKeys extends StatelessWidget {
  const ColorKeys({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ColorButton(
          color: const Color(0xFFAA4C48),
          label: l.redButton,
          keyCode: KeyCodes.KEY_RED,
        ),
        _ColorButton(
          color: const Color(0xFF528365),
          label: l.greenButton,
          keyCode: KeyCodes.KEY_GREEN,
        ),
        _ColorButton(
          color: const Color(0xFFB0A05A),
          label: l.yellowButton,
          keyCode: KeyCodes.KEY_YELLOW,
        ),
        _ColorButton(
          color: const Color(0xFF4B7897),
          label: l.blueButton,
          keyCode: KeyCodes.KEY_CYAN,
        ),
      ],
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.color,
    required this.label,
    required this.keyCode,
  });

  final Color color;
  final String label;
  final KeyCodes keyCode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 48,
      child: Semantics(
        label: label,
        button: true,
        child: RemoteKey(
          color: color,
          onPressed: () => context.sendTvKey(keyCode),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
