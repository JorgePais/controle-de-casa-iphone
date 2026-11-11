import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

/// Infrequent broadcast-TV controls live only under More controls.
class ChannelControls extends StatelessWidget {
  const ChannelControls({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Text(l.channels),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: l.channelDown,
              onPressed: () => context.sendTvKey(KeyCodes.KEY_CHDOWN),
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              tooltip: l.guide,
              onPressed: () => context.sendTvKey(KeyCodes.KEY_GUIDE),
              icon: const Icon(Icons.list_alt),
            ),
            IconButton(
              tooltip: l.channelUp,
              onPressed: () => context.sendTvKey(KeyCodes.KEY_CHUP),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
