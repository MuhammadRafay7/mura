import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/colors.dart';
import '../../core/services/supabase_service.dart';
import 'glass_panel.dart';

class MuraNavDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const MuraNavDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final String myId = MuraSupabase.client.auth.currentUser?.id ?? '';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: GlassPanel(
          height: 72,
          width: 240,
          borderRadius: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 0. THE_CIRCUIT (Messages)
              _navIcon(
                icon: LucideIcons.messageSquare,
                index: 0,
                // CORRECTED: Filtering inside the stream parameter
                stream: MuraSupabase.client
                    .from('messages')
                    .stream(primaryKey: ['id']).map((list) => list
                        .where((m) =>
                            m['receiver_id'] == myId && m['is_read'] == false)
                        .toList()),
              ),

              // 1. THE_VAULT
              _navIcon(icon: LucideIcons.layers, index: 1),

              // 2. THE_IDENTITY (Friend Requests)
              _navIcon(
                icon: LucideIcons.user,
                index: 2,
                // CORRECTED: Filtering inside the stream parameter
                stream: MuraSupabase.client
                    .from('friendships')
                    .stream(primaryKey: ['id']).map((list) => list
                        .where((f) =>
                            f['receiver_id'] == myId &&
                            f['status'] == 'pending')
                        .toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon({
    required IconData icon,
    required int index,
    Stream<List<Map<String, dynamic>>>? stream,
  }) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          HapticFeedback.lightImpact();
          onTabSelected(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. The Active Tab LED (Top)
            Positioned(
              top: 12,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutExpo,
                width: isActive ? 4 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: MuraColors.userBubble,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: MuraColors.userBubble.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                  ],
                ),
              ),
            ),

            // 2. The Notification Dot (Bottom Right)
            if (stream != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  final bool hasNotification =
                      snapshot.hasData && snapshot.data!.isNotEmpty;

                  return Positioned(
                    bottom: 22,
                    right: 22,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 400),
                      scale: hasNotification ? 1.0 : 0.0,
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // 3. The Main Icon
            AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isActive ? 1.2 : 1.0,
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                color: isActive
                    ? MuraColors.textPrimary
                    : MuraColors.mute.withOpacity(0.4),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
