import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game.dart';
import 'game_card_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String collectionName;
  final String collectionDescription;
  final Color collectionColor;
  final int gameCount;

  const CollectionDetailScreen({
    super.key,
    required this.collectionName,
    required this.collectionDescription,
    required this.collectionColor,
    required this.gameCount,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  int _selectedGameIndex = 0;
  List<Game> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock games for this collection
    final mockGames = [
      Game(
        title: 'Celeste',
        system: 'PC',
        genre: 'Platformer',
        status: GameStatus.completed,
        playTimeMinutes: 720,
      ),
      Game(
        title: 'Hollow Knight',
        system: 'PC',
        genre: 'Metroidvania',
        status: GameStatus.playing,
        playTimeMinutes: 1560,
      ),
      Game(
        title: 'Hades',
        system: 'PC',
        genre: 'Roguelike',
        status: GameStatus.completed,
        playTimeMinutes: 3600,
      ),
      Game(
        title: 'Portal 2',
        system: 'PC',
        genre: 'Puzzle',
        status: GameStatus.completed,
        playTimeMinutes: 480,
      ),
    ];

    setState(() {
      _games = mockGames;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Collection header
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.collectionColor.withValues(alpha: 0.3),
                  widget.collectionColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and actions
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: _addGames,
                            style: IconButton.styleFrom(
                              backgroundColor: widget.collectionColor.withValues(alpha: 0.2),
                            ),
                            tooltip: 'Add games',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.image, size: 20),
                            onPressed: _changeArtwork,
                            style: IconButton.styleFrom(
                              backgroundColor: widget.collectionColor.withValues(alpha: 0.2),
                            ),
                            tooltip: 'Change artwork',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onPressed: _showOptions,
                            style: IconButton.styleFrom(
                              backgroundColor: widget.collectionColor.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Collection info
                  Row(
                    children: [
                      // Artwork placeholder
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: widget.collectionColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.collectionColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.collections_bookmark,
                          size: 48,
                          color: widget.collectionColor,
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Collection details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.collectionName,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: widget.collectionColor,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.collectionDescription,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_games.length} games',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Games grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _games.isEmpty
                      ? _buildEmptyState()
                      : _buildGamesGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 64,
            color: widget.collectionColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No games yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add games to this collection',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addGames,
            icon: const Icon(Icons.add),
            label: const Text('Add Games'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.collectionColor,
              foregroundColor: Colors.white,
            ),
          ),
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

          return _buildGameCard(game, isSelected);
        },
      ),
    );
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

  Widget _buildGameCard(Game game, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedGameIndex = _games.indexOf(game));
        _openGameCard(game);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? widget.collectionColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover art
            SizedBox(
              height: 115,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade800,
                      Colors.grey.shade900,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.videogame_asset,
                        size: 48,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildStatusBadge(game.status),
                    ),
                  ],
                ),
              ),
            ),
            // Game info
            SizedBox(
              height: 62,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.system ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (game.playTimeMinutes > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 10,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${game.playTimeMinutes ~/ 60}h ${game.playTimeMinutes % 60}m',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(GameStatus status) {
    Color badgeColor;
    IconData icon;

    switch (status) {
      case GameStatus.unplayed:
        badgeColor = Colors.grey;
        icon = Icons.fiber_new;
        break;
      case GameStatus.playing:
        badgeColor = Colors.blue;
        icon = Icons.play_arrow;
        break;
      case GameStatus.beaten:
        badgeColor = Colors.green;
        icon = Icons.check;
        break;
      case GameStatus.completed:
        badgeColor = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case GameStatus.dropped:
        badgeColor = Colors.red;
        icon = Icons.close;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        size: 16,
        color: badgeColor,
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
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _addGames() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Add games (coming soon)'),
        backgroundColor: widget.collectionColor,
      ),
    );
  }

  void _changeArtwork() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Change artwork (coming soon)'),
        backgroundColor: widget.collectionColor,
      ),
    );
  }

  void _showOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Collection options (coming soon)'),
        backgroundColor: widget.collectionColor,
      ),
    );
  }
}
