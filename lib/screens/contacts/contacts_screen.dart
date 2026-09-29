import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/call_record.dart';
import '../../providers/contact_provider.dart';
import '../../providers/connection_provider.dart';
import 'widgets/contact_tile.dart';
import 'widgets/contact_request_card.dart';
import 'widgets/search_users_sheet.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    // Load contacts on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactProvider>().loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contactProvider = context.watch<ContactProvider>();

    return RefreshIndicator(
      onRefresh: () => contactProvider.loadContacts(),
      child: CustomScrollView(
        slivers: [
          // Incoming requests section
          if (contactProvider.incomingRequests.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${contactProvider.incomingRequests.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Contact Requests',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final request = contactProvider.incomingRequests[index];
                    return ContactRequestCard(
                      request: request,
                      onAccept: () =>
                          contactProvider.acceptRequest(request),
                      onReject: () =>
                          contactProvider.rejectRequest(request),
                    );
                  },
                  childCount: contactProvider.incomingRequests.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 24, indent: 20, endIndent: 20),
            ),
          ],

          // Recent connections section
          if (contactProvider.callHistory.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Recent',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: contactProvider.callHistory.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final call = contactProvider.callHistory[index];
                    return _RecentCallChip(call: call);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 20, indent: 20, endIndent: 20),
            ),
          ],

          // Contacts header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Contacts',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const Spacer(),
                  if (contactProvider.contacts.isNotEmpty)
                    Text(
                      '${contactProvider.contacts.length}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withAlpha(80),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Contact list or empty state
          if (contactProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (contactProvider.contacts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 56,
                      color: theme.colorScheme.onSurface.withAlpha(50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No contacts yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withAlpha(100),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to search and add people',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withAlpha(70),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final contact = contactProvider.contacts[index];
                    return ContactTile(
                      contact: contact,
                      onTap: () {
                        // Connect to this contact
                        context.read<ConnectionProvider>().connectToContact(
                          contactId: contact.profile.id,
                          contactName: contact.displayName,
                        );
                      },
                      onLongPress: () {
                        _showContactOptions(context, contact);
                      },
                    );
                  },
                  childCount: contactProvider.contacts.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context, dynamic contact) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: theme.colorScheme.error),
              title: Text(
                'Remove Contact',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                final contactProvider = context.read<ContactProvider>();
                await contactProvider.removeContact(contact);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// FloatingActionButton for adding contacts — used from WalkieScaffold
class AddContactFAB extends StatelessWidget {
  const AddContactFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const SearchUsersSheet(),
        );
      },
      child: const Icon(Icons.person_add_outlined),
    );
  }
}

/// A compact chip for the horizontal recent connections list.
class _RecentCallChip extends StatelessWidget {
  final CallRecord call;

  const _RecentCallChip({required this.call});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = call.isGroup;

    return GestureDetector(
      onTap: () {
        final connProvider = context.read<ConnectionProvider>();
        if (isGroup && call.groupId != null) {
          connProvider.connectToGroup(
            groupId: call.groupId!,
            groupName: call.groupName ?? 'Group',
          );
        } else if (call.peerId != null) {
          connProvider.connectToContact(
            contactId: call.peerId!,
            contactName: call.displayName,
          );
        }
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isGroup
                  ? theme.colorScheme.secondary.withAlpha(30)
                  : theme.colorScheme.primary.withAlpha(30),
              child: Icon(
                isGroup ? Icons.group : Icons.person,
                size: 20,
                color: isGroup
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              call.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
