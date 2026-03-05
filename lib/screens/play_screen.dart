import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import 'game_card_screen.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  int _selectedViewIndex = 0;
  int _selectedGameIndex = 0;
  List<Game> _games = [];
  bool _isLoading = true;
  String? _selectedFilter; // For filtering by specific genre/system/status

  final List<Map<String, dynamic>> _views = [
    {'label': 'All Games', 'icon': Icons.grid_view},
    {'label': 'By System', 'icon': Icons.devices},
    {'label': 'By Genre', 'icon': Icons.category},
    {'label': 'By Status', 'icon': Icons.check_circle},
  ];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);

    final dbService = DatabaseService.instance;
    final allGames = await dbService.getAllGames();
    
    // Filter out missing files by default
    final availableGames = allGames.where((g) => g.fileStatus == 0).toList();

    setState(() {
      _games = availableGames;
      _isLoading = false;
      if (_games.isNotEmpty && _selectedGameIndex >= _games.length) {
        _selectedGameIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Focus(
                onKeyEvent: _handleViewKeyEvent,
                child: Row(
                  children: List.generate(_views.length, (index) {
                    final view = _views[index];
                    final isSelected = index == _selectedViewIndex;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedViewIndex = index;
                            _selectedGameIndex = 0;
                          });
                          _loadGamesForView(index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade700.withValues(alpha: 0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade400
                                  : Colors.grey.shade800,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                view['icon'] as IconData,
                                size: 16,
                                color: isSelected
                                    ? Colors.blue.shade300
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                view['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade600,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Game count
              Text(
                '${_games.length} games',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter chips for grouped views
          if (_selectedViewIndex > 0) _buildFilterChips(),

          const SizedBox(height: 16),

          // Game grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _games.isEmpty
                    ? _buildEmptyState()
                    : _buildGameGrid(),
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
            Icons.videogame_asset_off,
            size: 64,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'No games found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add games to your library to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    // Always use grouped view (All Games just has one group)
    return _buildGroupedGameGrid();
  }

  Widget _buildAllGamesGrid() {
    // Old simple grid view - no longer used
    return Focus(
      autofocus: true,
      onKeyEvent: _handleGameKeyEvent,
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
                  color: isSelected
                      ? Colors.blue.shade400
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cover art - FIXED HEIGHT
                  SizedBox(
                    height: 240,
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
                          // Placeholder cover
                          Center(
                            child: Icon(
                              Icons.videogame_asset,
                              size: 48,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          // Status indicator
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _buildStatusBadge(game.status),
                          ),
                          // Favorite indicator
                          if (game.isFavorite)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Game info - FIXED HEIGHT
                  SizedBox(
                    height: 100,
                    child: Container(
                      padding: const EdgeInsets.all(12),
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
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            game.system ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 11,
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
                                  size: 11,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${game.playTimeMinutes ~/ 60}h ${game.playTimeMinutes % 60}m',
                                  style: TextStyle(
                                    fontSize: 11,
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
        },
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

  KeyEventResult _handleViewKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.keyQ) {
      setState(() {
        _selectedViewIndex = (_selectedViewIndex - 1 + _views.length) % _views.length;
        _selectedGameIndex = 0;
        _selectedFilter = null; // Reset filter when changing views
      });
      _loadGamesForView(_selectedViewIndex);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
      setState(() {
        _selectedViewIndex = (_selectedViewIndex + 1) % _views.length;
        _selectedGameIndex = 0;
        _selectedFilter = null; // Reset filter when changing views
      });
      _loadGamesForView(_selectedViewIndex);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleGameKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final itemsPerRow = 4;
    final totalItems = _games.length;

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
      if (_games.isNotEmpty) {
        _openGameCard(_games[_selectedGameIndex]);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _loadGamesForView(int viewIndex) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 200));

    // Get all games first
    await _loadGames();

    // Sort based on selected view
    setState(() {
      switch (viewIndex) {
        case 0: // All Games - alphabetical
          _games.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 1: // By System
          _games.sort((a, b) {
            final systemCompare = (a.system ?? 'Unknown').compareTo(b.system ?? 'Unknown');
            if (systemCompare != 0) return systemCompare;
            return a.title.compareTo(b.title);
          });
          break;
        case 2: // By Genre
          _games.sort((a, b) {
            final genreCompare = (a.genre ?? 'Unknown').compareTo(b.genre ?? 'Unknown');
            if (genreCompare != 0) return genreCompare;
            return a.title.compareTo(b.title);
          });
          break;
        case 3: // By Status
          _games.sort((a, b) {
            final statusCompare = a.status.index.compareTo(b.status.index);
            if (statusCompare != 0) return statusCompare;
            return a.title.compareTo(b.title);
          });
          break;
      }
      _isLoading = false;
    });
  }

  void _openGameCard(Game game) {
    if (game.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game not available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameCardScreen(gameId: game.id!),
      ),
    );
  }

  Widget _buildScrollingText(String text) {
    return SizedBox(
      height: 14,
      child: _ScrollingText(
        text: text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    List<String> filters = [];

    // Get unique values based on current view
    switch (_selectedViewIndex) {
      case 1: // By System
        filters = _games.map((g) => g.system ?? 'Unknown').toSet().toList()..sort();
        break;
      case 2: // By Genre
        filters = _games.map((g) => g.genre ?? 'Unknown').toSet().toList()..sort();
        break;
      case 3: // By Status
        filters = GameStatus.values.map((s) => s.displayName).toList();
        break;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" filter chip
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedFilter == null,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = null;
                });
              },
              selectedColor: Colors.blue.shade700.withValues(alpha: 0.3),
              checkmarkColor: Colors.blue.shade300,
            ),
          ),
          // Individual filter chips
          ...filters.map((filter) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = selected ? filter : null;
                    });
                  },
                  selectedColor: Colors.blue.shade700.withValues(alpha: 0.3),
                  checkmarkColor: Colors.blue.shade300,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildGroupedGameGrid() {
    // Group games based on current view
    Map<String, List<Game>> groupedGames = {};

    // Apply filter if selected
    List<Game> filteredGames = _games;
    if (_selectedFilter != null) {
      filteredGames = _games.where((game) {
        switch (_selectedViewIndex) {
          case 1: // By System
            return (game.system ?? 'Unknown') == _selectedFilter;
          case 2: // By Genre
            return (game.genre ?? 'Unknown') == _selectedFilter;
          case 3: // By Status
            return game.status.displayName == _selectedFilter;
          default:
            return true;
        }
      }).toList();
    }

    for (final game in filteredGames) {
      String groupKey;
      switch (_selectedViewIndex) {
        case 0: // All Games - single group
          groupKey = 'All Games';
          break;
        case 1: // By System
          groupKey = game.system ?? 'Unknown';
          break;
        case 2: // By Genre
          groupKey = game.genre ?? 'Unknown';
          break;
        case 3: // By Status
          groupKey = game.status.displayName;
          break;
        default:
          groupKey = 'All';
      }

      if (!groupedGames.containsKey(groupKey)) {
        groupedGames[groupKey] = [];
      }
      groupedGames[groupKey]!.add(game);
    }

    return Focus(
      autofocus: true,
      onKeyEvent: _handleGameKeyEvent,
      child: ListView.builder(
        itemCount: groupedGames.length,
        itemBuilder: (context, groupIndex) {
          final groupKey = groupedGames.keys.elementAt(groupIndex);
          final gamesInGroup = groupedGames[groupKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header
              Padding(
                padding: EdgeInsets.only(bottom: 16.0, top: groupIndex == 0 ? 0 : 24.0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      groupKey,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade300,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${gamesInGroup.length} ${gamesInGroup.length == 1 ? 'game' : 'games'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Games grid for this group
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.80,
                ),
                itemCount: gamesInGroup.length,
                itemBuilder: (context, gameIndex) {
                  final game = gamesInGroup[gameIndex];
                  final globalIndex = _games.indexOf(game);
                  final isSelected = globalIndex == _selectedGameIndex;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedGameIndex = globalIndex);
                      _openGameCard(game);
                    },
                    child: _buildGameCard(game, isSelected),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGameCard(Game game, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.blue.shade400
              : Colors.transparent,
          width: 3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover art - Fixed balanced height
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
                  // Placeholder cover
                  Center(
                    child: Icon(
                      Icons.videogame_asset,
                      size: 48,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  // Status indicator
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildStatusBadge(game.status),
                  ),
                  // Favorite indicator
                  if (game.isFavorite)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Game info - Fixed balanced height
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
                  // Scrolling title for selected cards
                  isSelected && game.title.length > 20
                      ? _buildScrollingText(game.title)
                      : Text(
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
    );
  }
}

// Scrolling text widget for long game titles
class _ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ScrollingText({
    required this.text,
    required this.style,
  });

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.text.length * 150),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: -1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textPainter = TextPainter(
            text: TextSpan(text: widget.text, style: widget.style),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();

          final textWidth = textPainter.width;
          final containerWidth = constraints.maxWidth;

          if (textWidth <= containerWidth) {
            return Text(widget.text, style: widget.style);
          }

          return Stack(
            children: [
              Positioned(
                left: _animation.value * (textWidth + 20),
                child: Text(
                  widget.text,
                  style: widget.style,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
              Positioned(
                left: _animation.value * (textWidth + 20) + textWidth + 20,
                child: Text(
                  widget.text,
                  style: widget.style,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
