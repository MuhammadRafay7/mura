import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
// Assuming your headers live here

class MuraSettingsDetailView extends StatelessWidget {
  final String title;

  const MuraSettingsDetailView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? MuraColors.background : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Minimal Back Interface
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: MuraColors.microBorder.withOpacity(0.3),
                          width: 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 10,
                        color: MuraColors.textPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Technical Centered Title
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: MuraColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Symmetry Buffer
                  const SizedBox(width: 34),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main Content Area
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${title}_INTERFACE_INITIALIZED",
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    color: MuraColors.mute.withOpacity(0.5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                // Visual placeholder for the "Loading/Ready" state
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: MuraColors.userBubble,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // Grounding "System Status" Bar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "MURA_CORE_V2 // SESSION_SECURE",
                style: GoogleFonts.spaceMono(
                  fontSize: 7,
                  color: MuraColors.mute.withOpacity(0.3),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
