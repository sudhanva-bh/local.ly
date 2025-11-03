import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseImageService {
  final SupabaseClient _client = Supabase.instance.client;
  final String _bucketName =
      'product-images'; // ⚠️ Change if your bucket differs

  Future<String> uploadImage(File file, String productId) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final filePath = 'products/$productId/$fileName';

    try {
      final storage = _client.storage.from(_bucketName);

      // 🔹 Upload the file
      await storage.upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // Supabase returns '' for success — so we just check for exceptions
      final publicUrl = storage.getPublicUrl(filePath);
      return publicUrl;
    } on StorageException catch (e) {
      // If it's "Object not found" on upload, it's likely a misconfigured bucket path
      if (e.statusCode == '404' || e.message.contains('not_found')) {
        throw Exception(
          'Upload failed: bucket or path not found. Check bucket name: $_bucketName',
        );
      }
      throw Exception('Image upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Deletes an image using its full public URL.
  /// Silently ignores invalid or missing URLs.
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      final uri = Uri.tryParse(imageUrl);
      if (uri == null || !uri.hasAbsolutePath) return;

      final parts = uri.pathSegments;
      final index = parts.indexOf(_bucketName);
      if (index == -1 || index + 1 >= parts.length) {
        // 🧩 Not a valid Supabase image URL — ignore silently
        return;
      }

      final path = parts.sublist(index + 1).join('/');

      await _client.storage.from(_bucketName).remove([path]);
    } on StorageException catch (e) {
      // 🧩 Ignore "Object not found"
      if (e.statusCode == 404 || e.message.contains('not_found')) {
        return;
      }
      rethrow;
    } catch (e) {
      // 🧩 Swallow invalid URL or parsing errors
      // debugPrint('⚠️ Skipping invalid image URL: $imageUrl');
    }
  }
}
