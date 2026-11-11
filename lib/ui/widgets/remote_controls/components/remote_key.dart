import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:remote/ui/widgets/remote_controls/tactile_feedback.dart';

/// Convex rubber cap, recessed seat, fine grain and immediate pressed feedback.
class RemoteKey extends StatefulWidget {
  const RemoteKey({
    required this.child,
    required this.onPressed,
    this.label,
    this.color = const Color(0xFF202020),
    this.radius = 24,
    super.key,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final Color color;
  final double radius;
  @override
  State<RemoteKey> createState() => _RemoteKeyState();
}

class _RemoteKeyState extends State<RemoteKey> {
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    final cap = TactileFeedback(
      enabled: widget.onPressed != null,
      builder: (pressed) => AnimatedContainer(
        duration: Duration(milliseconds: pressed ? 0 : 115),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          pressed ? .975 : 1,
          pressed ? .965 : 1,
          1,
        )..setTranslationRaw(0, pressed ? 1.5 : 0, 0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/materials/rubber-cap-v2.png'),
            fit: BoxFit.fill,
            opacity: .12,
            colorFilter: ColorFilter.mode(widget.color, BlendMode.color),
          ),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xEE000000),
              blurRadius: pressed ? .25 : 2,
              offset: Offset(0, pressed ? 0 : 1),
            ),
            const BoxShadow(
              color: Color(0xFF343434),
              offset: Offset(0, -1),
              blurRadius: .5,
            ),
          ],
          border: Border.all(color: const Color(0xFF080808)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, .12, .45, 1],
            colors: [
              Color.lerp(
                widget.color,
                pressed ? Colors.black : Colors.white,
                pressed ? .16 : .065,
              )!,
              Color.lerp(
                widget.color,
                pressed ? Colors.black : Colors.white,
                pressed ? .08 : .025,
              )!,
              Color.lerp(widget.color, Colors.black, pressed ? .06 : 0)!,
              Color.lerp(widget.color, Colors.black, pressed ? .18 : .28)!,
            ],
          ),
        ),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _RubberPores(
              widget.radius,
              HSLColor.fromColor(widget.color).saturation > .1,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                enableFeedback: false,
                onTap: widget.onPressed,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Center(child: widget.child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return widget.label == null
        ? cap
        : Tooltip(
            message: widget.label,
            child: Semantics(label: widget.label, button: true, child: cap),
          );
  }
}

/// Fine molded pores, shared by black and pigmented rubber caps.
class _RubberPores extends CustomPainter {
  const _RubberPores(this.radius, this.pigmented);
  final double radius;
  final bool pigmented;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final faceLight = Color(pigmented ? 0x18FFFFFF : 0x05FFFFFF);
    final faceShade = Color(pigmented ? 0x55000000 : 0x25000000);
    final rimLight = Color(pigmented ? 0x24FFFFFF : 0x10FFFFFF);
    final rimShade = Color(pigmented ? 0x60000000 : 0x30000000);
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRRect(
        shape,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.35, -.7),
            radius: 1.25,
            colors: [faceLight, Colors.transparent, faceShade],
            stops: const [0, .45, 1],
          ).createShader(rect),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(rect.deflate(.7), Radius.circular(radius)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = pigmented ? 1.6 : .8
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rimLight, Colors.transparent, rimShade],
            stops: const [0, .4, 1],
          ).createShader(rect),
      );
    final random = math.Random(173);
    final light = Paint()..color = const Color(0x1FFFFFFF);
    final shadow = Paint()..color = const Color(0x35000000);
    for (var i = 0; i < size.width * size.height / 3; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas
        ..drawOval(Rect.fromLTWH(x, y, .65, .35), shadow)
        ..drawOval(Rect.fromLTWH(x - .2, y - .3, .5, .3), light);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RubberPores oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.pigmented != pigmented;
}
