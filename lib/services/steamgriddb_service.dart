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
}
