import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;

  final List<String> _tabs = ['Overview', 'Activity', 'Linked Accounts'];

  // Mock user data
  final Map<String, dynamic> _userData = {
    'username': 'SolarGhost',
    'bio': 'Indie game enthusiast • Completionist • Speedrunner in training',
    'joinDate': DateTime(2023, 1, 15),
    'avatar': null, // Placeholder for avatar
    'banner': null, // Placeholder for banner
  };

  final Map<String, dynamic> _stats = {
    'totalGames': 127,
    'hoursPlayed': 2847,
    'achievementsUnlocked': 832,
    'totalAchievements': 1247,
    'completedGames': 12,
    'perfectGames': 3,
    'averageRating': 4.2,
  };

  final List<Map<String, dynamic>> _recentActivity = [
    {
      'type': 'achievement',
      'game': 'Hollow Knight',
      'title': 'Unlocked "Master of Shadows"',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'type': 'game',
      'game': 'Celeste',
      'title': 'Played for 3 hours',
      'time': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'type': 'note',
      'game': 'Elden Ring',
      'title': 'Added boss strategy notes',
      'time': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'type': 'collection',
      'title': 'Created "Cozy Games" collection',
      'time': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'type': 'achievement',
      'game': 'Hades',
      'title': 'Unlocked "No Death Run"',
      'time': DateTime.now().subtract(const Duration(days: 3)),
    },
  ];

  final List<Map<String, dynamic>> _favoriteGames = [
    {'title': 'Hollow Knight', 'hours': 156, 'color': Colors.purple},
    {'title': 'Celeste', 'hours': 89, 'color': Colors.blue},
    {'title': 'Hades', 'hours': 124, 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _linkedAccounts = [
    {
      'platform': 'Steam',
      'username': 'solarghost_dev',
      'linked': true,
      'icon': Icons.cloud,
      'color': Colors.blue,
    },
    {
      'platform': 'Epic Games',
      'username': 'Not linked',
      'linked': false,
      'icon': Icons.videogame_asset,
      'color': Colors.grey,
    },
    {
      'platform': 'GOG',
      'username': 'solarghost',
      'linked': true,
      'icon': Icons.games,
      'color': Colors.purple,
    },
    {
      'platform': 'Xbox',
      'username': 'Not linked',
      'linked': false,
      'icon': Icons.sports_esports,
      'color': Colors.green,
    },
    {
      'platform': 'PlayStation',
      'username': 'Not linked',
      'linked': false,
      'icon': Icons.gamepad,
      'color': Colors.blue,
    },
    {
      'platform': 'RetroAchievements',
      'username': 'solarghost',
      'linked': true,
      'icon': Icons.emoji_events,
      'color': Colors.amber,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner and avatar section
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.pink.withValues(alpha: 0.3),
                      Colors.purple.withValues(alpha: 0.3),
                      Colors.blue.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.landscape,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),

              // Avatar and edit button
              Positioned(
                bottom: -60,
                left: 32,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.pink.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0D0D0D),
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        Icons.account_circle,
                        size: 80,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Username and bio
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _userData['username'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userData['bio'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Edit profile button
              Positioned(
                top: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 80),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Focus(
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = index == _selectedTab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.pink.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.pink
                                : Colors.grey.shade800,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.pink
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Tab content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildTabContent(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildActivityTab();
      case 2:
        return _buildLinkedAccountsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats grid
        Row(
          children: [
            _buildStatCard(
              'Total Games',
              '${_stats['totalGames']}',
              Icons.videogame_asset,
              Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Hours Played',
              '${_stats['hoursPlayed']}',
              Icons.access_time,
              Colors.purple,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Achievements',
              '${_stats['achievementsUnlocked']}/${_stats['totalAchievements']}',
              Icons.emoji_events,
              Colors.amber,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(
              'Completed',
              '${_stats['completedGames']}',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Perfect Games',
              '${_stats['perfectGames']}',
              Icons.star,
              Colors.pink,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Avg Rating',
              '${_stats['averageRating']}',
              Icons.star_half,
              Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Favorite games
        Text(
          'Favorite Games',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Column(
          children: _favoriteGames.map((game) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (game['color'] as Color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.videogame_asset,
                      color: game['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${game['hours']} hours played',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Column(
          children: _recentActivity.map((activity) {
            return _buildActivityItem(activity);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color color;

    switch (activity['type']) {
      case 'achievement':
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 'game':
        icon = Icons.videogame_asset;
        color = Colors.blue;
        break;
      case 'note':
        icon = Icons.note;
        color = Colors.orange;
        break;
      case 'collection':
        icon = Icons.collections_bookmark;
        color = Colors.purple;
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (activity['game'] != null) ...[
                      Text(
                        activity['game'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    Text(
                      _getRelativeTime(activity['time'] as DateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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

  Widget _buildLinkedAccountsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked Accounts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect your gaming platforms to sync your library',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: _linkedAccounts.map((account) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: account['linked'] as bool
                      ? (account['color'] as Color).withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (account['color'] as Color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      account['icon'] as IconData,
                      color: account['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account['platform'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account['username'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: account['linked'] as bool
                                ? Colors.grey.shade500
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _toggleAccountLink(account),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: account['linked'] as bool
                          ? Colors.grey.shade800
                          : (account['color'] as Color),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      account['linked'] as bool ? 'Disconnect' : 'Connect',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _selectedTab = (_selectedTab - 1 + _tabs.length) % _tabs.length;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _selectedTab = (_selectedTab + 1) % _tabs.length;
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit profile (coming soon)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleAccountLink(Map<String, dynamic> account) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          account['linked'] as bool
              ? 'Disconnect ${account['platform']} (coming soon)'
              : 'Connect ${account['platform']} (coming soon)',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
