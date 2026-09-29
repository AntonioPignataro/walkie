import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connection_provider.dart';
import '../profile/profile_screen.dart';
import 'widgets/theme_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final connectionProvider = context.watch<ConnectionProvider>();
    final connState = connectionProvider.state;
    final profile = authProvider.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Active connection card
          if (connState.isConnected || connState.isReconnecting)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Card(
                color: theme.colorScheme.primary.withAlpha(15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: connState.isReconnecting
                              ? Colors.amber
                              : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connState.isReconnecting
                                  ? 'Reconnecting...'
                                  : 'Connected',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${connState.isGroup ? 'Group: ' : ''}${connState.targetName ?? 'Unknown'}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => connectionProvider.disconnect(),
                        child: Text(
                          'Disconnect',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Account section (now enabled!)
          _SettingsSection(
            title: 'ACCOUNT',
            children: [
              _SettingsItem(
                icon: Icons.person_outline,
                title: profile?.name ?? 'Profile',
                subtitle: profile != null
                    ? '@${profile.username}'
                    : 'View your profile',
                enabled: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: authProvider.email,
                enabled: true,
                isDestructive: true,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text(
                        'Are you sure you want to sign out?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Sign Out',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    // Full shutdown — disconnects call + stops services
                    await connectionProvider.shutdown();
                    await authProvider.signOut();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          const ThemeSelector(),

          const SizedBox(height: 20),

          // Audio
          _SettingsSection(
            title: 'AUDIO',
            children: [
              _SettingsItem(
                icon: Icons.volume_up,
                title: 'Speaker output',
                subtitle: 'Audio routes to speaker automatically',
                enabled: false,
                onTap: null,
              ),
              _SettingsItem(
                icon: Icons.mic,
                title: 'Noise suppression',
                subtitle: 'Enabled (echo cancellation + auto gain)',
                enabled: false,
                onTap: null,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // About
          _SettingsSection(
            title: 'ABOUT',
            children: [
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'Walkie',
                subtitle: 'Version 2.0.0',
                enabled: true,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Walkie',
                    applicationVersion: '2.0.0',
                    applicationLegalese:
                        'A walkie-talkie experience for everyone.',
                    applicationIcon: Icon(
                      Icons.cell_tower,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: textColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              ),
              if (!enabled)
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(60),
                ),
              if (enabled && !isDestructive)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurface.withAlpha(80),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
