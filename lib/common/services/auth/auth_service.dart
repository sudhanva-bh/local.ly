import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// SIGN UP
  Future<Either<String, User>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        return Right(res.user!);
      } else {
        return Left('Sign up failed');
      }
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// SIGN IN
  Future<Either<String, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        return Right(res.user!);
      } else {
        return Left('Sign in failed');
      }
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// SIGN OUT
  Future<Either<String, void>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return Right(null);
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// GET CURRENT USER
  Either<String, User> getCurrentUser() {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        return Right(user);
      } else {
        return Left('No user logged in');
      }
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// LISTEN TO AUTH STATE CHANGES
  Stream<AuthChangeEvent> authStateChanges() {
    return _supabase.auth.onAuthStateChange.map((data) => data.event);
  }
}
