import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/core/models/tv_brand.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';

enum StreamingApp { netflix, primevideo, youtube, disneyplus }

class StreamingShortcuts extends StatelessWidget {
  const StreamingShortcuts({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<TvConnectionBloc>().state;
    if (state.device == null ||
        TvBrand.fromDevice(state.device!) != TvBrand.lg) {
      return const SizedBox.shrink();
    }
    return const Row(
      children: [
        Expanded(child: _Shortcut(app: StreamingApp.netflix)),
        SizedBox(width: 8),
        Expanded(child: _Shortcut(app: StreamingApp.primevideo)),
        SizedBox(width: 8),
        Expanded(child: _Shortcut(app: StreamingApp.youtube)),
        SizedBox(width: 8),
        Expanded(child: _Shortcut(app: StreamingApp.disneyplus)),
      ],
    );
  }
}

class _Shortcut extends StatefulWidget {
  const _Shortcut({required this.app});
  final StreamingApp app;
  @override
  State<_Shortcut> createState() => _ShortcutState();
}

class _ShortcutState extends State<_Shortcut> {
  bool _busy = false;
  String get _name => switch (widget.app) {
    StreamingApp.netflix => 'Netflix',
    StreamingApp.primevideo => 'Prime Video',
    StreamingApp.youtube => 'YouTube',
    StreamingApp.disneyplus => 'Disney+',
  };
  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    final connection = context.read<TvConnectionBloc>();
    try {
      switch (widget.app) {
        case StreamingApp.netflix:
          await connection.openNetflix();
        case StreamingApp.primevideo:
          await connection.openPrimeVideo();
        case StreamingApp.youtube:
          await connection.openYouTube();
        case StreamingApp.disneyplus:
          await connection.openDisneyPlus();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível abrir o $_name. Confira se ele está instalado na TV e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: RemoteKey(
      label: 'Abrir $_name na TV',
      onPressed: _busy || !context.watch<TvConnectionBloc>().state.isConnected
          ? null
          : _open,
      child: SvgPicture.asset(
        'assets/brands/${widget.app.name}.svg',
        height: widget.app == StreamingApp.primevideo ? 28 : 24,
        width: widget.app == StreamingApp.primevideo
            ? 76
            : widget.app == StreamingApp.disneyplus
            ? 56
            : 32,
        excludeFromSemantics: true,
        colorFilter: ColorFilter.mode(
          widget.app == StreamingApp.primevideo
              ? const Color(0xFF35BCF1)
              : widget.app == StreamingApp.disneyplus
              ? const Color(0xFF9BBFD1)
              : const Color(0xFFF52135),
          BlendMode.srcIn,
        ),
      ),
    ),
  );
}
