import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/contact.dart';
import '../../../providers/connection_provider.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ContactTile({
    super.key,
    required this.contact,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      theme.colorScheme.primary.withAlpha(30),
                  child: Text(
                    contact.displayName.isNotEmpty
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                // Online status dot
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: contact.isOnline
                          ? const Color(0xFF00E676)
                          : const Color(0xFF4A5568),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // Name and username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${contact.profile.username}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
            ),

            // Connected badge OR Connect button
            Consumer<ConnectionProvider>(
              builder: (context, connProvider, _) {
                final connState = connProvider.state;
                final isConnectedToThis = connState.isConnected &&
                    connState.isDirect &&
                    connState.targetId == contact.profile.id;
                final isConnectingToThis = connState.isConnecting &&
                    connState.isDirect &&
                    connState.targetId == contact.profile.id;

                if (isConnectedToThis) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(60),
                      ),
                    ),
                    child: Text(
                      'Connected',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }

                if (isConnectingToThis) {
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                // Show connect button
                return IconButton(
                  onPressed: () {
                    connProvider.connectToContact(
                      contactId: contact.profile.id,
                      contactName: contact.displayName,
                    );
                  },
                  icon: Icon(
                    Icons.cell_tower,
                    color: theme.colorScheme.primary.withAlpha(160),
                    size: 22,
                  ),
                  tooltip: 'Connect',
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
