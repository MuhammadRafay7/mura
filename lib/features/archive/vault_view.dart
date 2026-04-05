import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/constants/colors.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/glass_panel.dart';

class VaultView extends StatefulWidget {
  const VaultView({super.key});

  @override
  State<VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<VaultView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _myRelations = [];
  bool _isSearching = false;

  final _supabase = MuraSupabase.client;
  final String _currentUserId = MuraSupabase.client.auth.currentUser?.id ?? '';

  // --- STREAMS ---
  // We use a stream to listen for any changes in the friendships table
  late final Stream<List<Map<String, dynamic>>> _friendsStream =
      _supabase.from('friendships').stream(primaryKey: ['id']);

  // --- LOGIC ---

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .neq('id', _currentUserId)
          .limit(10);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data);
        _isSearching = false;
      });
    } catch (e) {
      debugPrint("SEARCH_ERROR: $e");
    }
  }

  Future<void> _respondToRequest(String requestId, String status) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': status}).eq('id', requestId);

      _showStatusSnackBar(
          status == 'accepted' ? "UPLINK_ESTABLISHED" : "SIGNAL_IGNORED");
    } catch (e) {
      debugPrint("RESPONSE_ERROR: $e");
    }
  }

  Future<void> _sendUplinkRequest(String targetId, String username) async {
    try {
      await _supabase.from('friendships').upsert({
        'sender_id': _currentUserId,
        'receiver_id': targetId,
        'status': 'pending',
      });
      if (mounted) Navigator.pop(context);
      _showStatusSnackBar("UPLINK_INITIALIZED // @${username.toUpperCase()}");
    } catch (e) {
      _showStatusSnackBar("UPLINK_FAILURE: SIGNAL_EXISTS", isError: true);
    }
  }

  Future<void> _removeFriend(String friendId) async {
    try {
      await _supabase.from('friendships').delete().or(
          'and(sender_id.eq.$_currentUserId,receiver_id.eq.$friendId),and(sender_id.eq.$friendId,receiver_id.eq.$_currentUserId)');

      if (mounted) {
        Navigator.pop(context);
        _showStatusSnackBar("UPLINK_TERMINATED");
      }
    } catch (e) {
      _showStatusSnackBar("TERMINATION_FAILED", isError: true);
    }
  }

  void _showStatusSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : Colors.white,
        content: Text(message,
            style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isError ? Colors.white : Colors.black)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _friendsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("SYNC_ERROR"));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final allData = snapshot.data!;

                // Filter all relations involving the current user
                _myRelations = allData
                    .where((r) =>
                        r['sender_id'] == _currentUserId ||
                        r['receiver_id'] == _currentUserId)
                    .toList();

                // 1. Identify Incoming Pending Requests
                final incomingRequests = _myRelations
                    .where((r) =>
                        r['receiver_id'] == _currentUserId &&
                        r['status'] == 'pending')
                    .toList();

                // 2. Identify Accepted Friends
                final acceptedFriendIds = _myRelations
                    .where((r) => r['status'] == 'accepted')
                    .map((r) => r['sender_id'] == _currentUserId
                        ? r['receiver_id']
                        : r['sender_id'])
                    .toList();

                // 3. Identify Blocked Users
                final blockedIds = _myRelations
                    .where((r) =>
                        r['status'] == 'blocked' &&
                        r['sender_id'] == _currentUserId)
                    .map((r) => r['receiver_id'])
                    .toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),

                    // --- INCOMING REQUESTS SECTION ---
                    if (_searchQuery.isEmpty && incomingRequests.isNotEmpty)
                      SliverToBoxAdapter(
                          child: _buildRequestInbox(incomingRequests, isDark)),

                    if (_searchQuery.isEmpty) ...[
                      _buildHeader(acceptedFriendIds.isEmpty
                          ? "NO_ACTIVE_UPLINKS"
                          : "ENCRYPTED_CONNECTIONS"),
                      _buildGrid(acceptedFriendIds, isDark, isBlocked: false),
                      if (blockedIds.isNotEmpty) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        _buildHeader("BLACKLISTED_NODES // VIEW_ONLY",
                            color: Colors.redAccent.withOpacity(0.6)),
                        _buildGrid(blockedIds, isDark, isBlocked: true),
                      ],
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
            ),
          ),

          // Search Overlay
          if (_searchQuery.isNotEmpty)
            Positioned.fill(
              top: 130,
              child: Container(
                color: isDark
                    ? Colors.black.withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                child: _buildSearchResultsList(isDark),
              ),
            ),

          Positioned(top: 0, left: 0, right: 0, child: _buildSearchBar(isDark)),
        ],
      ),
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildHeader(String text, {Color? color}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Text(text,
            style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: color ?? MuraColors.mute,
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- GRID WIDGET (For Accepted/Blocked) ---
  Widget _buildGrid(List<dynamic> ids, bool isDark, {required bool isBlocked}) {
    if (ids.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase.from('profiles').select().inFilter('id', ids),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SliverToBoxAdapter(child: SizedBox());
        final profiles = snapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemBuilder: (context, index) =>
                _buildProfileCard(profiles[index], isDark, isBlocked),
            childCount: profiles.length,
          ),
        );
      },
    );
  }

  // --- INBOX WIDGET ---
  Widget _buildRequestInbox(List<Map<String, dynamic>> requests, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GlassPanel(
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 15),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: const Icon(LucideIcons.radio,
              color: Colors.greenAccent, size: 18),
          title: Text("INCOMING_SIGNALS (${requests.length})",
              style: GoogleFonts.spaceMono(
                  fontSize: 10, fontWeight: FontWeight.bold)),
          children:
              requests.map((req) => _buildRequestTile(req, isDark)).toList(),
        ),
      ),
    );
  }

  // --- INDIVIDUAL REQUEST TILE ---
  Widget _buildRequestTile(Map<String, dynamic> request, bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      // Explicitly fetching the sender's profile info
      future: _supabase
          .from('profiles')
          .select()
          .eq('id', request['sender_id'])
          .single(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(minHeight: 1);
        final sender = snapshot.data!;

        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          leading: CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(sender['avatar_url'] ??
                  "https://picsum.photos/seed/${sender['id']}/100")),
          title: Text("@${sender['username']}".toUpperCase(),
              style: GoogleFonts.spaceMono(
                  fontSize: 11, fontWeight: FontWeight.bold)),
          subtitle: Text("REQUESTING_ACCESS",
              style:
                  GoogleFonts.spaceMono(fontSize: 8, color: MuraColors.mute)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ACCEPT BUTTON
              IconButton(
                  icon: const Icon(LucideIcons.checkCircle2,
                      color: Colors.greenAccent, size: 20),
                  onPressed: () =>
                      _respondToRequest(request['id'], 'accepted')),
              // IGNORE/DECLINE BUTTON
              IconButton(
                  icon: const Icon(LucideIcons.xCircle,
                      color: Colors.redAccent, size: 20),
                  onPressed: () =>
                      _respondToRequest(request['id'], 'declined')),
            ],
          ),
        );
      },
    );
  }

  // --- SEARCH BAR & RESULTS ---
  Widget _buildSearchBar(bool isDark) {
    return GlassPanel(
      height: 110,
      borderRadius: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(LucideIcons.search,
                    size: 18, color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _performSearch(val);
                    },
                    style: GoogleFonts.spaceMono(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "SEARCH_NODES...",
                      hintStyle: GoogleFonts.spaceMono(
                          color: isDark ? Colors.white30 : Colors.black38,
                          fontSize: 11),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final existingRel = _myRelations.firstWhere(
          (r) => r['sender_id'] == user['id'] || r['receiver_id'] == user['id'],
          orElse: () => {},
        );

        return ListTile(
          onTap: () => _showProfilePreview(
            user,
            isFriend: existingRel['status'] == 'accepted',
            isBlocked: existingRel['status'] == 'blocked',
            isPending: existingRel['status'] == 'pending',
          ),
          leading: CircleAvatar(
              backgroundImage: NetworkImage(user['avatar_url'] ??
                  "https://picsum.photos/seed/${user['id']}/100")),
          title: Text("@${user['username']}".toUpperCase(),
              style: GoogleFonts.spaceMono(
                  fontSize: 12, fontWeight: FontWeight.bold)),
          trailing: const Icon(LucideIcons.chevronRight,
              size: 18, color: Colors.white24),
        );
      },
    );
  }

  // --- PROFILE PREVIEW CARD ---
  Widget _buildProfileCard(
      Map<String, dynamic> profile, bool isDark, bool isBlocked) {
    return Opacity(
      opacity: isBlocked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: () => _showProfilePreview(profile,
            isFriend: !isBlocked, isBlocked: isBlocked),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                profile['avatar_url'] ??
                    "https://picsum.photos/seed/${profile['id']}/400/300",
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text("@${profile['username']}".toUpperCase(),
                style: GoogleFonts.spaceMono(
                    fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showProfilePreview(Map<String, dynamic> profile,
      {bool isFriend = false, bool isBlocked = false, bool isPending = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassPanel(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profile['avatar_url'] ??
                    "https://picsum.photos/seed/${profile['id']}/400")),
            const SizedBox(height: 15),
            Text("@${profile['username']}".toUpperCase(),
                style: GoogleFonts.spaceMono(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  if (isBlocked)
                    ElevatedButton(
                        onPressed: () => _removeFriend(profile['id']),
                        child: const Text("RESTORE_SIGNAL"))
                  else if (isPending)
                    const Text("SIGNAL_PENDING...",
                        style: TextStyle(color: Colors.white38))
                  else if (isFriend)
                    ElevatedButton(
                        onPressed: () => _removeFriend(profile['id']),
                        child: const Text("TERMINATE_CONNECTION"))
                  else
                    ElevatedButton(
                        onPressed: () => _sendUplinkRequest(
                            profile['id'], profile['username']),
                        child: const Text("SEND_SIGNAL_REQUEST")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
