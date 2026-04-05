import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class MuraSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const MuraSettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (isDestructive) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.lightImpact();
          }
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        splashColor: isDestructive
            ? Colors.red.withOpacity(0.05)
            : MuraColors.userBubble.withOpacity(0.05),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.02)
                : (isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.white.withOpacity(0.4)),
            border: Border.all(
                color: isDestructive
                    ? Colors.red.withOpacity(0.2)
                    : MuraColors.microBorder.withOpacity(isDark ? 0.1 : 0.5),
                width: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Technical Node Icon
              Icon(
                icon,
                size: 16,
                color: isDestructive
                    ? Colors.red.withOpacity(0.8)
                    : MuraColors.textPrimary.withOpacity(0.9),
              ),
              const SizedBox(width: 20),

              // Metadata Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDestructive
                            ? Colors.red.withOpacity(0.8)
                            : MuraColors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceMono(
                        fontSize: 7,
                        color: MuraColors.mute.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Architectural Pointer
              Icon(
                Icons
                    .arrow_forward_ios, // Switched to forward for cleaner terminal vibe
                size: 10,
                color: isDestructive
                    ? Colors.red.withOpacity(0.2)
                    : MuraColors.mute.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
