import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';
import 'package:remote/ui/widgets/remote_controls/video_options.dart';

/// Persistent, familiar 3 × 4 numeric grid with comfortable touch targets.
class NumPad extends StatelessWidget {
  const NumPad({this.onVoice, super.key});
  final VoidCallback? onVoice;
  static const List<KeyCodes> _keys = [
    KeyCodes.KEY_1,
    KeyCodes.KEY_2,
    KeyCodes.KEY_3,
    KeyCodes.KEY_4,
    KeyCodes.KEY_5,
    KeyCodes.KEY_6,
    KeyCodes.KEY_7,
    KeyCodes.KEY_8,
    KeyCodes.KEY_9,
  ];
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        4,
        (row) => Row(
          children: List.generate(3, (column) {
            final digit = row * 3 + column + 1;
            if (digit == 10 || digit == 12) {
              return Expanded(
                child: Center(
                  child: SizedBox(
                    width: 76,
                    height: 48,
                    child: VideoOptionButton(captions: digit == 10),
                  ),
                ),
              );
            }
            final value = digit == 11 ? 0 : digit;
            final code = value == 0 ? KeyCodes.KEY_0 : _keys[value - 1];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: SizedBox(
                    width: 76,
                    height:
                        48 +
                        (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(
                          0,
                          20,
                        ),
                    child: RemoteKey(
                      label: '$value',
                      onPressed: () => context.sendTvKey(code),
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}
