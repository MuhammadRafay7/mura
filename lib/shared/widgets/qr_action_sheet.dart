import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';

class QrActionSheet extends StatelessWidget {
  final String shareLink = "https://mura.archive/mura_core";

  const QrActionSheet({super.key});

  // Helper for quick feedback on actions
  void _handleAction(BuildContext context, String actionLabel) {
    HapticFeedback.lightImpact();
    // Logic for Scan, Share, or Copy goes here
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we need to adjust for Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: isDark
              ? MuraColors.background.withOpacity(0.8)
              : Colors.white.withOpacity(0.88),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border(
            top: BorderSide(
                color: MuraColors.microBorder.withOpacity(isDark ? 0.1 : 0.4),
                width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Structural Handlebar - Minimalist
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MuraColors.textPrimary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 48),

            Text("IDENTITY_UPLINK",
                style: MuraStyles.labelTechnical.copyWith(
                  letterSpacing: 6,
                  color: MuraColors.mute.withOpacity(0.6),
                )),
            const SizedBox(height: 40),

            // QR Calibrated Frame
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                border: Border.all(
                    color:
                        MuraColors.microBorder.withOpacity(isDark ? 0.05 : 0.3),
                    width: 0.5),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(LucideIcons.qrCode,
                      size: 160,
                      color: isDark ? Colors.white : MuraColors.textPrimary),
                  // "Elite" Branding Center Overlay
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? MuraColors.background : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: MuraColors.microBorder.withOpacity(0.2),
                          width: 0.5),
                    ),
                    child: Center(
                      child: Icon(LucideIcons.layers,
                          size: 14, color: MuraColors.userBubble),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Action Matrix
            _buildActionButton(LucideIcons.scan, "SCAN_IDENTITY",
                () => _handleAction(context, "SCAN")),
            const SizedBox(height: 10),
            _buildActionButton(LucideIcons.share2, "SHARE_UPLINK",
                () => _handleAction(context, "SHARE")),
            const SizedBox(height: 10),
            _buildActionButton(LucideIcons.copy, "COPY_RESOURCE_LOCATOR",
                () => _handleAction(context, "COPY")),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white
              .withOpacity(0.02), // Micro-fill for interaction feedback
          border: Border.all(
              color: MuraColors.microBorder.withOpacity(0.1), width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: MuraColors.textPrimary.withOpacity(0.7)),
            const SizedBox(width: 20),
            Text(label,
                style: MuraStyles.labelTechnical
                    .copyWith(letterSpacing: 2, fontSize: 9)),
            const Spacer(),
            Icon(LucideIcons.chevronRight,
                size: 12, color: MuraColors.mute.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
