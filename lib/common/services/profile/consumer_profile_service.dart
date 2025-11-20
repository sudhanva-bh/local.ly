// lib/common/services/profile/consumer_profile_service.dart
import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/users/consumer_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumerProfileService {
  final SupabaseClient _supabase;

  // Assuming Consumers and Sellers share the same 'profiles' table
  // but have different data structures handled by the Model.
  static const String _tableName = 'consumer_profiles';

  ConsumerProfileService(this._supabase);

  /// CREATE — Create a new consumer profile
  Future<Either<String, void>> createProfile(ConsumerModel consumer) async {
    try {
      await _supabase.from(_tableName).insert(consumer.toMap());
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// READ (Single)
  Future<Either<String, ConsumerModel>> getProfile(String uid) async {
    try {
      final data = await _supabase
          .from(_tableName)
          .select()
          .eq('id', uid)
          .single();
      return Right(ConsumerModel.fromMap(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const Left('ConsumerModel profile not found.');
      }
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// UPDATE
  Future<Either<String, void>> updateProfile(ConsumerModel consumer) async {
    try {
      await _supabase
          .from(_tableName)
          .update(consumer.toMap())
          .eq('id', consumer.uid);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// STREAM — Live updates to a consumer's profile
  Stream<ConsumerModel?> getProfileStream(String uid) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((rows) {
          if (rows.isEmpty) return null;
          return ConsumerModel.fromMap(rows.first);
        })
        .handleError((e) {
          // Use a logger in production
          print('Error in getProfileStream (ConsumerModel): $e');
          return null;
        });
  }

  /// DELETE — Calls the Supabase function to delete the auth user.
  Future<Either<String, void>> deleteProfile() async {
    try {
      // 'delete_current_user' RPC handles Auth + Profile deletion via Cascade
      await _supabase.rpc('delete_current_user');
      await _supabase.auth.signOut();
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }
}

extension ConsumerProfileLocation on ConsumerProfileService {
  /// Updates the current consumer's delivery location
  Future<Either<String, void>> updateLocation({
    required String uid,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final updates = {
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Optional: Update the text address if provided
      if (address != null) {
        updates['address'] = address;
      }

      await _supabase
          .from(ConsumerProfileService._tableName)
          .update(updates)
          .eq('id', uid);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
