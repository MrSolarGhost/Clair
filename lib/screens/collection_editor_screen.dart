import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/collection.dart';
import '../models/game.dart';
import '../services/collections_service.dart';
import '../services/database_service.dart';

class CollectionEditorScreen extends StatefulWidget {
  final Collection? collection;

  const CollectionEditorScreen({super.key, this.collection});

  @override
  State<CollectionEditorScreen> createState() => _CollectionEditorScreenState();
}

class _CollectionEditorScreenState extends State<CollectionEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _collectionsService = CollectionsService();
  final _dbService = DatabaseService.instance;

  bool _isLoading = true;
  String? _selectedCoverPath;
  List<Game> _games = [];
  final Set<int> _selectedGameIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (widget.collection != null) {
        _nameController.text = widget.collection!.name;
        _descriptionController.text = widget.collection!.description ?? '';
        _selectedCoverPath = widget.collection!.coverPath;
        final existingGames =
            await _collectionsService.getGamesForCollection(widget.collection!.id!);
        _selectedGameIds.addAll(existingGames.map((g) => g.id!).toSet());
      }
      _games = await _dbService.getAllGames();
    } catch (_) {
      // Silent failure
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCoverFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;

      final source = File(result.files.single.path!);
      final docs = await getApplicationDocumentsDirectory();
      final filename =
          'collection_${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
      final dest = File('${docs.path}/$filename');
      await source.copy(dest.path);

      setState(() {
        _selectedCoverPath = dest.path;
      });
    } catch (_) {
      // Silent failure
    }
  }

  void _pickCoverFromGame(Game game) {
    if (game.coverPath == null || game.coverPath!.isEmpty) return;
    setState(() {
      _selectedCoverPath = game.coverPath;
    });
  }

  Future<void> _saveCollection() async {
    try {
      final name = _nameController.text.trim();
      if (name.isEmpty) return;

      final description = _descriptionController.text.trim();
      if (widget.collection == null) {
        final id = await _collectionsService.createCollection(
          Collection(
            name: name,
            description: description.isEmpty ? null : description,
            coverPath: _selectedCoverPath,
          ),
        );
        for (final gameId in _selectedGameIds) {
          await _collectionsService.addGameToCollection(id, gameId);
        }
      } else {
        await _collectionsService.updateCollection(
          widget.collection!.copyWith(
            name: name,
            description: description.isEmpty ? null : description,
            coverPath: _selectedCoverPath,
          ),
        );
        final existing =
            await _collectionsService.getGamesForCollection(widget.collection!.id!);
        final existingIds = existing.map((g) => g.id!).toSet();

        for (final gameId in _selectedGameIds.difference(existingIds)) {
          await _collectionsService.addGameToCollection(widget.collection!.id!, gameId);
        }
        for (final gameId in existingIds.difference(_selectedGameIds)) {
          await _collectionsService.removeGameFromCollection(widget.collection!.id!, gameId);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      // Silent failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection == null ? 'New Collection' : 'Edit Collection'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Artwork', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickCoverFromFile,
                        icon: const Icon(Icons.image),
                        label: const Text('Pick from file'),
                      ),
                      const SizedBox(width: 12),
                      if (_selectedCoverPath != null)
                        Expanded(
                          child: Text(
                            _selectedCoverPath!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Pick from game cover'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _games
                          .where((g) => g.coverPath != null && g.coverPath!.isNotEmpty)
                          .map((game) => GestureDetector(
                                onTap: () => _pickCoverFromGame(game),
                                child: Container(
                                  width: 60,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selectedCoverPath == game.coverPath
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    image: DecorationImage(
                                      image: FileImage(File(game.coverPath!)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Games', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _games.length,
                      itemBuilder: (context, index) {
                        final game = _games[index];
                        final selected = _selectedGameIds.contains(game.id);
                        return CheckboxListTile(
                          value: selected,
                          title: Text(game.title),
                          subtitle: Text(game.system ?? 'Unknown'),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedGameIds.add(game.id!);
                              } else {
                                _selectedGameIds.remove(game.id!);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _saveCollection,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
