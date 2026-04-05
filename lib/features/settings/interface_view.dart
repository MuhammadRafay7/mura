import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/theme_controller.dart';

class MuraInterfaceView extends StatefulWidget {
  const MuraInterfaceView({super.key});

  @override
  State<MuraInterfaceView> createState() => _MuraInterfaceViewState();
}

class _MuraInterfaceViewState extends State<MuraInterfaceView> {
  // Assuming MuraThemeController is a singleton or managed via a Provider/Riverpod
  final _themeController = MuraThemeController();

  void _handleThemeChange(String themeKey) {
    // Prevent redundant swaps
    if ((_themeController.isDarkMode && themeKey == "CYBER_ONYX") ||
        (!_themeController.isDarkMode && themeKey == "LUXURY_MODERN")) return;

    HapticFeedback.heavyImpact();

    setState(() {
      _themeController.toggleTheme(themeKey);
    });

    // Optional: Show a micro-confirmation toast
    _showProtocolUpdate(themeKey);
  }

  void _showProtocolUpdate(String theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 1),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _themeController.isDarkMode ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text("PROTOCOL_UPDATED: $theme",
                style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: _themeController.isDarkMode
                        ? Colors.black
                        : Colors.white)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _themeController.isDarkMode;
    String activeTheme = isDark ? "CYBER_ONYX" : "LUXURY_MODERN";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080808) : Colors.white,
      appBar: _buildAppBar(context, "INTERFACE_STYLE"),
      body: Stack(
        children: [
          // Background ambient pulse (Optional aesthetic touch)
          Positioned(
            bottom: -50,
            right: -50,
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.01)
                    : Colors.black.withOpacity(0.02),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text("SELECT_ENVIRONMENT",
                      style: GoogleFonts.spaceMono(
                          fontSize: 8,
                          color: isDark ? Colors.white24 : MuraColors.mute,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),

                _themeCard(
                  "LUXURY_MODERN",
                  "LIGHT_MINIMAL_V2 // HIGH_CLARITY",
                  activeTheme == "LUXURY_MODERN",
                  LucideIcons.sun,
                ),

                _themeCard(
                  "CYBER_ONYX",
                  "DARK_HIGH_CONTRAST // STEALTH_MODE",
                  activeTheme == "CYBER_ONYX",
                  LucideIcons.moon,
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white10, thickness: 0.5),
                const SizedBox(height: 24),

                // Experimental Section
                Opacity(
                  opacity: 0.3,
                  child: _themeCard(
                    "MONO_GLASS",
                    "EXPERIMENTAL_BLUR // LOCKED",
                    false,
                    LucideIcons.lock,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    final bool isDark = _themeController.isDarkMode;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 70,
      leading: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : MuraColors.microBorder.withOpacity(0.5)),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.chevronLeft,
                size: 14,
                color: isDark ? Colors.white : MuraColors.textPrimary),
          ),
        ),
      ),
      title: Text(title,
          style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: isDark ? Colors.white : MuraColors.textPrimary)),
      centerTitle: true,
    );
  }

  Widget _themeCard(
      String title, String subtitle, bool isSelected, IconData icon) {
    final bool isDark = _themeController.isDarkMode;

    return GestureDetector(
      onTap: () => _handleThemeChange(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : MuraColors.textPrimary)
              : (isDark ? Colors.white.withOpacity(0.02) : Colors.transparent),
          border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white : MuraColors.textPrimary)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : MuraColors.microBorder),
              width: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : MuraColors.mute),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.spaceMono(
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark
                                  ? Colors.white
                                  : MuraColors.textPrimary),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: GoogleFonts.spaceMono(
                          color: isSelected
                              ? (isDark ? Colors.black45 : Colors.white54)
                              : MuraColors.mute.withOpacity(0.5),
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.checkCircle2,
                  color: Colors.greenAccent, size: 14),
          ],
        ),
      ),
    );
  }
}
