import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/contact_provider.dart';

class SearchUsersSheet extends StatefulWidget {
  const SearchUsersSheet({super.key});

  @override
  State<SearchUsersSheet> createState() => _SearchUsersSheetState();
}

class _SearchUsersSheetState extends State<SearchUsersSheet> {
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contactProvider = context.watch<ContactProvider>();

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

              // Title
              Text(
                'Add Contact',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by username or Walkie ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              contactProvider.clearSearch();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {}); // Rebuild for suffix icon
                    _debouncer.run(() {
                      contactProvider.searchUsers(value);
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Results
              Expanded(
                child: _buildResults(theme, contactProvider, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResults(
    ThemeData theme,
    ContactProvider contactProvider,
    ScrollController scrollController,
  ) {
    if (contactProvider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(60),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for users to add',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withAlpha(100),
              ),
            ),
          ],
        ),
      );
    }

    final results = contactProvider.searchResults;

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withAlpha(100),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final profile = results[index];
        final isAlreadyContact = contactProvider.isContact(profile.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withAlpha(30),
            child: Text(
              profile.name.isNotEmpty
                  ? profile.name[0].toUpperCase()
                  : '?',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          title: Text(
            profile.name,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '@${profile.username}  ·  ${profile.displayWalkieId}',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          trailing: isAlreadyContact
              ? Chip(
                  label: Text(
                    'Contact',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  backgroundColor:
                      theme.colorScheme.primary.withAlpha(20),
                  side: BorderSide.none,
                )
              : IconButton(
                  icon: Icon(
                    Icons.person_add_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () async {
                    final success =
                        await contactProvider.sendRequest(profile.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Request sent to @${profile.username}',
                          ),
                        ),
                      );
                    }
                  },
                ),
        );
      },
    );
  }
}

class _Debouncer {
  final int milliseconds;
  VoidCallback? _action;
  Future<void>? _timer;

  _Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _action = action;
    _timer?.ignore();
    _timer = Future.delayed(Duration(milliseconds: milliseconds), () {
      _action?.call();
    });
  }
}
