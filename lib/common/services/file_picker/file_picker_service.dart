import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this

class FilePickerService {
  // --- MODIFIED: Renamed and changed return type to List<File> ---
  Future<List<File>> pickImages() async {
    try {
      // --- REMOVED ALL PERMISSION_HANDLER and DEVICE_INFO LOGIC ---

      // --- MODIFIED: Added allowMultiple: true ---
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      // --- MODIFIED: Handle multiple files ---
      if (result != null && result.files.isNotEmpty) {
        // Convert all valid paths to File objects
        final files = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        if (files.isNotEmpty) {
          return files;
        } else {
          // This case might happen if files were selected but paths were null
          throw Exception("No valid files were selected.");
        }
      } else {
        // User cancelled the picker
        throw Exception("File selection cancelled.");
      }
    } on PlatformException catch (e) {
      // This will catch errors if permission is denied
      debugPrint("File picker platform error: $e");
      if (e.code == 'permission_denied') {
        throw Exception(
          "Permission permanently denied. Please go to settings.",
        );
      }
      throw Exception("An error occurred while picking the file.");
    } on Exception catch (e) {
      // This catches our "cancelled" exception
      debugPrint("File picker error: ${e.toString()}");
      rethrow;
    }
  }
}
