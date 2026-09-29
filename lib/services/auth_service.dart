import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Current authenticated user (null if not signed in)
  User? get currentUser => _client.auth.currentUser;

  /// Whether the user is signed in
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;
}
