import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the state of authentication
class AuthState {
  final bool loading;
  final String? errorMessage;
  final User? user;
  final bool showSignUp; // <-- ADD THIS

  const AuthState({
    this.loading = false,
    this.errorMessage,
    this.user,
    this.showSignUp = true, // <-- ADD THIS
  });

  AuthState copyWith({
    bool? loading,
    String? errorMessage,
    User? user,
    bool? showSignUp, // <-- ADD THIS
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      errorMessage: errorMessage, // Note: Don't preserve old error messages
      user: user ?? this.user,
      showSignUp: showSignUp ?? this.showSignUp, // <-- ADD THIS
    );
  }

  static const initial = AuthState();
}

/// The AuthController handles toggling between forms and submitting auth actions.
class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  // REMOVE the local _showSignUp variable

  AuthController(this._ref) : super(AuthState.initial);

  void toggleForm() {
    // Simply update the state
    state = state.copyWith(showSignUp: !state.showSignUp);
  }

  /// REGISTER NEW USER
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    // Clear previous errors
    state = state.copyWith(loading: true, errorMessage: null);

    final authService = _ref.read(authServiceProvider);
    final result = await authService.signUp(email: email, password: password);

    result.match(
      (l) => state = state.copyWith(loading: false, errorMessage: l),
      (user) => state = state.copyWith(loading: false, user: user),
    );
  }

  /// SIGN IN EXISTING USER
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, errorMessage: null);

    final authService = _ref.read(authServiceProvider);
    final result = await authService.signIn(email: email, password: password);

    result.match(
      (l) => state = state.copyWith(loading: false, errorMessage: l),
      (user) => state = state.copyWith(loading: false, user: user),
    );
  }

  /// SIGN OUT CURRENT USER
  Future<void> signOut() async {
    final authService = _ref.read(authServiceProvider);
    await authService.signOut();
    // Reset to initial state
    state = AuthState.initial.copyWith(showSignUp: state.showSignUp);
  }
}

/// Riverpod provider for AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});