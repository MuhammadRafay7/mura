import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';

class GlobalView extends StatefulWidget {
  const GlobalView({super.key});

  @override
  State<GlobalView> createState() => _GlobalViewState();
}

class _GlobalViewState extends State<GlobalView> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  // Search function to find users in the global registry
  Future<void> _searchRegistry(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await _supabase
          .from('nodes')
          .select()
          .ilike('name', '%$query%') // Case-insensitive search
          .limit(10);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // "Connect" logic: Updates the status to show you've linked
  Future<void> _connectToNode(String id) async {
    try {
      await _supabase.from('nodes').update({
        'status': 'CONNECTION_ESTABLISHED',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("UPLINK_SUCCESSFUL")),
      );
    } catch (e) {
      debugPrint("Connect error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 60),
              Text("NETWORK_EXPLORER",
                  style: GoogleFonts.spaceMono(
                      letterSpacing: 2,
                      color: MuraColors.mute,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildSearchBar(isDark),
              const SizedBox(height: 40),
              Text(
                  _searchController.text.isEmpty
                      ? "SUGGESTED_NODES"
                      : "REGISTRY_MATCHES",
                  style: GoogleFonts.spaceMono(
                      letterSpacing: 4,
                      color: MuraColors.mute,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                    child: LinearProgressIndicator(
                        color: MuraColors.userBubble,
                        backgroundColor: Colors.transparent))
              else if (_searchResults.isEmpty &&
                  _searchController.text.isNotEmpty)
                Center(
                    child: Text("NO_MATCHES_FOUND",
                        style: GoogleFonts.spaceMono(
                            fontSize: 10, color: MuraColors.mute)))
              else
                ..._searchResults
                    .map((node) => _globalUser(context, node, isDark)),
              const SizedBox(height: 140),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: isDark ? Colors.white10 : MuraColors.microBorder,
                  width: 1.0))),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => _searchRegistry(val),
        style: GoogleFonts.inter(
            color: isDark ? Colors.white : MuraColors.textPrimary,
            fontSize: 16),
        cursorColor: MuraColors.userBubble,
        decoration: InputDecoration(
          hintText: "SEARCH_REGISTRY...",
          hintStyle: GoogleFonts.spaceMono(
              color: MuraColors.mute.withOpacity(0.4), fontSize: 12),
          border: InputBorder.none,
          suffixIcon: Icon(LucideIcons.search,
              color: isDark ? Colors.white : MuraColors.textPrimary, size: 18),
        ),
      ),
    );
  }

  Widget _globalUser(
      BuildContext context, Map<String, dynamic> node, bool isDark) {
    final String name = node['name'] ?? 'UNKNOWN';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : MuraColors.microBorder,
                  width: 0.5))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isDark ? Colors.white10 : MuraColors.background,
          child: Text(
              name.startsWith('@')
                  ? name[1].toUpperCase()
                  : name[0].toUpperCase(),
              style: GoogleFonts.spaceMono(
                  color: isDark ? Colors.white : Colors.black, fontSize: 12)),
        ),
        title: Text(name,
            style: GoogleFonts.inter(
                color: isDark ? Colors.white : MuraColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        trailing: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: MuraColors.userBubble.withOpacity(0.3))),
          child: TextButton(
            onPressed: () => _connectToNode(node['id'].toString()),
            child: const Text("CONNECT",
                style: TextStyle(
                    color: MuraColors.userBubble,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
        ),
      ),
    );
  }
}
