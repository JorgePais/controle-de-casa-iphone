import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Starts before the tap recognizer's press delay. Commands still use onTap,
/// so dragging to scroll never sends an accidental command to the TV.
class TactileFeedback extends StatefulWidget {
  const TactileFeedback({
    required this.builder,
    this.enabled = true,
    super.key,
  });
  final Widget Function(bool pressed) builder;
  final bool enabled;

  @override
  State<TactileFeedback> createState() => _TactileFeedbackState();
}

class _TactileFeedbackState extends State<TactileFeedback> {
  bool _pressed = false;
  int? _pointer;
  Offset? _origin;
  final Stopwatch _held = Stopwatch();
  Timer? _releaseTimer;

  void _down(PointerDownEvent event) {
    if (!widget.enabled || _pointer != null) return;
    _releaseTimer?.cancel();
    _pointer = event.pointer;
    _origin = event.position;
    _held
      ..reset()
      ..start();
    setState(() => _pressed = true);
    unawaited(HapticFeedback.lightImpact().catchError((Object _) {}));
  }

  void _release({bool cancel = false}) {
    _pointer = null;
    _origin = null;
    _releaseTimer?.cancel();
    // Preserve one visible compression even for taps shorter than one frame.
    final remaining = 64 - _held.elapsedMilliseconds;
    if (!cancel && remaining > 0) {
      _releaseTimer = Timer(Duration(milliseconds: remaining), () {
        if (mounted) setState(() => _pressed = false);
      });
    } else if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  @override
  void didUpdateWidget(covariant TactileFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) _release(cancel: true);
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    _held.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: (event) {
      if (event.pointer == _pointer) _release();
    },
    onPointerCancel: (event) {
      if (event.pointer == _pointer) _release(cancel: true);
    },
    onPointerMove: (event) {
      if (event.pointer == _pointer &&
          _origin != null &&
          (event.position - _origin!).distance > kTouchSlop) {
        _release(cancel: true);
      }
    },
    child: RepaintBoundary(child: widget.builder(_pressed)),
  );
}
