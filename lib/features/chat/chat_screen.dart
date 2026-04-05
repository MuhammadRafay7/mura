import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

// Mura Design System Imports
import '../../core/constants/colors.dart';
import '../../shared/widgets/glass_panel.dart';
import '../../core/services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.username,
    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isUploading = false;
  String? _currentlyPlayingUrl;

  late final Stream<List<Map<String, dynamic>>> _messageStream;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
    _initMessageStream();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  // --- PROTOCOL: SYNC READ STATUS ---
  Future<void> _markMessagesAsRead() async {
    final myId = MuraSupabase.currentUserId;
    if (myId == null) return;

    try {
      await MuraSupabase.client
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', widget.receiverId)
          .eq('receiver_id', myId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint("MURA_READ_SYNC_FAILURE: $e");
    }
  }

  // --- DATA UPLINK: REALTIME STREAM ---
  void _initMessageStream() {
    final myId = MuraSupabase.currentUserId.toString();
    final rId = widget.receiverId.toString();

    _messageStream = MuraSupabase.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((maps) => maps.where((m) {
              final s = m['sender_id'].toString();
              final r = m['receiver_id'].toString();
              return (s == myId && r == rId) || (s == rId && r == myId);
            }).toList());
  }

  // --- SUPABASE CLOUD UPLOAD ---
  Future<String?> _uploadMedia(String filePath, String type) async {
    setState(() => _isUploading = true);
    try {
      final file = File(filePath);
      final ext = type == "voice" ? "m4a" : (type == "video" ? "mp4" : "jpg");
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = '${MuraSupabase.currentUserId}/$fileName';

      // Ensure the 'chat_assets' bucket exists and is public in Supabase Dashboard
      await MuraSupabase.client.storage
          .from('chat_assets')
          .upload(storagePath, file);

      return MuraSupabase.client.storage
          .from('chat_assets')
          .getPublicUrl(storagePath);
    } catch (e) {
      debugPrint("MURA_UPLOAD_ERROR: $e");
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // --- SIGNAL EMISSION ---
  Future<void> _sendSignal(
      {required String content, required String type}) async {
    final myId = MuraSupabase.currentUserId;
    if (myId == null || (type == "text" && content.trim().isEmpty)) return;

    String finalContent = content;

    if (type != "text") {
      final url = await _uploadMedia(content, type);
      if (url == null) return;
      finalContent = url;
    }

    try {
      await MuraSupabase.client.from('messages').insert({
        'sender_id': myId,
        'receiver_id': widget.receiverId,
        'content': finalContent,
        'type': type,
        'is_read': false,
      });
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint("MURA_UPLINK_ERROR: $e");
    }
  }

  // --- HARDWARE INTERACTION ---
  Future<void> _handleMedia(String type) async {
    try {
      XFile? file;
      if (type == "image") {
        file = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 70);
      } else if (type == "video") {
        file = await _picker.pickVideo(source: ImageSource.gallery);
      } else if (type == "camera") {
        file = await _picker.pickImage(
            source: ImageSource.camera, imageQuality: 70);
      }

      if (file != null) {
        if (mounted) Navigator.pop(context);
        await _sendSignal(content: file.path, type: type);
      }
    } catch (e) {
      debugPrint("MURA_HARDWARE_EXCEPTION: $e");
    }
  }

  Future<void> _toggleVoice() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) await _sendSignal(content: path, type: "voice");
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final path =
              '${dir.path}/mura_v_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() => _isRecording = true);
          HapticFeedback.lightImpact();
        }
      }
    } catch (e) {
      debugPrint("MURA_MIC_EXCEPTION: $e");
    }
  }

  Future<void> _playVoice(String url) async {
    if (_currentlyPlayingUrl == url) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingUrl = null);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() => _currentlyPlayingUrl = url);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _currentlyPlayingUrl = null);
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : MuraColors.background,
      appBar: _buildMuraAppBar(),
      body: Column(
        children: [
          if (_isUploading)
            const LinearProgressIndicator(
                minHeight: 2,
                color: Colors.white,
                backgroundColor: Colors.transparent),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: Text("LINKING_ARCHIVE...",
                          style: GoogleFonts.spaceMono(
                              fontSize: 8, color: MuraColors.mute)));
                }

                final messages = snapshot.data!;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0)
                      return _buildSystemLog(
                          "PROTOCOL: SECURE_UPLINK_ESTABLISHED");
                    return _buildModernTelegramBubble(messages[index - 1]);
                  },
                );
              },
            ),
          ),
          _buildTelegramInputBar(),
        ],
      ),
    );
  }

  Widget _buildModernTelegramBubble(Map<String, dynamic> msg) {
    bool isMe =
        msg["sender_id"].toString() == MuraSupabase.currentUserId.toString();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: (msg["type"] == "image" ||
                msg["type"] == "camera" ||
                msg["type"] == "video")
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? (isDark ? Colors.white : MuraColors.userBubble)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: isDark ? Colors.white10 : MuraColors.microBorder,
                  width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: _renderBubbleContent(msg),
        ),
      ),
    );
  }

  Widget _renderBubbleContent(Map<String, dynamic> msg) {
    bool isMe =
        msg["sender_id"].toString() == MuraSupabase.currentUserId.toString();
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color txtColor = isMe
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : MuraColors.textPrimary);

    switch (msg["type"]) {
      case "image":
      case "camera":
        return Image.network(msg["content"],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const Icon(LucideIcons.imageOff, color: Colors.red));
      case "video":
        return Container(
          height: 180,
          color: Colors.black,
          child: const Center(
              child:
                  Icon(LucideIcons.playCircle, color: Colors.white, size: 40)),
        );
      case "voice":
        bool isPlaying = _currentlyPlayingUrl == msg["content"];
        return InkWell(
          onTap: () => _playVoice(msg["content"]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isPlaying ? LucideIcons.pause : LucideIcons.play,
                  color: txtColor, size: 20),
              const SizedBox(width: 12),
              Text("AUDIO_SIGNAL",
                  style: GoogleFonts.spaceMono(
                      color: txtColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      default:
        return Text(msg["content"],
            style: GoogleFonts.inter(
                color: txtColor, fontSize: 14.5, height: 1.4));
    }
  }

  Widget _buildTelegramInputBar() {
    bool hasText = _messageController.text.isNotEmpty;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark ? Colors.white10 : MuraColors.microBorder,
                width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
                icon: const Icon(LucideIcons.paperclip,
                    color: MuraColors.mute, size: 22),
                onPressed: _showAttachmentMenu),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : MuraColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark ? Colors.white10 : MuraColors.microBorder),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 1,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                      hintText: "SECURE_MESSAGE",
                      hintStyle: GoogleFonts.inter(
                          fontSize: 14, color: MuraColors.mute),
                      border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: !hasText
                  ? _toggleVoice
                  : () => _sendSignal(
                      content: _messageController.text, type: "text"),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.redAccent
                        : (isDark ? Colors.white : MuraColors.userBubble),
                    shape: BoxShape.circle),
                child: Icon(!hasText ? LucideIcons.mic : LucideIcons.arrowUp,
                    color: isDark ? Colors.black : Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassPanel(
        borderRadius: 32,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMenuAction(
                  LucideIcons.image, "GALLERY", () => _handleMedia("image")),
              _buildMenuAction(
                  LucideIcons.video, "VIDEO", () => _handleMedia("video")),
              _buildMenuAction(
                  LucideIcons.camera, "CAMERA", () => _handleMedia("camera")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuAction(IconData icon, String label, VoidCallback onTap) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isDark
                ? Colors.white10
                : MuraColors.textPrimary.withOpacity(0.05),
            child: Icon(icon,
                color: isDark ? Colors.white : MuraColors.textPrimary,
                size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.spaceMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : MuraColors.textPrimary)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMuraAppBar() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : MuraColors.background,
      elevation: 0,
      leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: isDark ? Colors.white : MuraColors.textPrimary),
          onPressed: () => Navigator.pop(context)),
      title: Column(
        children: [
          Text(widget.username.toUpperCase(),
              style: GoogleFonts.spaceMono(
                  fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text("ENCRYPTED_SIGNAL",
              style:
                  GoogleFonts.spaceMono(fontSize: 7, color: MuraColors.mute)),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildSystemLog(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
          child: Text(text,
              style:
                  GoogleFonts.spaceMono(color: MuraColors.mute, fontSize: 8))),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
