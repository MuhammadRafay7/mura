import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/colors.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/glass_panel.dart';
import '../../main.dart'; // IMPORTED MAIN TO ACCESS MAINLAYOUT

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isRegistering = false;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("REQUIRED_FIELDS_EMPTY");
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      AuthResponse response;
      if (_isRegistering) {
        response = await MuraSupabase.client.auth.signUp(
          email: email,
          password: password,
        );
      } else {
        response = await MuraSupabase.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      if (response.user != null && mounted) {
        // --- FIX: NAVIGATE TO MAINLAYOUT SO THE NAVBAR SHOWS ---
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("PROTOCOL_FAILURE: AUTH_UNEXPECTED");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        content: Text(message.toUpperCase(),
            style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : MuraColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MuraColors.userBubble.withOpacity(isDark ? 0.03 : 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 64),
                    _buildLoginForm(isDark),
                    const SizedBox(height: 32),
                    _buildSubmitButton(isDark),
                    const SizedBox(height: 20),
                    _buildToggleMode(isDark),
                    const SizedBox(height: 48),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Text('MURA // ARCHIVE',
            style: GoogleFonts.spaceMono(
                color: isDark ? Colors.white : MuraColors.textPrimary,
                fontSize: 14,
                letterSpacing: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border:
                Border.all(color: MuraColors.mute.withOpacity(0.3), width: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            _isRegistering ? 'NEW_NODE_REGISTRATION' : 'CENTRAL_AUTH_GATEWAY',
            style: GoogleFonts.spaceMono(
                color: MuraColors.mute, fontSize: 8, letterSpacing: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return GlassPanel(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            _buildTextField(
              isDark: isDark,
              controller: _emailController,
              label: "EMAIL_IDENTITY",
              icon: LucideIcons.mail,
              hint: "user@mura.archive",
            ),
            const SizedBox(height: 32),
            _buildTextField(
              isDark: isDark,
              controller: _passwordController,
              label: "SECURE_PASSCODE",
              icon: LucideIcons.lock,
              hint: "••••••••",
              isPassword: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.spaceMono(
                color: MuraColors.mute,
                fontSize: 8,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          cursorColor: isDark ? Colors.white : MuraColors.userBubble,
          style: GoogleFonts.spaceMono(
              color: isDark ? Colors.white : MuraColors.textPrimary,
              fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceMono(
                color: MuraColors.mute.withOpacity(0.3), fontSize: 13),
            prefixIcon: Icon(icon, size: 16, color: MuraColors.mute),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 16,
                      color: MuraColors.mute,
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: MuraColors.microBorder, width: 0.5)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: isDark ? Colors.white : MuraColors.userBubble,
                    width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return InkWell(
      onTap: _isLoading ? null : _handleAuth,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: _isLoading
              ? Colors.transparent
              : (isDark ? Colors.white : MuraColors.textPrimary),
          border: Border.all(
              color: isDark ? Colors.white : MuraColors.textPrimary, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.black : Colors.white))
              : Text(_isRegistering ? "CREATE_IDENTITY" : "INITIALIZE_SESSION",
                  style: GoogleFonts.spaceMono(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
        ),
      ),
    );
  }

  Widget _buildToggleMode(bool isDark) {
    return TextButton(
      onPressed: () => setState(() => _isRegistering = !_isRegistering),
      child: Text(
        _isRegistering ? "EXISTING_USER? LOGIN" : "NEW_USER? REGISTER",
        style: GoogleFonts.spaceMono(
          color: MuraColors.mute,
          fontSize: 9,
          letterSpacing: 1,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text("SYSTEM_V.3.0.1 // ENCRYPTED_CONNECTION",
        style: GoogleFonts.spaceMono(
            fontSize: 7,
            color: MuraColors.mute.withOpacity(0.4),
            letterSpacing: 2));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
