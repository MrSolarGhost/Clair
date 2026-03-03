import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SteamGridDBService {
  final http.Client client;
  final String apiKey;
  final Duration timeout;

  static const String baseUrl = 'https://www.steamgriddb.com/api/v2';

  SteamGridDBService({
    http.Client? client,
    required this.apiKey,
    this.timeout = const Duration(seconds: 10),
  }) : client = client ?? http.Client();

  /// Search for games by title
  Future<List<Map<String, dynamic>>> search(String query) async {
    final uri = Uri.parse('$baseUrl/search/autocomplete/$query');
    final response = await client
        .get(
          uri,
          headers: {'Authorization': 'Bearer $apiKey'},
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to search: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['success'] != true) {
      throw Exception('API returned error');
    }

    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }

  /// Get cover art for a game
  /// Returns covers sorted by score (best first)
  Future<List<Map<String, dynamic>>> getCovers(int gameId) async {
    final uri = Uri.parse('$baseUrl/grids/game/$gameId').replace(
      queryParameters: {'dimensions': '600x900'},
    );

    final response = await client
        .get(
          uri,
          headers: {'Authorization': 'Bearer $apiKey'},
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to get covers: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['success'] != true) {
      throw Exception('API returned error');
    }

    final covers = List<Map<String, dynamic>>.from(data['data'] ?? []);
    
    // Sort by score (highest first)
    covers.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    
    return covers;
  }

  /// Quick fetch: search + get best cover with short timeout
  /// Returns null if timeout or no results
  Future<String?> quickFetch(String gameName, {String? platform}) async {
    try {
      // Search for game
      final searchResults = await search(gameName);
      if (searchResults.isEmpty) {
        return null;
      }

      // Get covers for first result (best match)
      final gameId = searchResults.first['id'] as int;
      final covers = await getCovers(gameId);
      
      if (covers.isEmpty) {
        return null;
      }

      // Return best cover (already sorted by score)
      return covers.first['url'] as String?;
    } on TimeoutException {
      return null;
    } catch (e) {
      // Log error but don't throw - graceful failure
      print('QuickFetch failed: $e');
      return null;
    }
  }
}
