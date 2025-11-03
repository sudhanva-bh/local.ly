// lib/common/services/profile/profile_service.dart
import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/users/seller_model.dart';
// Product service imports are no longer needed
// import 'package:locally/common/services/products/retail_product_service.dart';
// import 'package:locally/common/services/products/wholesale_product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase;
  // Product service members are no longer needed
  // final WholesaleProductService _wholesaleService;
  // final RetailProductService _retailService;

  static const String _tableName = 'profiles';

  /// Constructor no longer requires product services
  ProfileService(this._supabase);

  /// CREATE — Create a new seller profile
  Future<Either<String, void>> createProfile(Seller seller) async {
    try {
      await _supabase.from(_tableName).insert(seller.toMap());
      return Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// READ (Single)
  Future<Either<String, Seller>> getProfile(String uid) async {
    try {
      final data = await _supabase
          .from(_tableName)
          .select()
          .eq('id', uid)
          .single();
      return Right(Seller.fromMap(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return Left('Profile not found.');
      }
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// UPDATE
  Future<Either<String, void>> updateProfile(Seller seller) async {
    try {
      await _supabase
          .from(_tableName)
          .update(seller.toMap())
          .eq('id', seller.uid);
      return Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
    // TODO: Update all locations of products
  }

  /// STREAM — Live updates to a user's profile
  Stream<Seller?> getProfileStream(String uid) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((rows) {
          if (rows.isEmpty) return null;
          return Seller.fromMap(rows.first);
        })
        .handleError((e) {
          print('Error in getProfileStream: $e');
          return null;
        });
  }

  /// DELETE — Calls the Supabase function to delete the auth user.
  /// The database's "ON DELETE CASCADE" rules will handle deleting
  /// the profile and all associated products.
  Future<Either<String, void>> deleteProfile(String sellerId) async {
    // The sellerId parameter isn't even used, as the SQL function
    // uses auth.uid() to get the currently authenticated user.
    try {
      // 'delete_current_user' is the name of the SQL function we created
      await _supabase.rpc('delete_current_user');
      await _supabase.auth.signOut();
      return Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
