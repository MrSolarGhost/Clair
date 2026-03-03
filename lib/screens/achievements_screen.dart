import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int _selectedGameIndex = 0;

  // Mock achievement data
  final Map<String, dynamic> _stats = {
    'totalAchievements': 1247,
    'unlockedAchievements': 832,
    'completedGames': 12,
    'perfectGames': 3,
  };

  final List<Map<String, dynamic>> _recentAchievements = [
    {
      'title': 'Master of Shadows',
      'description': 'Complete all stealth challenges',
      'game': 'Hollow Knight',
      'unlocked': '2 hours ago',
      'rare': true,
    },
    {
      'title': 'Speed Demon',
      'description': 'Complete any level in under 30 seconds',
      'game': 'Celeste',
      'unlocked': 'Yesterday',
      'rare': false,
    },
    {
      'title': 'No Death Run',
      'description': 'Complete a full escape without dying',
      'game': 'Hades',
      'unlocked': '2 days ago',
      'rare': true,
    },
  ];

  final List<Map<String, dynamic>> _gameProgress = [
    {
      'game': 'Hades',
      'system': 'PC',
      'unlocked': 48,
      'total': 49,
      'percentage': 98,
      'color': Colors.red,
    },
    {
      'game': 'Celeste',
      'system': 'PC',
      'unlocked': 35,
      'total': 35,
      'percentage': 100,
      'color': Colors.blue,
    },
    {
      'game': 'Hollow Knight',
      'system': 'PC',
      'unlocked': 42,
      'total': 63,
      'percentage': 67,
      'color': Colors.purple,
    },
    {
      'game': 'Portal 2',
      'system': 'PC',
      'unlocked': 28,
      'total': 51,
      'percentage': 55,
      'color': Colors.orange,
    },
    {
      'game': 'The Legend of Zelda: BOTW',
      'system': 'Switch',
      'unlocked': 15,
      'total': 76,
      'percentage': 20,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your progress across all games',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // Stats cards
          Row(
            children: [
              _buildStatCard(
                'Total Unlocked',
                '${_stats['unlockedAchievements']}/${_stats['totalAchievements']}',
                Icons.emoji_events,
                Colors.amber,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Completed Games',
                '${_stats['completedGames']}',
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Perfect Games',
                '${_stats['perfectGames']}',
                Icons.star,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Content tabs
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent achievements
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Unlocks',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _recentAchievements.length,
                          itemBuilder: (context, index) {
                            final achievement = _recentAchievements[index];
                            return _buildAchievementCard(achievement);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Game progress
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Games by Completion',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Focus(
                          autofocus: true,
                          onKeyEvent: _handleKeyEvent,
                          child: ListView.builder(
                            itemCount: _gameProgress.length,
                            itemBuilder: (context, index) {
                              final game = _gameProgress[index];
                              final isSelected = index == _selectedGameIndex;
                              return _buildGameProgressCard(game, isSelected);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Achievement icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Achievement info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (achievement['rare'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'RARE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade300,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement['description'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      achievement['game'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      ' • ${achievement['unlocked']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameProgressCard(Map<String, dynamic> game, bool isSelected) {
    final percentage = game['percentage'] as int;
    final color = game['color'] as Color;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedGameIndex = _gameProgress.indexOf(game));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game['game'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game['system'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${game['unlocked']}/${game['total']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 6,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedGameIndex = (_selectedGameIndex - 1 + _gameProgress.length) %
            _gameProgress.length;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedGameIndex = (_selectedGameIndex + 1) % _gameProgress.length;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      // Open game achievements detail
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'View ${_gameProgress[_selectedGameIndex]['game']} achievements'),
          backgroundColor: _gameProgress[_selectedGameIndex]['color'] as Color,
        ),
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
