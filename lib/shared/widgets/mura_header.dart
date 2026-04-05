import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';

/// The primary header component for Mura architecture.
/// Uses a technical/architectural indicator to ground display text.
class MuraHeader extends StatelessWidget {
  final String technicalTag;
  final String displayTitle;
  final bool showDivider;
  final CrossAxisAlignment alignment; // Added for layout flexibility

  const MuraHeader({
    super.key,
    required this.technicalTag,
    required this.displayTitle,
    this.showDivider = true,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        // Technical Indicator Row
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Architectural Pointer - Represents the "Node" origin
            Container(
              width: 16,
              height: 1,
              decoration: BoxDecoration(
                color: MuraColors.userBubble.withOpacity(0.8),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                technicalTag.toUpperCase(),
                style: MuraStyles.labelTechnical.copyWith(
                  letterSpacing: 4.0,
                  color: MuraColors.mute.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Main Display Title
        Text(
          displayTitle,
          style: MuraStyles.headingMain.copyWith(
            // Subtle dimming for OLED comfort in dark mode
            color: isDark
                ? Colors.white.withOpacity(0.95)
                : MuraColors.textPrimary,
          ),
          textAlign: alignment == CrossAxisAlignment.center
              ? TextAlign.center
              : TextAlign.left,
          semanticsLabel: displayTitle,
        ),

        if (showDivider) ...[
          const SizedBox(height: 32),
          // Subtle Grounding Divider with fade-out
          Container(
            height: 0.5,
            width: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: alignment == CrossAxisAlignment.center
                    ? Alignment.centerLeft
                    : Alignment.centerLeft,
                end: alignment == CrossAxisAlignment.center
                    ? Alignment.centerRight
                    : Alignment.centerRight,
                colors: [
                  alignment == CrossAxisAlignment.center
                      ? Colors.transparent
                      : MuraColors.microBorder,
                  MuraColors.microBorder,
                  Colors.transparent,
                ],
                stops: alignment == CrossAxisAlignment.center
                    ? const [0.0, 0.5, 1.0]
                    : const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
