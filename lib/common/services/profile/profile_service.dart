// lib/common/services/profile/profile_service.dart
import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/services/products/retail_product_service.dart';
import 'package:locally/common/services/products/wholesale_product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase;
  final WholesaleProductService _wholesaleService;
  final RetailProductService _retailService;

  static const String _tableName = 'profiles';

  ProfileService(
    this._supabase, {
    required WholesaleProductService wholesaleService,
    required RetailProductService retailService,
  }) : _wholesaleService = wholesaleService,
       _retailService = retailService;

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

  /// DELETE — Deletes the profile and all associated products
  Future<Either<String, void>> deleteProfile(String sellerId) async {
    try {
      final profileData = await _supabase
          .from(_tableName)
          .select('seller_type')
          .eq('id', sellerId)
          .maybeSingle();

      if (profileData == null) {
        return Left('Profile not found');
      }

      final sellerType = profileData['seller_type'] as String?;

      if (sellerType == 'wholesaleSeller') {
        await _wholesaleService.deleteProductsBySeller(sellerId);
      } else if (sellerType == 'retailSeller') {
        await _retailService.deleteProductsBySeller(sellerId);
      }

      await _supabase.from(_tableName).delete().eq('id', sellerId);
      return Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
