import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/connection_provider.dart';
import '../../services/call_notification_service.dart';

/// Bottom sheet shown when another user wants to connect.
class IncomingConnectionSheet extends StatelessWidget {
  final IncomingConnectionRequest request;

  const IncomingConnectionSheet({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = request.type == 'group';
    final displayName = isGroup
        ? (request.groupName ?? 'Group')
        : request.fromProfile.name;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha(40),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGroup ? Icons.group : Icons.cell_tower,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Incoming Connection',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            isGroup
                ? '${request.fromProfile.displayName} invited you to $displayName'
                : '$displayName wants to connect',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Username
          Text(
            '@${request.fromProfile.username}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ),
          const SizedBox(height: 28),

          // Action buttons
          Row(
            children: [
              // Decline
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<ConnectionProvider>().declineIncoming();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.colorScheme.error.withAlpha(120),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Accept
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ConnectionProvider>().acceptIncoming();
                      Navigator.pop(context);
                    },
                    child: const Text('Connect'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
