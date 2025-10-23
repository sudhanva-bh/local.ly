import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/services/auth/auth_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provide SupabaseClient (already initialized)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provide AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = Supabase.instance.client;

  return supabase.auth.onAuthStateChange
      .map((data) => data.session?.user)
      .startWith(supabase.auth.currentUser);
});
