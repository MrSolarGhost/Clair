import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SnapshotCard {
  final String username;
  final String? bio;
  final String? avatar;
  final int totalGames;
  final int hoursPlayed;
  final int achievementsUnlocked;
  final int completedGames;
  final List<String> favoriteGames;
  final DateTime importedAt;
  final String? shareCode;

  const SnapshotCard({
    required this.username,
    this.bio,
    this.avatar,
    required this.totalGames,
    required this.hoursPlayed,
    required this.achievementsUnlocked,
    required this.completedGames,
    required this.favoriteGames,
    required this.importedAt,
    this.shareCode,
  });
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  int _selectedIndex = 0;

  // Mock snapshot cards data
  final List<SnapshotCard> _snapshotCards = [
    SnapshotCard(
      username: 'Alex',
      bio: 'Metroidvania enthusiast',
      totalGames: 89,
      hoursPlayed: 1842,
      achievementsUnlocked: 456,
      completedGames: 23,
      favoriteGames: ['Hollow Knight', 'Ori and the Will of the Wisps', 'Metroid Dread'],
      importedAt: DateTime.now().subtract(const Duration(days: 15)),
      shareCode: 'AX7K9M',
    ),
    SnapshotCard(
      username: 'Jordan',
      bio: 'Speedrunner • Platformer lover',
      totalGames: 42,
      hoursPlayed: 892,
      achievementsUnlocked: 234,
      completedGames: 18,
      favoriteGames: ['Celeste', 'Super Meat Boy', 'The End is Nigh'],
      importedAt: DateTime.now().subtract(const Duration(days: 8)),
      shareCode: 'JD3P8Q',
    ),
    SnapshotCard(
      username: 'Sam',
      bio: 'RPG completionist',
      totalGames: 156,
      hoursPlayed: 3421,
      achievementsUnlocked: 892,
      completedGames: 45,
      favoriteGames: ['Hades', 'Divinity: OS 2', 'Baldur\'s Gate 3'],
      importedAt: DateTime.now().subtract(const Duration(days: 22)),
      shareCode: 'SM5R2W',
    ),
    SnapshotCard(
      username: 'Riley',
      bio: 'Soulsborne fan',
      totalGames: 67,
      hoursPlayed: 2103,
      achievementsUnlocked: 378,
      completedGames: 15,
      favoriteGames: ['Elden Ring', 'Dark Souls 3', 'Bloodborne'],
      importedAt: DateTime.now().subtract(const Duration(days: 5)),
      shareCode: 'RL9N4T',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Friends',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_snapshotCards.length} snapshot cards imported',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              // Action buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _shareMyCard,
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('Share My Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _importCard,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Import Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Info box about snapshot cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Snapshot cards are offline profiles. No live sync, just static stats you can share.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Snapshot cards grid
          Expanded(
            child: Focus(
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.1,
                ),
                itemCount: _snapshotCards.length,
                itemBuilder: (context, index) {
                  final card = _snapshotCards[index];
                  final isSelected = index == _selectedIndex;
                  return _buildSnapshotCard(card, isSelected);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotCard(SnapshotCard card, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = _snapshotCards.indexOf(card));
        _viewCard(card);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withValues(alpha: 0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and username
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_circle,
                    color: Colors.green,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.green : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (card.bio != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          card.bio!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('Games', '${card.totalGames}', Icons.videogame_asset),
                _buildMiniStat('Hours', '${card.hoursPlayed}', Icons.access_time),
                _buildMiniStat('Completed', '${card.completedGames}', Icons.check_circle),
              ],
            ),
            const SizedBox(height: 16),

            // Favorite games
            Text(
              'Favorites:',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: card.favoriteGames.take(3).map((game) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $game',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Imported ${_getRelativeTime(card.importedAt)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (card.shareCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      card.shareCode!,
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final itemsPerRow = 2;
    final totalItems = _snapshotCards.length;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + totalItems) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - itemsPerRow + totalItems) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + itemsPerRow) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _viewCard(_snapshotCards[_selectedIndex]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _viewCard(SnapshotCard card) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View ${card.username}\'s snapshot card'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareMyCard() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Share Your Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2,
                  size: 120,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'SG4K7M',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan QR code or use share code',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _importCard() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Import Snapshot Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.purple),
              title: const Text('Scan QR Code'),
              subtitle: const Text('Use camera to scan'),
              onTap: () {
                Navigator.pop(context);
                _scanQRCode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard, color: Colors.green),
              title: const Text('Enter Share Code'),
              subtitle: const Text('6-character code'),
              onTap: () {
                Navigator.pop(context);
                _enterShareCode();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _scanQRCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('QR code scanner (coming soon)'),
        backgroundColor: Colors.purple.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _enterShareCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Enter share code (coming soon)'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
