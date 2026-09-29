import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    if (profile != null) {
      _usernameController.text = profile.username;
      _displayNameController.text = profile.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final newUsername = _usernameController.text.trim();
    final newDisplayName = _displayNameController.text.trim();

    final success = await authProvider.updateProfile(
      username: newUsername != authProvider.profile?.username
          ? newUsername
          : null,
      displayName: newDisplayName.isNotEmpty ? newDisplayName : null,
    );

    setState(() {
      _isSaving = false;
      if (success) _isEditing = false;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Failed to save')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _usernameController.text = profile?.username ?? '';
                _displayNameController.text = profile?.displayName ?? '';
              },
            ),
            IconButton(
              icon: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(Icons.check, color: theme.colorScheme.primary),
              onPressed: _isSaving ? null : _saveProfile,
            ),
          ],
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar placeholder
                  CircleAvatar(
                    radius: 48,
                    backgroundColor:
                        theme.colorScheme.primary.withAlpha(30),
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Walkie ID card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'YOUR WALKIE ID',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(120),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                profile.displayWalkieId,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: profile.walkieId),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Walkie ID copied!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Profile fields
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROFILE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(120),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Username
                          _ProfileField(
                            label: 'Username',
                            controller: _usernameController,
                            isEditing: _isEditing,
                            icon: Icons.alternate_email,
                          ),
                          const SizedBox(height: 16),

                          // Display name
                          _ProfileField(
                            label: 'Display Name',
                            controller: _displayNameController,
                            isEditing: _isEditing,
                            icon: Icons.person_outline,
                            hint: 'Optional',
                          ),
                          const SizedBox(height: 16),

                          // Email (read-only)
                          _ReadOnlyField(
                            label: 'Email',
                            value: authProvider.email,
                            icon: Icons.email_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final IconData icon;
  final String? hint;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!isEditing) {
      return Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurface.withAlpha(150)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                controller.text.isNotEmpty ? controller.text : (hint ?? '—'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: controller.text.isNotEmpty
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withAlpha(80),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurface.withAlpha(150)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
