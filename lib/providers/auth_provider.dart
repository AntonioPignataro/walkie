import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final DatabaseService _databaseService;

  Profile? _profile;
  Profile? get profile => _profile;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _error;
  String? get error => _error;

  /// Current user's email
  String get email => _authService.currentUser?.email ?? '';

  StreamSubscription<AuthState>? _authSubscription;

  AuthProvider({
    AuthService? authService,
    DatabaseService? databaseService,
  })  : _authService = authService ?? AuthService(),
        _databaseService = databaseService ?? DatabaseService() {
    _init();
  }

  void _init() {
    // Check initial auth state
    _isAuthenticated = _authService.isAuthenticated;
    if (_isAuthenticated) {
      _loadProfile();
    } else {
      _isLoading = false;
      notifyListeners();
    }

    // Listen for auth changes
    _authSubscription = _authService.onAuthStateChange.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        _isAuthenticated = true;
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _isAuthenticated = false;
        _profile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await _databaseService.getMyProfile();
    } catch (e) {
      _error = 'Failed to load profile: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        _isAuthenticated = true;
        await _loadProfile();
        return true;
      } else {
        _error = 'Sign up failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _parseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        _isAuthenticated = true;
        await _loadProfile();
        return true;
      } else {
        _error = 'Sign in failed. Please check your credentials.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _parseAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _isAuthenticated = false;
      _profile = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  /// Update profile
  Future<bool> updateProfile({
    String? username,
    String? displayName,
  }) async {
    _error = null;
    try {
      _profile = await _databaseService.updateProfile(
        username: username,
        displayName: displayName,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  /// Reload profile from database
  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseAuthError(dynamic error) {
    final message = error.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('Password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (message.contains('Unable to validate email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('Email rate limit exceeded')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
