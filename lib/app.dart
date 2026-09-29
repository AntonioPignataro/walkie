import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/contact_provider.dart';
import 'theme/walkie_theme.dart';
import 'widgets/walkie_scaffold.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/call/incoming_connection_sheet.dart';
import 'services/call_notification_service.dart';

class WalkieApp extends StatelessWidget {
  const WalkieApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Walkie',
      debugShowCheckedModeBanner: false,
      theme: WalkieTheme.light(),
      darkTheme: WalkieTheme.dark(),
      themeMode: themeProvider.themeMode,
      home: authProvider.isLoading
          ? const _SplashScreen()
          : authProvider.isAuthenticated
              ? const _AuthenticatedApp()
              : const AuthScreen(),
    );
  }
}

/// Wrapper that initializes connection services after authentication
/// and listens for incoming connection requests.
///
/// Uses [WidgetsBindingObserver] to handle app lifecycle transitions
/// without killing the audio connection.
class _AuthenticatedApp extends StatefulWidget {
  const _AuthenticatedApp();

  @override
  State<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<_AuthenticatedApp>
    with WidgetsBindingObserver {
  bool _initialized = false;
  bool _isShowingIncomingSheet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeServices();
      _initialized = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[App] Lifecycle state: $state');

    // We do NOT disconnect on paused/detached/hidden.
    // The foreground service keeps LiveKit alive in the background.
    // When the user comes back, we just need to make sure the UI
    // is in sync with the connection state.
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground — UI is alive again
      debugPrint('[App] Resumed — UI is active');
    }
  }

  Future<void> _initializeServices() async {
    final authProvider = context.read<AuthProvider>();
    final connectionProvider = context.read<ConnectionProvider>();
    final contactProvider = context.read<ContactProvider>();

    if (authProvider.profile != null) {
      // Initialize connection service with current profile
      if (!connectionProvider.isInitialized) {
        await connectionProvider.initialize(authProvider.profile!);

        // Listen for incoming connection requests
        if (mounted) {
          connectionProvider.addListener(_checkIncoming);
        }
      }

      // Start presence tracking (online/offline)
      contactProvider.presenceService.join(authProvider.profile!.id);
      contactProvider.startPresenceListening();
    }
  }

  void _checkIncoming() {
    final connectionProvider = context.read<ConnectionProvider>();
    final pending = connectionProvider.pendingIncoming;

    // Only show if there's a pending request AND we're not already showing one
    if (pending != null && !_isShowingIncomingSheet) {
      // Consume the pending request immediately so it won't re-trigger
      connectionProvider.consumePendingIncoming();
      _showIncomingSheet(pending);
    }
  }

  void _showIncomingSheet(IncomingConnectionRequest request) {
    if (!mounted) return;

    _isShowingIncomingSheet = true;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => IncomingConnectionSheet(request: request),
    ).whenComplete(() {
      _isShowingIncomingSheet = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leave presence channel on sign out
    try {
      context.read<ContactProvider>().presenceService.leave();
      context.read<ConnectionProvider>().removeListener(_checkIncoming);
    } catch (_) {}
    // Do NOT call connectionProvider.shutdown() here.
    // The foreground service + LiveKit keep running in background.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const WalkieScaffold();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cell_tower,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
