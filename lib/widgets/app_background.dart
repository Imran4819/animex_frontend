import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark ? null : AppGradients.background,
        color: isDark ? AppColors.navyDark : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            right: -30,
            child: _Orb(
              color: AppColors.orange.withValues(alpha: 0.12),
              size: 180,
            ),
          ),
          Positioned(
            bottom: 120,
            left: -70,
            child: _Orb(
              color: AppColors.navy.withValues(alpha: 0.09),
              size: 220,
            ),
          ),
          Positioned(
            top: 180,
            left: 30,
            child: _Orb(
              color: AppColors.orange.withValues(alpha: 0.06),
              size: 90,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
