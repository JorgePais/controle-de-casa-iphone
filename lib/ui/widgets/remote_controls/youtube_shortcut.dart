import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';

class YouTubeShortcut extends StatefulWidget {
  const YouTubeShortcut({this.compact = false, super.key});
  final bool compact;
  @override
  State<YouTubeShortcut> createState() => _YouTubeShortcutState();
}

class _YouTubeShortcutState extends State<YouTubeShortcut> {
  bool _busy = false;
  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<TvConnectionBloc>().openYouTube();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o YouTube. Confira se ele está instalado na TV e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TvConnectionBloc>().state;
    if (state.device == null ||
        TvBrand.fromDevice(state.device!) != TvBrand.lg) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 54,
      child: RemoteKey(
        label: 'Abrir YouTube na TV',
        onPressed: _busy || !state.isConnected ? null : _open,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.smart_display_rounded,
              color: Color(0xFFFF293B),
              size: 30,
            ),
            if (!widget.compact) const SizedBox(width: 10),
            if (!widget.compact)
              Text(
                _busy ? 'Abrindo…' : 'YouTube',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
