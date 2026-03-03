import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/input_service.dart';
import 'play_screen.dart';
import 'collections_screen.dart';
import 'achievements_screen.dart';
import 'guides_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'friends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.play_arrow, 'label': 'Play', 'color': Colors.blue},
    {'icon': Icons.collections_bookmark, 'label': 'Collections', 'color': Colors.purple},
    {'icon': Icons.emoji_events, 'label': 'Achievements', 'color': Colors.amber},
    {'icon': Icons.book, 'label': 'Guides', 'color': Colors.cyan},
    {'icon': Icons.note, 'label': 'Notes', 'color': Colors.orange},
    {'icon': Icons.people, 'label': 'Friends', 'color': Colors.green},
    {'icon': Icons.account_circle, 'label': 'Profile', 'color': Colors.pink},
    {'icon': Icons.settings, 'label': 'Settings', 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    final inputService = context.watch<InputService>();

    return Scaffold(
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade800,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    // Logo/Title
                    Text(
                      'Clair',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                    ),
                    const SizedBox(width: 48),

                    // Navigation Items (icon-only for clean look)
                    Expanded(
                      child: Focus(
                        autofocus: true,
                        onKeyEvent: _handleKeyEvent,
                        child: Row(
                          children: List.generate(_navItems.length, (index) {
                            final item = _navItems[index];
                            final isSelected = index == _selectedIndex;

                            return Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Tooltip(
                                message: item['label'] as String,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedIndex = index);
                                    _onNavItemSelected(index);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (item['color'] as Color).withValues(alpha: 0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? (item['color'] as Color)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      size: 22,
                                      color: isSelected
                                          ? (item['color'] as Color)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    // Input indicator
                    Row(
                      children: [
                        Icon(
                          inputService.hasGamepad
                              ? Icons.gamepad
                              : Icons.keyboard,
                          size: 18,
                          color: inputService.hasGamepad
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          inputService.hasGamepad ? 'Controller' : 'Keyboard',
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
            ),
          ),

          // Main Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: // Play
        return const PlayScreenContent();
      case 1: // Collections
        return const CollectionsScreen();
      case 2: // Achievements
        return const AchievementsScreen();
      case 3: // Guides
        return const GuidesScreen();
      case 4: // Notes
        return const NotesScreen();
      case 5: // Friends
        return const FriendsScreen();
      case 6: // Profile
        return const ProfileScreen();
      case 7: // Settings
        return _buildPlaceholder('Settings', Icons.settings, Colors.grey);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlaceholder(String title, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: color.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + _navItems.length) % _navItems.length;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _navItems.length;
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildHint(String key, String action) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          action,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  void _onNavItemSelected(int index) {
    // Navigation handled by _buildContent() - no need for separate navigation
  }
}

// Embedded Play screen content (no separate navigation needed)
class PlayScreenContent extends StatelessWidget {
  const PlayScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlayScreen();
  }
}
