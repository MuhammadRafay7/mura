import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- CORE & SHARED ---
import '../../core/constants/colors.dart';
import 'settings_detail_view.dart';
import 'privacy_view.dart';
import 'interface_view.dart';

class MuraSettingsRegistry extends StatelessWidget {
  const MuraSettingsRegistry({super.key});

  /// Technical fade transition for navigation
  void _pushPage(BuildContext context, Widget page) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Handles the actual logout logic
  Future<void> _terminateSession(BuildContext context) async {
    // 1. High-intensity feedback for security confirmation
    await HapticFeedback.heavyImpact();

    try {
      // 2. Sign out from Supabase (Clears local JWT)
      await Supabase.instance.client.auth.signOut();

      // 3. Brief delay so the user feels the haptic feedback before the UI snaps
      await Future.delayed(const Duration(milliseconds: 200));

      // 4. Clear stack and return to root login route
      if (context.mounted) {
        // IMPORTANT: '/' must be your LoginScreen route in main.dart
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("TERMINATION_ERROR: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("SESSION_TERMINATION_FAILED"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            "SYSTEM_CONFIG",
            style: GoogleFonts.spaceMono(
              fontSize: 8,
              color: MuraColors.mute.withOpacity(0.6),
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),

        _settingTile(
          context,
          LucideIcons.shieldCheck,
          "PRIVACY_&_SECURITY",
          "ENCRYPTION_LAYER_ACTIVE",
          destination: const MuraPrivacyView(),
        ),

        _settingTile(
          context,
          LucideIcons.bell,
          "NOTIFICATIONS",
          "UPLINK_ALERTS_ON",
          destination: const MuraSettingsDetailView(title: "NOTIFICATIONS"),
        ),

        _settingTile(
          context,
          LucideIcons.cpu,
          "INTERFACE_STYLE",
          "LUXURY_MODERN_V2",
          destination: const MuraInterfaceView(),
        ),

        const SizedBox(height: 24),

        // --- TERMINATE SESSION ---
        _settingTile(
          context,
          LucideIcons.logOut,
          "TERMINATE_SESSION",
          "WIPE_LOCAL_KEYS",
          isDestructive: true,
          onTapOverride: () => _terminateSession(context),
        ),
      ],
    );
  }

  Widget _settingTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    Widget? destination,
    bool isDestructive = false,
    VoidCallback? onTapOverride,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (onTapOverride != null) {
            onTapOverride();
          } else if (destination != null) {
            _pushPage(context, destination);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.05)
                : (isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.white.withOpacity(0.3)),
            border: Border.all(
                color: isDestructive
                    ? Colors.red.withOpacity(0.3)
                    : MuraColors.microBorder.withOpacity(isDark ? 0.1 : 0.5),
                width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDestructive
                    ? Colors.red.withOpacity(0.8)
                    : MuraColors.textPrimary,
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
              const Spacer(),
              Icon(
                LucideIcons.chevronRight,
                size: 12,
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
