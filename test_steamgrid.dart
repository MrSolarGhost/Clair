import 'package:clair/services/steamgriddb_service.dart';
import 'package:http/http.dart' as http;

void main() async {
  final service = SteamGridDBService(
    client: http.Client(),
    apiKey: '5e447b768660a429d2721f56501064c0',
  );

  print('Searching for Sonic Adventure 2...');
  final results = await service.search('Sonic Adventure 2');
  print('Found ${results.length} results:');
  for (var game in results) {
    print('  - ${game['name']} (ID: ${game['id']})');
  }

  if (results.isNotEmpty) {
    final gameId = results.first['id'];
    print('\nFetching covers for game ID $gameId...');
    final covers = await service.getCovers(gameId);
    print('Found ${covers.length} covers');
    
    if (covers.isNotEmpty) {
      print('\nTop 3 covers:');
      for (var i = 0; i < 3 && i < covers.length; i++) {
        print('  ${i + 1}. ${covers[i]['url']} (score: ${covers[i]['score']})');
      }
    }
  }

  print('\nTesting quickFetch...');
  final coverUrl = await service.quickFetch('Sonic Adventure 2');
  print('Best cover: $coverUrl');
}
