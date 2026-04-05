import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/colors.dart';
import '../../shared/widgets/glass_panel.dart';
import '../settings/settings_registry.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _hasActiveStory = true;
  String? _profileImageUrl;
  String _userId = "NOT_ASSIGNED";

  late AnimationController _storyRotationController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _storyRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _statusController.dispose();
    _storyRotationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _userId = user.id);

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted && data != null) {
        setState(() {
          _nameController.text = data['username'] ?? "";
          _regionController.text = data['region'] ?? "LOCAL_NODE";
          _statusController.text = data['status_text'] ?? "USER_ACTIVE";
          _profileImageUrl = data['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint("ARCHIVE_FETCH_ERROR: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final fileName = 'avatar_${_userId}.jpg';
      final bytes = await image.readAsBytes();

      await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      final String publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(fileName);
      final String cacheBustUrl =
          "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      setState(() {
        _profileImageUrl = cacheBustUrl;
        _isLoading = false;
      });
      _showStatusSnackBar("ASSET_UPLOAD_SUCCESSFUL");
    } catch (e) {
      setState(() => _isLoading = false);
      _showStatusSnackBar("UPLOAD_ERROR: ${e.toString().toUpperCase()}",
          isError: true);
    }
  }

  Future<void> _handleCommit() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _isLoading) return;

    final cleanUsername = _nameController.text.trim().toUpperCase();

    if (cleanUsername.isEmpty) {
      _showStatusSnackBar("VALIDATION_ERROR: NAME_REQUIRED", isError: true);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'username': cleanUsername,
        'region': _regionController.text.trim().toUpperCase(),
        'status_text': _statusController.text.trim().toUpperCase(),
        'avatar_url': _profileImageUrl,
      });

      await _supabase.from('nodes').upsert({
        'id': user.id,
        'name': '@$cleanUsername',
        'status': _statusController.text.trim().toUpperCase(),
        'avatar_url': _profileImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        _showStatusSnackBar("ARCHIVE_SYNC_SUCCESSFUL");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showStatusSnackBar("SYNC_FAILURE: ${e.toString().toUpperCase()}",
            isError: true);
      }
    }
  }

  void _showStatusSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent : MuraColors.userBubble,
        behavior: SnackBarBehavior.floating,
        content: Text(message,
            style: GoogleFonts.spaceMono(
                fontSize: 10, color: isError ? Colors.white : Colors.black)),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "M";
    String cleanName = name.startsWith('@') ? name.substring(1) : name;
    if (cleanName.isEmpty) return "M";
    return cleanName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildTopBar(),
                    const SizedBox(height: 48),
                    _buildPassportCard(),
                    const SizedBox(height: 48),
                    _buildSettingsRegistrySection(),
                    const SizedBox(height: 40),
                    _buildActionFooter(),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MURA // ARCHIVE',
                style: GoogleFonts.spaceMono(
                    color: MuraColors.mute,
                    fontSize: 9,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('USER_PASSPORT_v2.5',
                style: GoogleFonts.spaceMono(
                    color: MuraColors.textPrimary,
                    fontSize: 8,
                    letterSpacing: 1)),
          ],
        ),
        _buildEditButton(),
      ],
    );
  }

  Widget _buildEditButton() {
    return InkWell(
      onTap: () {
        if (_isLoading) return;
        if (_isEditing) {
          _handleCommit();
        } else {
          HapticFeedback.lightImpact();
          setState(() => _isEditing = true);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isEditing ? MuraColors.textPrimary : Colors.transparent,
          border: Border.all(
            color: _isEditing ? MuraColors.textPrimary : MuraColors.microBorder,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: Colors.black))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isEditing ? LucideIcons.save : LucideIcons.edit3,
                      color: _isEditing ? Colors.black : MuraColors.textPrimary,
                      size: 14),
                  const SizedBox(width: 8),
                  Text(_isEditing ? "COMMIT" : "EDIT",
                      style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _isEditing
                              ? Colors.black
                              : MuraColors.textPrimary,
                          letterSpacing: 1)),
                ],
              ),
      ),
    );
  }

  Widget _buildPassportCard() {
    return GlassPanel(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          children: [
            _buildAvatarSystem(),
            const SizedBox(height: 40),
            _isEditing
                ? _buildEditField(_nameController, isLarge: true)
                : Text('@${_nameController.text.toUpperCase()}',
                    style: GoogleFonts.spaceMono(
                        fontSize: 18,
                        color: MuraColors.textPrimary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
                height: 0.5,
                width: 40,
                color: MuraColors.userBubble.withOpacity(0.5)),
            const SizedBox(height: 48),
            _detailRow('REGION', _regionController),
            _detailRow('STATUS', _statusController),
            _detailRow(
                'KEY_ID',
                TextEditingController(
                    text: _userId.length > 12
                        ? _userId.substring(0, 12).toUpperCase()
                        : _userId),
                enabled: false),
            const SizedBox(height: 40),
            _buildQrTrigger(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSystem() {
    return GestureDetector(
      onTap: _isEditing ? _pickProfileImage : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_hasActiveStory && !_isEditing)
            RotationTransition(
              turns: _storyRotationController,
              child: Container(
                width: 114,
                height: 114,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: MuraColors.userBubble.withOpacity(0.6),
                        width: 1.5)),
              ),
            ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
              border: Border.all(
                  color: MuraColors.microBorder.withOpacity(0.2), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: _profileImageUrl != null
                  ? Image.network(
                      _profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialsView(),
                    )
                  : _buildInitialsView(),
            ),
          ),
          if (_isEditing)
            Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)))
                    : const Icon(LucideIcons.camera,
                        color: Colors.white, size: 24)),
        ],
      ),
    );
  }

  Widget _buildInitialsView() {
    return Center(
      child: Text(_getInitials(_nameController.text),
          style: GoogleFonts.spaceMono(
              fontSize: 32,
              fontWeight: FontWeight.w200,
              color: MuraColors.textPrimary,
              letterSpacing: 4)),
    );
  }

  Widget _detailRow(String label, TextEditingController controller,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.spaceMono(
                  color: MuraColors.mute.withOpacity(0.5),
                  fontSize: 7,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Expanded(
            child: _isEditing && enabled
                ? _buildEditField(controller)
                : Text(controller.text.toUpperCase(),
                    textAlign: TextAlign.end,
                    style: GoogleFonts.spaceMono(
                        color: MuraColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller,
      {bool isLarge = false}) {
    return TextField(
      controller: controller,
      textAlign: isLarge ? TextAlign.center : TextAlign.end,
      cursorColor: MuraColors.userBubble,
      textCapitalization: TextCapitalization.characters,
      style: GoogleFonts.spaceMono(
          color: MuraColors.textPrimary,
          fontSize: isLarge ? 18 : 10,
          fontWeight: isLarge ? FontWeight.bold : FontWeight.w600),
      decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          enabledBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: MuraColors.microBorder, width: 0.5)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: MuraColors.userBubble, width: 1))),
    );
  }

  Widget _buildSettingsRegistrySection() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _isEditing ? 0.2 : 1.0,
      child: IgnorePointer(
          ignoring: _isEditing, child: const MuraSettingsRegistry()),
    );
  }

  Widget _buildActionFooter() {
    return Opacity(
      opacity: _isEditing ? 0.0 : 1.0,
      child: Column(
        children: [
          Text("AUTHENTICATED_SESSION",
              style: GoogleFonts.spaceMono(
                  fontSize: 7, color: MuraColors.mute, letterSpacing: 3)),
        ],
      ),
    );
  }

  Widget _buildQrTrigger() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(LucideIcons.qrCode,
            color: MuraColors.textPrimary.withOpacity(0.2), size: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("SIGNED_BY_MURA",
                style: GoogleFonts.spaceMono(
                    fontSize: 6, color: MuraColors.mute, letterSpacing: 1)),
            Text("SECURE_ENCLAVE_ACTIVE",
                style: GoogleFonts.spaceMono(
                    fontSize: 6,
                    color: MuraColors.userBubble,
                    letterSpacing: 1)),
          ],
        ),
      ],
    );
  }
}
