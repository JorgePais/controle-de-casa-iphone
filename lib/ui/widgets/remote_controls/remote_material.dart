import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Continuous ABS surface. Mirrored sampling joins edges without restarting light.
class RemoteMaterial extends StatefulWidget {
  const RemoteMaterial({required this.child, this.radius = 32, super.key});
  final Widget child;
  final double radius;
  @override
  State<RemoteMaterial> createState() => _RemoteMaterialState();
}

class _RemoteMaterialState extends State<RemoteMaterial> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      'assets/materials/black-abs.png',
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = stream;
    _listener = ImageStreamListener((info, synchronous) {
      final previous = _info;
      if (mounted) {
        setState(() => _info = info);
      } else {
        info.dispose();
        return;
      }
      previous?.dispose();
    });
    stream.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(widget.radius),
      color: const Color(0xFF141414),
      boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 2))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: CustomPaint(
        painter: _AbsSurface(_info?.image),
        foregroundPainter: _ShellEdge(widget.radius),
        child: widget.child,
      ),
    ),
  );
}

class _AbsSurface extends CustomPainter {
  const _AbsSurface(this.image);
  final ui.Image? image;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final texture = image;
    if (texture != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..filterQuality = FilterQuality.medium
          ..shader = ui.ImageShader(
            texture,
            TileMode.mirror,
            TileMode.mirror,
            Matrix4.diagonal3Values(.5, .5, 1).storage,
          ),
      );
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x0AFFFFFF), Color(0x18000000), Color(0x70000000)],
          stops: [0, .35, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _AbsSurface oldDelegate) =>
      image != oldDelegate.image;
}

class _ShellEdge extends CustomPainter {
  const _ShellEdge(this.radius);
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF484848),
            Color(0xFF202020),
            Color(0xFF080808),
            Color(0xFF303030),
          ],
          stops: [0, .25, .7, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ShellEdge oldDelegate) =>
      oldDelegate.radius != radius;
}
