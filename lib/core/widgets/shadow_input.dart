import 'package:flutter/material.dart';

/// Wraps a child widget (typically a TextFormField, DropdownButtonFormField,
/// or InkWell date picker) in a Container with a subtle shadow in light mode.
/// In dark mode, the child is returned without any wrapper.
class ShadowInput extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const ShadowInput({super.key, required this.child, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return child;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
