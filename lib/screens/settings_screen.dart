import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';
import '../services/cover_fetch_queue.dart';
import '../services/steamgriddb_service.dart';
import '../services/cover_storage_service.dart';
import 'library_directories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _retroarchPathController = TextEditingController();
  final _retroarchCoresPathController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  int _totalGames = 0;
  int _gamesWithCovers = 0;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadStats();
  }

  Future<void> _loadApiKey() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final envFile = File('${dir.path}/.env');
      
      if (envFile.existsSync()) {
        final contents = await envFile.readAsString();
        final lines = contents.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('STEAMGRIDDB_API_KEY=')) {
            _apiKeyController.text = line.substring(20);
          } else if (line.startsWith('RETROARCH_PATH=')) {
            _retroarchPathController.text = line.substring(15);
          } else if (line.startsWith('RETROARCH_CORES_PATH=')) {
            _retroarchCoresPathController.text = line.substring(21);
          }
        }
      }
    } catch (e) {
      print('Error loading API key: $e');
    }
  }

  Future<void> _saveApiKey() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final envFile = File('${dir.path}/.env');
      
      final key = _apiKeyController.text.trim();
      if (key.isEmpty) {
        setState(() {
          _statusMessage = 'API key cannot be empty';
          _isLoading = false;
        });
        return;
      }

      // Read existing .env or create new
      final lines = <String>[];
      if (envFile.existsSync()) {
        final contents = await envFile.readAsString();
        lines.addAll(contents.split('\n'));
      }

      // Update or add API key line
      bool foundKey = false;
      bool foundRetroarch = false;
      bool foundRetroarchCores = false;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('STEAMGRIDDB_API_KEY=')) {
          lines[i] = 'STEAMGRIDDB_API_KEY=$key';
          foundKey = true;
        } else if (lines[i].startsWith('RETROARCH_PATH=')) {
          lines[i] = 'RETROARCH_PATH=${_retroarchPathController.text.trim()}';
          foundRetroarch = true;
        } else if (lines[i].startsWith('RETROARCH_CORES_PATH=')) {
          lines[i] = 'RETROARCH_CORES_PATH=${_retroarchCoresPathController.text.trim()}';
          foundRetroarchCores = true;
        }
      }

      if (!foundKey) {
        lines.add('STEAMGRIDDB_API_KEY=$key');
      }
      if (!foundRetroarch) {
        lines.add('RETROARCH_PATH=${_retroarchPathController.text.trim()}');
      }
      if (!foundRetroarchCores) {
        lines.add('RETROARCH_CORES_PATH=${_retroarchCoresPathController.text.trim()}');
      }

      // Write back to file
      await envFile.writeAsString(lines.join('\n'));

      setState(() {
        _statusMessage = 'API key saved successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving API key: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    final dbService = DatabaseService.instance;
    final allGames = await dbService.getAllGames();
    final withCovers = allGames.where((g) => g.coverPath != null && g.coverPath!.isNotEmpty).length;
    
    setState(() {
      _totalGames = allGames.length;
      _gamesWithCovers = withCovers;
    });
  }

  Future<void> _fetchAllCovers() async {
    setState(() => _isFetching = true);
    
    try {
      final dbService = DatabaseService.instance;
      final db = await dbService.database;
      final queue = CoverFetchQueue(
        db: db,
        steamGridDB: SteamGridDBService(
          apiKey: dotenv.env['STEAMGRIDDB_API_KEY'] ?? '',
          timeout: const Duration(seconds: 3),
        ),
        storage: CoverStorageService(),
        gameService: dbService,
      );
      
      final gamesWithoutCovers = await dbService.getGamesWithoutCovers();
      
      for (final game in gamesWithoutCovers) {
        await queue.add(gameId: game.id!);
      }
      
      await queue.processQueue();
      await _loadStats();
      
      setState(() {
        _statusMessage = 'Fetched covers for ${gamesWithoutCovers.length} games';
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error fetching covers: $e';
        _isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SteamGridDB API Key',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter your API key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get your API key from: https://www.steamgriddb.com/profile/preferences/api',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveApiKey,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save API Key'),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('Error')
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'RetroArch Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _retroarchPathController,
              decoration: const InputDecoration(
                hintText: 'RetroArch executable path',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _retroarchCoresPathController,
              decoration: const InputDecoration(
                hintText: 'RetroArch cores path',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cover Art',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('$_gamesWithCovers/$_totalGames games have covers'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isFetching ? null : _fetchAllCovers,
              child: _isFetching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Get Game Covers'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Library Directories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Automatically import games from your ROM and game directories',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LibraryDirectoriesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Manage Directories'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
