// lib/common/services/supabase_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Call a Supabase Edge Function and parse returned list into T
  Future<List<T>> invokeFunction<T>({
    required String functionName,
    Map<String, dynamic>? params,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      // Use the Functions API (invoke returns a response wrapper)
      final response = await _client.functions.invoke(
        functionName,
        body: params ?? {},
      );

      // response.data should contain parsed JSON. It can be a List or Map.
      final data = response.data;

      if (data is List) {
        return data.map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
      }

      // if it's a map with a key -> maybe it returned { items: [...] }
      if (data is Map && data.values.isNotEmpty) {
        // try to extract first list found
        final firstList = data.values.firstWhere(
          (v) => v is List,
          orElse: () => null,
        );
        if (firstList is List) {
          return firstList.map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }

      return [];
    } catch (e, st) {
      debugPrint('Supabase function error ($functionName): $e\n$st');
      rethrow;
    }
  }

  /// Fetch full table rows (generic)
  Future<List<T>> fetchFromTable<T>({
    required String tableName,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final data = await _client.from(tableName).select();
      if (data is List) {
        return data.map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Supabase table fetch error ($tableName): $e');
      rethrow;
    }
  }
}
