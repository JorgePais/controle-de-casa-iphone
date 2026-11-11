import 'package:flutter/material.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';

class PrimaryKeys extends StatelessWidget {
  const PrimaryKeys({
    required this.onPower,
    required this.onToggleKeypad,
    required this.keypadShown,
    super.key,
  });
  final VoidCallback onPower;
  final VoidCallback onToggleKeypad;
  final bool keypadShown;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 64,
          height: 48,
          child: RemoteKey(
            label: l.numericKeypad,
            onPressed: onToggleKeypad,
            child: const Text(
              '123',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Text(
          'CONTROLE DE CASA',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.5,
            color: Colors.white54,
          ),
        ),
        SizedBox(
          width: 54,
          height: 54,
          child: RemoteKey(
            label: l.power,
            onPressed: onPower,
            color: const Color(0xFFE30F24),
            radius: 50,
            child: const Icon(Icons.power_settings_new, size: 30),
          ),
        ),
      ],
    );
  }
}
