import 'package:flutter/material.dart';
import '../../../models/peer_connection_state.dart';
import '../../../theme/walkie_colors.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  final PeerConnectionState connectionState;

  const ConnectionStatusIndicator({
    super.key,
    required this.connectionState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(connectionState.status),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusDot(status: connectionState.status),
              const SizedBox(width: 8),
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _statusColor(theme),
                ),
              ),
            ],
          ),
          if (connectionState.targetName != null &&
              connectionState.isConnected) ...[
            const SizedBox(height: 4),
            Text(
              'Connected to ${connectionState.targetName}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
          if (connectionState.isGroup &&
              connectionState.isConnected &&
              connectionState.participants.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${connectionState.participants.length} participant${connectionState.participants.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withAlpha(80),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _statusText {
    switch (connectionState.status) {
      case PeerConnectionStatus.disconnected:
        return 'Disconnected';
      case PeerConnectionStatus.connecting:
        return 'Connecting...';
      case PeerConnectionStatus.connected:
        return 'Connected';
      case PeerConnectionStatus.ringing:
        return 'Incoming...';
      case PeerConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case PeerConnectionStatus.error:
        return connectionState.errorMessage ?? 'Connection error';
    }
  }

  Color _statusColor(ThemeData theme) {
    switch (connectionState.status) {
      case PeerConnectionStatus.disconnected:
        return WalkieColors.disconnectedGray;
      case PeerConnectionStatus.connecting:
      case PeerConnectionStatus.ringing:
      case PeerConnectionStatus.reconnecting:
        return WalkieColors.incomingCallCyan;
      case PeerConnectionStatus.connected:
        return theme.colorScheme.primary;
      case PeerConnectionStatus.error:
        return theme.colorScheme.error;
    }
  }
}

class _StatusDot extends StatefulWidget {
  final PeerConnectionStatus status;

  const _StatusDot({required this.status});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant _StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.status == PeerConnectionStatus.connecting ||
        widget.status == PeerConnectionStatus.ringing ||
        widget.status == PeerConnectionStatus.reconnecting) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _dotColor(theme);

    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Color _dotColor(ThemeData theme) {
    switch (widget.status) {
      case PeerConnectionStatus.disconnected:
        return WalkieColors.disconnectedGray;
      case PeerConnectionStatus.connecting:
      case PeerConnectionStatus.ringing:
      case PeerConnectionStatus.reconnecting:
        return WalkieColors.incomingCallCyan;
      case PeerConnectionStatus.connected:
        return theme.colorScheme.primary;
      case PeerConnectionStatus.error:
        return theme.colorScheme.error;
    }
  }
}
