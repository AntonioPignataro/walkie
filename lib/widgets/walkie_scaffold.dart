import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/talk/talk_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/settings/settings_screen.dart';

class WalkieScaffold extends StatefulWidget {
  const WalkieScaffold({super.key});

  @override
  State<WalkieScaffold> createState() => _WalkieScaffoldState();
}

class _WalkieScaffoldState extends State<WalkieScaffold> {
  int _currentIndex = 0;

  void _navigateToContacts() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Walkie',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.colorScheme.primary.withAlpha(60),
                  theme.colorScheme.primary.withAlpha(100),
                  theme.colorScheme.primary.withAlpha(60),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildScreen(),
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return TalkScreen(
          key: const ValueKey('talk'),
          onNavigateToConnections: _navigateToContacts,
        );
      case 1:
        return const ContactsScreen(key: ValueKey('contacts'));
      case 2:
        return const GroupsScreen(key: ValueKey('groups'));
      case 3:
        return const SettingsScreen(key: ValueKey('settings'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget? _buildFAB() {
    switch (_currentIndex) {
      case 1:
        return const AddContactFAB();
      case 2:
        return const CreateGroupFAB();
      default:
        return null;
    }
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withAlpha(40),
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        height: 70,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.cell_tower_outlined),
            selectedIcon: Icon(Icons.cell_tower),
            label: 'Talk',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_work_outlined),
            selectedIcon: Icon(Icons.group_work),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
