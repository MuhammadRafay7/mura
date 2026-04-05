import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class MuraStyles {
  // 1. The "Statement" Heading - High contrast, cinematic serif
  static TextStyle headingMain = GoogleFonts.cormorantGaramond(
    color: MuraColors.textPrimary,
    fontSize: 48,
    fontWeight: FontWeight.w300,
    height: 0.9,
    letterSpacing: -1,
  );

  // 2. The "Technical" Label - Wide, mono, architectural tracking
  static TextStyle labelTechnical = GoogleFonts.spaceMono(
    color: MuraColors.mute,
    fontSize: 9,
    fontWeight: FontWeight.bold,
    letterSpacing: 6, // "Tracking-widest" look
  );

  // 3. Metadata Style - Small, clean, functional
  static TextStyle metadata = GoogleFonts.spaceMono(
    color: MuraColors.mute.withOpacity(0.5),
    fontSize: 7,
    letterSpacing: 2,
  );
}

// Global Spacer for consistent vertical rhythm
class MuraSpacing {
  static const double radius = 24.0;
  static const double outerPadding = 32.0;
}
