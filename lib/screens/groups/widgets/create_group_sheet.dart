import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/contact_provider.dart';

class CreateGroupSheet extends StatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final Set<String> _selectedContactIds = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    final groupProvider = context.read<GroupProvider>();
    final group = await groupProvider.createGroup(
      name: name,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
    );

    if (group != null && _selectedContactIds.isNotEmpty) {
      for (final contactId in _selectedContactIds) {
        await groupProvider.addMember(group.id, contactId);
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contacts = context.watch<ContactProvider>().contacts;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
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
                'Create Group',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // Group name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Group name',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),

              // Description (optional)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Add members
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add contacts to group',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Contact list
              Expanded(
                child: contacts.isEmpty
                    ? Center(
                        child: Text(
                          'No contacts to add',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withAlpha(80),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          final isSelected = _selectedContactIds
                              .contains(contact.profile.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedContactIds.add(contact.profile.id);
                                } else {
                                  _selectedContactIds
                                      .remove(contact.profile.id);
                                }
                              });
                            },
                            title: Text(
                              contact.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '@${contact.profile.username}',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            secondary: CircleAvatar(
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
                          );
                        },
                      ),
              ),

              // Create button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _nameController.text.trim().isEmpty || _isCreating
                        ? null
                        : _createGroup,
                    child: _isCreating
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Create Group'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
