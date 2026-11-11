import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';

import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

class TvVolumeSlider extends StatefulWidget {
  const TvVolumeSlider({super.key});
  @override
  State<TvVolumeSlider> createState() => _TvVolumeSliderState();
}

class _TvVolumeSliderState extends State<TvVolumeSlider>
    with WidgetsBindingObserver {
  Timer? _timer;
  int? _level;
  double? _draft;
  bool _busy = false;

  bool _reading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_refresh()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_busy || _reading || _draft != null) return;
    _reading = true;
    try {
      final level = await context.read<TvConnectionBloc>().volume();
      if (mounted && !_busy && _draft == null) setState(() => _level = level);
    } catch (_) {
      if (mounted) setState(() => _level = null);
    } finally {
      _reading = false;
    }
  }

  Future<void> _set(int value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<TvConnectionBloc>().setVolume(value.clamp(0, 100));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível ajustar o volume.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _draft = null;
        });
        await _refresh();
      }
    }
  }

  void _step(int delta) {
    if (_level != null) {
      unawaited(_set(_level! + delta));
    } else {
      context.sendTvKey(delta > 0 ? KeyCodes.KEY_VOLUP : KeyCodes.KEY_VOLDOWN);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget key(IconData icon, String label, VoidCallback action) => Expanded(
      child: SizedBox(
        height:
            52 + (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0, 20),
        child: RemoteKey(
          label: label,
          onPressed: _busy ? null : action,
          child: Icon(icon, size: 28),
        ),
      ),
    );
    return Column(
      children: [
        Row(
          children: [
            key(Icons.remove, l.volumeDown, () => _step(-1)),
            const SizedBox(width: 8),
            key(
              Icons.volume_off_outlined,
              l.mute,
              () => context.sendTvKey(KeyCodes.KEY_MUTE),
            ),
            const SizedBox(width: 8),
            key(Icons.add, l.volumeUp, () => _step(1)),
          ],
        ),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Text(
                'VOL',
                style: TextStyle(fontSize: 10, color: Colors.white60),
              ),
              Expanded(
                child: _level == null
                    ? const Tooltip(
                        message:
                            'Ajuste direto indisponível nesta saída de áudio. Use VOL +/−.',
                        child: Center(
                          child: Text(
                            'Indisponível',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      )
                    : Slider(
                        value: _draft ?? _level!.toDouble(),
                        max: 100,
                        divisions: 100,
                        semanticFormatterCallback: (value) =>
                            'Volume da TV ${value.round()}',
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _draft = value),
                        onChangeEnd: (value) => unawaited(_set(value.round())),
                      ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  _level == null
                      ? '—'
                      : '${(_draft ?? _level!.toDouble()).round()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      ],
    );
  }
}
