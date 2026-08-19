import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.heroTag,
    this.showLabel = true,
  });

  final double size;
  final String? heroTag;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final logo = _LogoMark(size: size);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (heroTag != null) Hero(tag: heroTag!, child: logo) else logo,
        if (showLabel) ...[
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANIMEX',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.24,
                  letterSpacing: 1.4,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Billing Suite',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: size * 0.12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return content;
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.14),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.pets_rounded,
              size: size * 0.5,
              color: AppColors.navy,
            );
          },
        ),
      ),
    );
  }
}
