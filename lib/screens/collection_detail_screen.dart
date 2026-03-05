import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/collection.dart';
import '../models/game.dart';
import '../services/collections_service.dart';
import 'collection_editor_screen.dart';
import 'game_card_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final int collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final CollectionsService _collectionsService = CollectionsService();
  Collection? _collection;
  List<Game> _games = [];
  bool _isLoading = true;
  int _selectedGameIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    try {
      final collection = await _collectionsService.getCollection(widget.collectionId);
      final games = await _collectionsService.getGamesForCollection(widget.collectionId);
      if (mounted) {
        setState(() {
          _collection = collection;
          _games = games;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editCollection() async {
    if (_collection == null) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionEditorScreen(collection: _collection),
      ),
    );
    if (updated == true) {
      _loadCollection();
    }
  }

  void _openGameCard(Game game) {
    if (game.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameCardScreen(gameId: game.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collection == null
              ? const Center(child: Text('Collection not found'))
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _games.isEmpty
                          ? _buildEmptyState()
                          : _buildGamesGrid(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    final coverPath = _collection?.coverPath;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blueGrey.withValues(alpha: 0.3),
            Colors.blueGrey.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 24),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _editCollection,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blueGrey.withValues(alpha: 0.2),
                  ),
                  tooltip: 'Edit collection',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade900,
                    image: coverPath != null && coverPath.isNotEmpty
                        ? DecorationImage(
                            image: FileImage(File(coverPath)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: coverPath == null || coverPath.isEmpty
                      ? Icon(Icons.collections_bookmark, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _collection?.name ?? '',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _collection?.description ?? '',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      Text('${_games.length} games',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.collections_bookmark, size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text('No games yet', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildGamesGrid() {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 0.80,
        ),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          final isSelected = index == _selectedGameIndex;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedGameIndex = index);
              _openGameCard(game);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blueGrey : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 115,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: game.coverPath != null && game.coverPath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.file(
                                File(game.coverPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.videogame_asset,
                                size: 32,
                                color: Colors.grey.shade600,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text(
                            game.system ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final itemsPerRow = 4;
    final totalItems = _games.length;
    if (totalItems == 0) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _selectedGameIndex = (_selectedGameIndex - 1 + totalItems) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _selectedGameIndex = (_selectedGameIndex + 1) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedGameIndex = (_selectedGameIndex - itemsPerRow + totalItems) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedGameIndex = (_selectedGameIndex + itemsPerRow) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _openGameCard(_games[_selectedGameIndex]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
