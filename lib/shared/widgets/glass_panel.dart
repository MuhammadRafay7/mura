import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final double? borderRadius;
  final double blur;
  final Border? customBorder; // Added for more granular control

  const GlassPanel({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.borderRadius,
    this.blur = 30.0,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveRadius = borderRadius ?? MuraSpacing.radius;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: width,
      constraints: const BoxConstraints(
        minWidth: 0,
        minHeight: 0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              // Slightly adjusted opacity for better legibility on complex backgrounds
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : MuraColors.contactBubble.withOpacity(0.12),
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: customBorder ??
                  Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : MuraColors.contactBubble.withOpacity(0.2),
                    width: 0.5,
                  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Stack(
              children: [
                // DECORATIVE LAYER: Subtle light sweep for that "elite" finish
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(effectiveRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.4),
                            Colors.transparent,
                            isDark
                                ? Colors.black.withOpacity(0.02)
                                : Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // INTERACTIVE LAYER: The actual content
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
