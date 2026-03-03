import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CoverStorageService {
  final http.Client client;

  CoverStorageService({http.Client? client})
      : client = client ?? http.Client();

  /// Download cover from URL and save to app documents directory
  /// Returns file path on success, null on failure
  Future<String?> downloadCover(String url, {required int gameId}) async {
    try {
      // Download image
      final response = await client.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return null;
      }

      // Get app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final coversDir = Directory(path.join(dir.path, 'covers'));
      
      // Create covers directory if it doesn't exist
      if (!coversDir.existsSync()) {
        coversDir.createSync(recursive: true);
      }

      // Generate filename (game ID + timestamp to allow updates)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'game_${gameId}_$timestamp.jpg';
      final filePath = path.join(coversDir.path, filename);

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } catch (e) {
      print('Failed to download cover: $e');
      return null;
    }
  }

  /// Delete cover file
  Future<void> deleteCover(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      print('Failed to delete cover: $e');
    }
  }
}
