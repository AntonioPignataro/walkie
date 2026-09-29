import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../providers/group_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/connection_provider.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contacts = context.watch<ContactProvider>().contacts;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group.name,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'leave') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Leave Group'),
                    content: Text(
                      'Are you sure you want to leave "${group.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Leave',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<GroupProvider>().leaveGroup(group.id);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text('Leave Group', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Connect / Disconnect button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Consumer<ConnectionProvider>(
              builder: (context, connectionProvider, _) {
                final connState = connectionProvider.state;
                final isConnectedHere = connState.isConnected &&
                    connState.isGroup &&
                    connState.targetId == group.id;
                final isConnecting = connState.isConnecting &&
                    connState.isGroup &&
                    connState.targetId == group.id;

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: isConnectedHere
                      ? OutlinedButton.icon(
                          onPressed: () =>
                              connectionProvider.disconnect(),
                          icon: const Icon(Icons.link_off),
                          label: const Text('Disconnect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(
                              color: theme.colorScheme.error.withAlpha(120),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: isConnecting
                              ? null
                              : () {
                                  connectionProvider.connectToGroup(
                                    groupId: group.id,
                                    groupName: group.name,
                                  );
                                },
                          icon: isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cell_tower),
                          label: Text(
                            isConnecting ? 'Connecting...' : 'Connect to Group',
                          ),
                        ),
                );
              },
            ),
          ),

          // Description
          if (group.description != null && group.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          group.description!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Members header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Members',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const Spacer(),
                Text(
                  '${group.members.length}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withAlpha(80),
                  ),
                ),
              ],
            ),
          ),

          // Members list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                final member = group.members[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        theme.colorScheme.primary.withAlpha(30),
                    child: Text(
                      member.profile.name.isNotEmpty
                          ? member.profile.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    member.profile.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '@${member.profile.username}',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (member.isConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Connected',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (member.isAdmin) ...[
                        if (member.isConnected) const SizedBox(width: 6),
                        Chip(
                          label: Text(
                            'Admin',
                            style: GoogleFonts.inter(fontSize: 11),
                          ),
                          backgroundColor:
                              theme.colorScheme.secondary.withAlpha(20),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Add member button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddMemberSheet(context, contacts),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add Contact to Group'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMemberSheet(BuildContext context, List contacts) {
    final theme = Theme.of(context);
    final memberIds = group.members.map((m) => m.profile.id).toSet();
    final availableContacts = contacts
        .where((c) => !memberIds.contains(c.profile.id))
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add to ${group.name}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (availableContacts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'All contacts are already in this group',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                ),
              )
            else
              ...availableContacts.map((contact) => ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          theme.colorScheme.primary.withAlpha(30),
                      child: Text(
                        contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(contact.displayName),
                    subtitle: Text('@${contact.profile.username}'),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.add,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () async {
                        await context
                            .read<GroupProvider>()
                            .addMember(group.id, contact.profile.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
