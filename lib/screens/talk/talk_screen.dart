import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/connection_provider.dart';
import '../../models/peer_connection_state.dart';
import 'widgets/push_to_talk_button.dart';
import 'widgets/connection_status_indicator.dart';
import 'widgets/audio_visualizer.dart';

class TalkScreen extends StatelessWidget {
  final VoidCallback onNavigateToConnections;

  const TalkScreen({
    super.key,
    required this.onNavigateToConnections,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final state = connectionProvider.state;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Error banner
              if (state.status == PeerConnectionStatus.error &&
                  state.errorMessage != null)
                _ErrorBanner(
                  message: state.errorMessage!,
                  onDismiss: connectionProvider.clearError,
                ),

              // Connected-to header (shows what you're connected to)
              if (state.isConnected || state.isReconnecting)
                _ConnectedToHeader(state: state),

              // Participant list for group calls
              if (state.isGroup &&
                  (state.isConnected || state.isReconnecting))
                _ParticipantChips(state: state),

              const Spacer(flex: 2),

              // Audio visualizer (shows when talking)
              AudioVisualizer(
                isActive: connectionProvider.isTalking,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 24),

              // Push to talk button
              Expanded(
                flex: 6,
                child: Center(
                  child: PushToTalkButton(
                    isConnected: state.isConnected,
                    isTalking: connectionProvider.isTalking,
                    onTalkStart: connectionProvider.startTalking,
                    onTalkEnd: connectionProvider.stopTalking,
                    onTapDisconnected: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Connect to a contact or group first',
                          ),
                          action: SnackBarAction(
                            label: 'GO',
                            onPressed: onNavigateToConnections,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Connection status
              ConnectionStatusIndicator(connectionState: state),

              // Disconnect button
              if (state.isConnected ||
                  state.isConnecting ||
                  state.isReconnecting)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton.icon(
                    onPressed: () => connectionProvider.disconnect(),
                    icon: Icon(
                      Icons.link_off,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    label: Text(
                      'Disconnect',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),

              const Spacer(flex: 2),
            ],
          ),
        );
      },
    );
  }
}

/// Shows who/what you're connected to at the top.
class _ConnectedToHeader extends StatelessWidget {
  final PeerConnectionState state;

  const _ConnectedToHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.isGroup ? Icons.group : Icons.person,
            size: 18,
            color: theme.colorScheme.primary.withAlpha(180),
          ),
          const SizedBox(width: 8),
          Text(
            state.targetName ?? 'Unknown',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable chips showing participants (for group calls).
class _ParticipantChips extends StatelessWidget {
  final PeerConnectionState state;

  const _ParticipantChips({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participants = state.participants;

    if (participants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          'Waiting for others to join...',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withAlpha(80),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: participants.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = participants[index];
          return Chip(
            avatar: CircleAvatar(
              radius: 12,
              backgroundColor: p.isSpeaking
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withAlpha(30),
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: p.isSpeaking
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
              ),
            ),
            label: Text(
              p.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: p.isSpeaking ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            backgroundColor: p.isSpeaking
                ? theme.colorScheme.primary.withAlpha(20)
                : null,
            side: p.isSpeaking
                ? BorderSide(color: theme.colorScheme.primary.withAlpha(80))
                : BorderSide.none,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          );
        },
      ),
    );
  }
}

/// Shows a dismissible error banner at the top of the talk screen.
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 18,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.error.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
