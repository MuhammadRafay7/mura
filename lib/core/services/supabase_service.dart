import 'package:supabase_flutter/supabase_flutter.dart';

class MuraSupabase {
  // --- CONFIGURATION ---
  // Replace these with your actual Project URL and Anon Key from Supabase Dashboard
  static const String _url = 'https://your-project-id.supabase.co';
  static const String _anonKey = 'your-anon-public-key';

  /// Initialize the Supabase Client
  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  /// Direct access to the Supabase Client
  static SupabaseClient get client => Supabase.instance.client;

  /// Helper to get current User ID
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Helper to check if user is logged in
  static bool get isAuthenticated => client.auth.currentUser != null;
}
