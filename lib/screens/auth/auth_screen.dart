import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Wrapper that manages switching between login and register screens.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _showLogin
          ? LoginScreen(
              key: const ValueKey('login'),
              onSwitchToRegister: () => setState(() => _showLogin = false),
            )
          : RegisterScreen(
              key: const ValueKey('register'),
              onSwitchToLogin: () => setState(() => _showLogin = true),
            ),
    );
  }
}
