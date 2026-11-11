import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:remote/constants/key_codes.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/remote_key.dart';
import 'package:remote/ui/widgets/remote_controls/input_picker.dart';
import 'package:remote/ui/widgets/remote_controls/tactile_feedback.dart';
import 'package:remote/ui/widgets/remote_controls/tv_actions.dart';

class DirectionKeys extends StatelessWidget {
  const DirectionKeys({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget sector(int index, IconData icon, String label, KeyCodes key) =>
        Positioned.fill(
          child: ClipPath(
            clipper: _Sector(index),
            child: TactileFeedback(
              builder: (pressed) => AnimatedContainer(
                duration: Duration(milliseconds: pressed ? 0 : 115),
                curve: Curves.easeOutCubic,
                transformAlignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  pressed ? .985 : 1,
                  pressed ? .985 : 1,
                  1,
                )..setTranslationRaw(0, pressed ? 1.2 : 0, 0),
                decoration: BoxDecoration(
                  color: pressed ? const Color(0x40000000) : Colors.transparent,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.sendTvKey(key),
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    enableFeedback: false,
                    child: Tooltip(
                      message: label,
                      child: Semantics(
                        label: label,
                        button: true,
                        child: Align(
                          alignment: [
                            Alignment.topCenter,
                            Alignment.centerRight,
                            Alignment.bottomCenter,
                            Alignment.centerLeft,
                          ][index],
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Icon(icon, size: 40, color: Colors.white),
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
    Widget shortcut(IconData icon, String label, VoidCallback action) =>
        Expanded(
          child: SizedBox(
            height:
                60 +
                (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(0, 30),
            child: RemoteKey(
              onPressed: action,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  Text(label, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
        );
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final diameter = math.min<double>(176, constraints.maxWidth);
              return Row(
                children: [
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: diameter,
                        height: diameter,
                        child: Container(
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/materials/black-abs.png',
                              ),
                              fit: BoxFit.cover,
                              opacity: .28,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF090909)),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF505050),
                                Color(0xFF272727),
                                Color(0xFF101010),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(blurRadius: 2, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              sector(
                                0,
                                Icons.arrow_drop_up,
                                l.up,
                                KeyCodes.KEY_UP,
                              ),
                              sector(
                                1,
                                Icons.arrow_right,
                                l.right,
                                KeyCodes.KEY_RIGHT,
                              ),
                              sector(
                                2,
                                Icons.arrow_drop_down,
                                l.down,
                                KeyCodes.KEY_DOWN,
                              ),
                              sector(
                                3,
                                Icons.arrow_left,
                                l.left,
                                KeyCodes.KEY_LEFT,
                              ),
                              const Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(painter: _Seams()),
                                ),
                              ),
                              const SizedBox(
                                width: 84,
                                height: 84,
                                child: IgnorePointer(
                                  child: CustomPaint(painter: _WheelRidges()),
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: RemoteKey(
                                  radius: 50,
                                  onPressed: () =>
                                      context.sendTvKey(KeyCodes.KEY_ENTER),
                                  child: Text(
                                    l.ok,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              shortcut(
                Icons.keyboard_return,
                l.back,
                () => context.sendTvKey(KeyCodes.KEY_RETURN),
              ),
              const SizedBox(width: 8),
              shortcut(
                Icons.home_outlined,
                l.smart,
                () => context.sendTvKey(KeyCodes.KEY_HOME),
              ),
              const SizedBox(width: 8),
              shortcut(
                Icons.settings_input_hdmi_outlined,
                l.input,
                () => showTvInputs(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sector extends CustomClipper<Path> {
  const _Sector(this.index);
  final int index;
  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final angle = -math.pi * 3 / 4 + index * math.pi / 2;
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Offset.zero & size, angle, math.pi / 2, false)
      ..close();
  }

  @override
  bool shouldReclip(covariant _Sector oldClipper) => index != oldClipper.index;
}

class _Seams extends CustomPainter {
  const _Seams();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = (Offset.zero & size).deflate(2);
    canvas.drawCircle(
      center,
      size.width / 2 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF777777), Color(0xFF252525), Color(0xFF060606)],
        ).createShader(rect),
    );
    for (var i = 0; i < 4; i++) {
      final angle = math.pi / 4 + i * math.pi / 2;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * 51,
        center + direction * (size.width / 2),
        Paint()
          ..color = const Color(0xFF080808)
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Seams oldDelegate) => false;
}

class _WheelRidges extends CustomPainter {
  const _WheelRidges();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF080808));
    for (var i = 0; i < 44; i++) {
      final angle = i * math.pi * 2 / 44;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - 12),
        center + direction * (radius - 3),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF101010),
                  Color.lerp(
                    const Color(0xFF444444),
                    const Color(0xFF929292),
                    (.5 + .5 * math.cos(angle + math.pi / 4)),
                  )!,
                  const Color(0xFF171717),
                ],
                stops: const [0, .4, 1],
              ).createShader(
                Rect.fromPoints(
                  center + direction * (radius - 13),
                  center + direction * (radius - 2),
                ).inflate(2),
              )
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelRidges oldDelegate) => false;
}
