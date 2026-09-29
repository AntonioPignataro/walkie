import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/contact_request.dart';

class ContactRequestCard extends StatelessWidget {
  final ContactRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ContactRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = request.fromProfile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.secondary.withAlpha(30),
              child: Text(
                from.name.isNotEmpty ? from.name[0].toUpperCase() : '?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    from.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '@${from.username}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            IconButton(
              onPressed: onReject,
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.error,
                size: 22,
              ),
              tooltip: 'Decline',
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onAccept,
              icon: Icon(
                Icons.check,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              tooltip: 'Accept',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withAlpha(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
