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
  List<Map<String, dynamic>> _covers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCovers();
  }

  Future<void> _loadCovers() async {
    try {
      final service = SteamGridDBService(
        apiKey: dotenv.env['STEAMGRIDDB_API_KEY'] ?? '',
      );

      // Search for game
      final results = await service.search(widget.game.title);
      if (results.isEmpty) {
        setState(() {
          _error = 'No results found';
          _isLoading = false;
        });
        return;
      }

      // Get covers for first result
      final covers = await service.getCovers(results.first['id']);
      setState(() {
        _covers = covers;
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
        title: Text('Choose Cover - ${widget.game.title}'),
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
                          _loadCovers();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
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
                ),
    );
  }
}
