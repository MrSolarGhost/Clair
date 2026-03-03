import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game.dart';
import '../services/steamgriddb_service.dart';
import '../services/cover_storage_service.dart';
import '../services/database_service.dart';

class CoverPickerScreen extends StatefulWidget {
  final Game game;

  const CoverPickerScreen({super.key, required this.game});

  @override
  State<CoverPickerScreen> createState() => _CoverPickerScreenState();
}

class _CoverPickerScreenState extends State<CoverPickerScreen> {
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _covers = [];
  bool _isLoading = true;
  bool _showingCovers = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchGames();
  }

  Future<void> _searchGames() async {
    try {
      final service = SteamGridDBService(
        apiKey: dotenv.env['STEAMGRIDDB_API_KEY'] ?? '',
      );

      final results = await service.search(widget.game.title);
      if (results.isEmpty) {
        setState(() {
          _error = 'No results found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCovers(int gameId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = SteamGridDBService(
        apiKey: dotenv.env['STEAMGRIDDB_API_KEY'] ?? '',
      );

      final covers = await service.getCovers(gameId);
      setState(() {
        _covers = covers;
        _showingCovers = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCover(String coverUrl) async {
    final storage = CoverStorageService();
    final coverPath = await storage.downloadCover(
      coverUrl,
      gameId: widget.game.id!,
    );

    if (coverPath != null) {
      final dbService = DatabaseService.instance;
      await dbService.updateGame(
        widget.game.copyWith(coverPath: coverPath),
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showingCovers ? 'Choose Cover' : 'Select Game'),
        leading: _showingCovers
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showingCovers = false;
                    _covers = [];
                  });
                },
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _searchGames();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _showingCovers
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2 / 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _covers.length,
                      itemBuilder: (context, index) {
                        final cover = _covers[index];
                        return GestureDetector(
                          onTap: () => _selectCover(cover['url']),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              cover['url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.error));
                              },
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final game = _searchResults[index];
                        return Card(
                          child: ListTile(
                            title: Text(game['name']),
                            subtitle: Text('ID: ${game['id']}'),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () => _loadCovers(game['id']),
                          ),
                        );
                      },
                    ),
    );
  }
}
