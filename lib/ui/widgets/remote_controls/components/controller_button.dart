import 'package:flutter/material.dart';

class ControllerButton extends StatelessWidget {
  const ControllerButton({
    super.key,
    this.child,
    this.onPressed,
    this.borderRadius = 50,
    this.color = Colors.transparent,
  });
  final Widget? child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color == Colors.transparent
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : color,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}
