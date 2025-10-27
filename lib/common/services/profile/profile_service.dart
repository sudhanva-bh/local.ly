import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase;
  // Assumes your table is named 'profiles'
  static const String _tableName = 'profiles';

  ProfileService(this._supabase);

  /// CREATE
  /// Creates a new seller profile. This is usually called right after sign-up.
  Future<Either<String, void>> createProfile(Seller seller) async {
    try {
      // The Seller.toMap() function converts the model to a Supabase-friendly map
      await _supabase.from(_tableName).insert(seller.toMap());
      return Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// READ (Single)
  /// Fetches a single seller profile by their UID.
  Future<Either<String, Seller>> getProfile(String uid) async {
    try {
      final data = await _supabase
          .from(_tableName)
          .select()
          .eq('id', uid)
          .single(); // .single() ensures we get exactly one row or it throws

      return Right(Seller.fromMap(data));
    } on PostgrestException catch (e) {
      // Handle cases like "0 rows" or "multiple rows"
      if (e.code == 'PGRST116') {
        return Left('Profile not found.');
      }
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// UPDATE
  /// Updates an existing seller profile.
  Future<Either<String, void>> updateProfile(Seller seller) async {
    try {
      await _supabase
          .from(_tableName)
          .update(seller.toMap())
          .eq('id', seller.uid); // Match the user's ID
      return Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// READ (Stream)
  /// Listens to real-time changes for a *specific* seller profile.
  /// This is the stream you requested.
  Stream<Seller?> getProfileStream(String uid) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id']) // The primary key of your table
        .eq('id', uid)
        .map((maps) {
          // The stream returns a List<Map<String, dynamic>>
          if (maps.isEmpty) {
            // User exists, but has no profile row yet, or it was deleted
            return null;
          }
          // Profile exists, map it to a Seller object
          return Seller.fromMap(maps.first);
        })
        .handleError((e) {
          // Handle any potential stream errors
          print('Error in getProfileStream: $e');
          // You could return null or re-throw
          return null;
        });
  }
}