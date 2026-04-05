import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/services/supabase_service.dart';
import '../chat/chat_screen.dart';

// --- DATA MODEL ---
class SignalNode {
  final String name;
  final String status;
  final bool isGroup;
  final String uid;
  final String lastTime;
  final String? avatarUrl;

  SignalNode({
    required this.name,
    required this.status,
    required this.isGroup,
    required this.uid,
    required this.lastTime,
    this.avatarUrl,
  });

  factory SignalNode.fromJson(Map<String, dynamic> json) {
    final DateTime updatedAt =
        DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String());
    final String timeString =
        "${updatedAt.hour}:${updatedAt.minute.toString().padLeft(2, '0')}";

    return SignalNode(
      name: json['name'] ?? 'UNKNOWN_NODE',
      status: json['status'] ?? 'IDLE',
      isGroup: json['is_group'] ?? false,
      uid: json['id'].toString(),
      lastTime: timeString,
      // CRITICAL: Ensure this matches your Supabase column name exactly
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  int _activeFilterIndex = 0;
  final List<String> _filters = ["ALL_NODES", "UNREAD", "GROUPS"];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String myId = MuraSupabase.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100, right: 8),
        child: FloatingActionButton(
          onPressed: _createNewGroup,
          backgroundColor: isDark ? Colors.white : MuraColors.textPrimary,
          elevation: 10,
          shape: const CircleBorder(),
          child: Icon(LucideIcons.plus,
              color: isDark ? Colors.black : Colors.white, size: 20),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: MuraSupabase.client
            .from('nodes')
            .stream(primaryKey: ['id']).order('updated_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("PROTOCOL_ERROR",
                    style: GoogleFonts.spaceMono(
                        fontSize: 10, color: Colors.red)));
          }

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 1, color: MuraColors.mute));
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: MuraSupabase.client
                .from('friendships')
                .stream(primaryKey: ['id']),
            builder: (context, friendshipSnapshot) {
              if (!friendshipSnapshot.hasData) return const SizedBox();

              final List<String> friendIds = friendshipSnapshot.data!
                  .where((f) => f['status'] == 'accepted')
                  .map((f) => f['sender_id'] == myId
                      ? f['receiver_id']
                      : f['sender_id'])
                  .cast<String>()
                  .toList();

              final List<SignalNode> allNodes = snapshot.data!
                  .map((json) => SignalNode.fromJson(json))
                  .where((node) => friendIds.contains(node.uid) || node.isGroup)
                  .toList();

              final filteredNodes = _applyFilters(allNodes);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    sliver: SliverToBoxAdapter(child: _buildSearchNode(isDark)),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                            children: List.generate(_filters.length,
                                (index) => _buildFilterTab(index))),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildLiveContactRow(
                            context, filteredNodes[index], myId),
                        childCount: filteredNodes.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLiveContactRow(
      BuildContext context, SignalNode node, String myId) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: MuraSupabase.client.from('messages').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final int unreadCount = snapshot.hasData
            ? snapshot.data!
                .where((m) =>
                    m['receiver_id'] == myId &&
                    m['sender_id'] == node.uid &&
                    m['is_read'] == false)
                .length
            : 0;

        final bool hasUnread = unreadCount > 0;

        if (_activeFilterIndex == 1 && !hasUnread)
          return const SizedBox.shrink();

        return InkWell(
          onTap: () async {
            HapticFeedback.mediumImpact();
            if (hasUnread) {
              await MuraSupabase.client
                  .from('messages')
                  .update({'is_read': true})
                  .eq('sender_id', node.uid)
                  .eq('receiver_id', myId)
                  .eq('is_read', false);
            }
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  username: node.name,
                  receiverId: node.uid,
                ),
              ),
            );
          },
          child: Container(
            key: ValueKey('${node.uid}_$unreadCount'),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : MuraColors.microBorder,
                        width: 0.5))),
            child: Row(
              children: [
                _buildAvatar(
                    node.name, node.isGroup, hasUnread, node.avatarUrl),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.name,
                          style: GoogleFonts.spaceMono(
                              color: isDark
                                  ? Colors.white
                                  : MuraColors.textPrimary,
                              fontSize: 12,
                              fontWeight:
                                  hasUnread ? FontWeight.w900 : FontWeight.bold,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text(node.status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceMono(
                              fontSize: 8,
                              letterSpacing: 0.2,
                              color: hasUnread
                                  ? (isDark
                                      ? Colors.white
                                      : MuraColors.textPrimary)
                                  : MuraColors.mute.withOpacity(0.6))),
                    ],
                  ),
                ),
                _buildMetadata(node, unreadCount),
              ],
            ),
          ),
        );
      },
    );
  }

  List<SignalNode> _applyFilters(List<SignalNode> nodes) {
    List<SignalNode> result = List.from(nodes);
    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
              (n) => n.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_activeFilterIndex == 2) {
      result = result.where((n) => n.isGroup).toList();
    }
    return result;
  }

  Widget _buildMetadata(SignalNode node, int unreadCount) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(node.lastTime,
            style: GoogleFonts.spaceMono(fontSize: 7, color: MuraColors.mute)),
        if (unreadCount > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: isDark ? Colors.white : MuraColors.textPrimary,
                borderRadius: BorderRadius.circular(4)),
            child: Text(unreadCount.toString(),
                style: GoogleFonts.spaceMono(
                    color: isDark ? Colors.black : Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ],
    );
  }

  // --- REFINED AVATAR LOGIC ---
  Widget _buildAvatar(
      String name, bool isGroup, bool highlight, String? avatarUrl) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String initial = name.isEmpty
        ? "?"
        : (name.startsWith('@') ? name[1] : name[0]).toUpperCase();

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isGroup ? 12 : 22),
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
        border: Border.all(
            color: highlight
                ? (isDark ? Colors.white : MuraColors.textPrimary)
                : MuraColors.microBorder.withOpacity(0.3),
            width: highlight ? 1.5 : 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isGroup ? 12 : 22),
        child: avatarUrl != null && avatarUrl.trim().isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                // Shows initials if the network link is broken or 404
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitials(initial, isDark),
                // Shows a subtle loading state while fetching the image
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        color: isDark ? Colors.white : MuraColors.mute,
                      ),
                    ),
                  );
                },
              )
            : _buildInitials(initial, isDark),
      ),
    );
  }

  Widget _buildInitials(String initial, bool isDark) {
    return Center(
      child: Text(initial,
          style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MuraColors.textPrimary)),
    );
  }

  Widget _buildSearchNode(bool isDark) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: MuraColors.microBorder.withOpacity(0.2), width: 0.5),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        cursorColor: isDark ? Colors.white : MuraColors.textPrimary,
        style: GoogleFonts.spaceMono(
            fontSize: 12,
            color: isDark ? Colors.white : MuraColors.textPrimary),
        decoration: InputDecoration(
          hintText: "SEARCH_REGISTRY...",
          hintStyle: GoogleFonts.spaceMono(
              fontSize: 10,
              color: MuraColors.mute.withOpacity(0.5),
              letterSpacing: 2),
          prefixIcon: Icon(LucideIcons.search,
              size: 16, color: isDark ? Colors.white54 : MuraColors.mute),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index) {
    bool isActive = _activeFilterIndex == index;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _activeFilterIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white : MuraColors.textPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isActive
                  ? (isDark ? Colors.white : MuraColors.textPrimary)
                  : MuraColors.microBorder.withOpacity(0.3),
              width: 0.5),
        ),
        child: Text(_filters[index],
            style: GoogleFonts.spaceMono(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: isActive
                    ? (isDark ? Colors.black : Colors.white)
                    : MuraColors.mute)),
      ),
    );
  }

  void _createNewGroup() {
    final TextEditingController groupNameController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _buildSheetHandle(),
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: TextField(
                  controller: groupNameController,
                  autofocus: true,
                  style: GoogleFonts.spaceMono(
                      color: isDark ? Colors.white : MuraColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: "NAME_YOUR_UPLINK...",
                    hintStyle: GoogleFonts.spaceMono(color: MuraColors.mute),
                  ),
                ),
              ),
              const Spacer(),
              _buildStageButton("INITIALIZE_UPLINK", () {
                _finalizeGroup(groupNameController.text);
                Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finalizeGroup(String name) async {
    try {
      await MuraSupabase.client.from('nodes').insert({
        'name': name.isEmpty ? "NEW_UPLINK" : name.toUpperCase(),
        'status': 'SECURE_UPLINK_INITIALIZED',
        'is_group': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("MURA_DB_WRITE_FAILURE: $e");
    }
  }

  Widget _buildStageButton(String label, VoidCallback onPressed) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : MuraColors.textPrimary,
          minimumSize: const Size(double.infinity, 64),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: GoogleFonts.spaceMono(
                color: isDark ? Colors.black : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        width: 32,
        height: 3,
        decoration: BoxDecoration(
            color: MuraColors.microBorder.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2)));
  }
}
