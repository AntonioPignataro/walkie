import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import 'widgets/group_tile.dart';
import 'widgets/create_group_sheet.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupProvider = context.watch<GroupProvider>();

    return RefreshIndicator(
      onRefresh: () => groupProvider.loadGroups(),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Groups',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const Spacer(),
                  if (groupProvider.groups.isNotEmpty)
                    Text(
                      '${groupProvider.groups.length}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withAlpha(80),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Group list or empty state
          if (groupProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (groupProvider.groups.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_work_outlined,
                      size: 56,
                      color: theme.colorScheme.onSurface.withAlpha(50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No groups yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withAlpha(100),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create a group',
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
                    final group = groupProvider.groups[index];
                    return GroupTile(
                      group: group,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(group: group),
                          ),
                        );
                      },
                    );
                  },
                  childCount: groupProvider.groups.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

/// FAB for creating groups
class CreateGroupFAB extends StatelessWidget {
  const CreateGroupFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const CreateGroupSheet(),
        );
      },
      child: const Icon(Icons.group_add_outlined),
    );
  }
}
