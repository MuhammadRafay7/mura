import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/colors.dart';
import '../../core/services/supabase_service.dart'; // Ensure you have your Supabase client here

class MuraPrivacyView extends StatefulWidget {
  const MuraPrivacyView({super.key});

  @override
  State<MuraPrivacyView> createState() => _MuraPrivacyViewState();
}

class _MuraPrivacyViewState extends State<MuraPrivacyView> {
  final _supabase = MuraSupabase.client;

  // Stream to listen to security changes live from Supabase
  late final Stream<Map<String, dynamic>> _securityStream;

  @override
  void initState() {
    super.initState();
    final userId = _supabase.auth.currentUser!.id;
    _securityStream = _supabase
        .from('user_security')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) => data.first);
  }

  Future<void> _updateSecurity(String key, bool value) async {
    try {
      await _supabase.from('user_security').update({
        key: value,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      debugPrint("SECURITY_UPDATE_FAILED: $e");
    }
  }

  Future<void> _wipeSessions() async {
    try {
      await _supabase.rpc('wipe_all_sessions');
      // After wiping, the user is effectively logged out
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      debugPrint("WIPE_FAILURE: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Map<String, dynamic>>(
      stream: _securityStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!;
        final bool is2FA = data['is_two_factor'] ?? false;
        final bool isBio = data['is_biometric'] ?? false;
        final bool isEnc = data['is_encrypted'] ?? false;
        final bool isFullySecure = isBio && isEnc;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          appBar: _buildAppBar(context, "PRIVACY_PROTOCOL", isDark),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSecurityHeader(isFullySecure, isEnc),
                const SizedBox(height: 48),
                _buildToggleTile(
                    "TWO_FACTOR_AUTH",
                    "ENHANCED_UPLINK_SECURITY",
                    is2FA,
                    (val) => _updateSecurity('is_two_factor', val),
                    isDark),
                _buildToggleTile(
                    "BIOMETRIC_LOCK",
                    "SECURE_ENCLAVE_ACCESS",
                    isBio,
                    (val) => _updateSecurity('is_biometric', val),
                    isDark),
                _buildToggleTile(
                    "ENCRYPTED_CHATS",
                    "END_TO_END_PROTOCOL",
                    isEnc,
                    (val) => _updateSecurity('is_encrypted', val),
                    isDark),
                const Spacer(),
                _buildWipeAction(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, String title, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : MuraColors.microBorder.withOpacity(0.2)),
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
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: isDark ? Colors.white : MuraColors.textPrimary)),
      centerTitle: true,
    );
  }

  Widget _buildSecurityHeader(bool isFullySecure, bool isEncrypted) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MuraColors.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isFullySecure ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
            color: isFullySecure ? Colors.white : Colors.orangeAccent,
            size: 22,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFullySecure
                    ? "SHIELD_LEVEL: MAXIMUM"
                    : "SHIELD_LEVEL: MODEST",
                style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isEncrypted ? "ALL_SYSTEMS_ENCRYPTED" : "UPLINK_UNSECURED",
                style: GoogleFonts.spaceMono(
                    color: Colors.white.withOpacity(0.4), fontSize: 7),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool isActive,
      Function(bool) onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : MuraColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.spaceMono(
                        fontSize: 7, color: MuraColors.mute.withOpacity(0.6))),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: isActive,
              onChanged: (val) {
                HapticFeedback.mediumImpact();
                onChanged(val);
              },
              activeThumbColor: Colors.greenAccent,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWipeAction(bool isDark) {
    return InkWell(
      onTap: () {
        HapticFeedback.heavyImpact();
        _wipeSessions();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          border: Border.all(color: Colors.red.withOpacity(0.2), width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text("WIPE_REMOTE_SESSIONS",
              style: GoogleFonts.spaceMono(
                  color: Colors.redAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
        ),
      ),
    );
  }
}
