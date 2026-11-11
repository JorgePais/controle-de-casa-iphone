import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/core/models/disconnection_type.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/components.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';
import 'package:remote/ui/widgets/remote_controls/remote_material.dart';
import 'package:remote/ui/widgets/remote_controls/streaming_shortcuts.dart';

import 'package:remote/ui/widgets/remote_controls/tv_volume_slider.dart';

import 'package:remote/ui/widgets/remote_controls/voice_text_sheet.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  Future<void> _showVoice() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171717),
      builder: (_) => BlocProvider.value(
        value: context.read<TvConnectionBloc>(),
        child: const VoiceTextSheet(),
      ),
    );
  }

  Future<void> _showMore() async {
    final l = AppLocalizations.of(context);
    final connection = context.read<TvConnectionBloc>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171717),
      builder: (_) => BlocProvider.value(
        value: connection,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.more,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ChannelControls(),
                  ListTile(
                    leading: const Icon(Icons.stop),
                    title: Text(l.stop),
                    onTap: () => connection.add(
                      const TvSendKeyRequested(KeyCodes.KEY_STOP),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(l.menu),
                    onTap: () => connection.add(
                      const TvSendKeyRequested(KeyCodes.KEY_MENU),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l.info),
                    onTap: () => connection.add(
                      const TvSendKeyRequested(KeyCodes.KEY_INFO),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l.exit),
                    onTap: () => connection.add(
                      const TvSendKeyRequested(KeyCodes.KEY_EXT41),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePower(BuildContext context) {
    context.read<TvConnectionBloc>().add(const TvPowerOffRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TvConnectionBloc, TvConnectionState>(
      listenWhen: (p, n) =>
          p.status != n.status || p.errorMessage != n.errorMessage,
      listener: (context, state) {
        final l = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        if (state.isConnected && state.errorMessage != null) {
          messenger.showSnackBar(SnackBar(content: Text(l.connectionError)));
        }
        switch (state.status) {
          case TvConnectionStatus.error:
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? l.connectionError),
                backgroundColor: Colors.red,
              ),
            );
          case TvConnectionStatus.disconnected:
            if (state.disconnectionType != DisconnectionType.userInitiated) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    l.disconnectedReason(
                      state.disconnectionType?.displayName ?? l.unknown,
                    ),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          case _:
            break;
        }
      },
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            context.read<TvConnectionBloc>().add(const TvDisconnectRequested());
          }
        },
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 48,
            leading: IconButton(
              icon: const Icon(Icons.devices),
              tooltip: AppLocalizations.of(context).switchTv,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: BlocBuilder<TvConnectionBloc, TvConnectionState>(
              builder: (context, state) => Text(
                state.device?.displayName ??
                    AppLocalizations.of(context).remote,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppLocalizations.of(context).reconnect,
                onPressed: () {
                  final device = context.read<TvConnectionBloc>().state.device;
                  if (device != null) {
                    context.read<TvConnectionBloc>().add(
                      TvConnectRequested(device),
                    );
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: RemoteMaterial(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: RemoteKey(
                                  label: AppLocalizations.of(context).power,
                                  color: const Color(0xFFAD4650),
                                  radius: 50,
                                  onPressed: () => _handlePower(context),
                                  child: const Icon(
                                    Icons.power_settings_new,
                                    size: 30,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: RemoteKey(
                                  label: AppLocalizations.of(context).more,
                                  onPressed: _showMore,
                                  child: const Icon(Icons.more_horiz, size: 24),
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: RemoteKey(
                                  label: 'Falar ou escrever',
                                  radius: 50,
                                  onPressed: _showVoice,
                                  child: const Icon(Icons.mic_none, size: 28),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            height:
                                216 +
                                (MediaQuery.textScalerOf(context).scale(16) -
                                            16)
                                        .clamp(0, 20) *
                                    4,
                            child: Column(
                              children: [NumPad(onVoice: _showVoice)],
                            ),
                          ),
                          const SizedBox(height: 5),

                          SizedBox(
                            height:
                                244 +
                                (MediaQuery.textScalerOf(context).scale(14) -
                                        14)
                                    .clamp(0, 40),
                            child: const Column(children: [DirectionKeys()]),
                          ),
                          const SizedBox(height: 5),
                          BlocBuilder<TvConnectionBloc, TvConnectionState>(
                            builder: (context, state) => TvVolumeSlider(
                              key: ValueKey(
                                '${state.device?.host}:${state.status}',
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const StreamingShortcuts(),
                          const SizedBox(height: 5),

                          const MediaControls(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
