import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/guide.dart';
import 'guide_detail_screen.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  int _selectedIndex = 0;

  // Mock guides data
  final List<Guide> _guides = [
    Guide(
      id: 1,
      title: 'Elden Ring Complete Walkthrough',
      gameTitle: 'Elden Ring',
      type: GuideType.pdf,
      source: GuideSource.gamefaqs,
      localPath: '/guides/elden-ring-walkthrough.pdf',
      url: 'https://gamefaqs.com/elden-ring',
      currentPage: 42,
      totalPages: 150,
      lastAccessed: DateTime.now().subtract(const Duration(hours: 2)),
      createdDate: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Guide(
      id: 2,
      title: 'Hollow Knight - All Charms Location',
      gameTitle: 'Hollow Knight',
      type: GuideType.url,
      source: GuideSource.other,
      url: 'https://hollowknight.fandom.com/wiki/Charms',
      scrollPosition: 0.65,
      lastAccessed: DateTime.now().subtract(const Duration(days: 1)),
      createdDate: DateTime.now().subtract(const Duration(days: 14)),
    ),
    Guide(
      id: 3,
      title: 'Celeste B-Side Strategies',
      gameTitle: 'Celeste',
      type: GuideType.text,
      source: GuideSource.manual,
      localPath: '/guides/celeste-bside.txt',
      scrollPosition: 0.32,
      lastAccessed: DateTime.now().subtract(const Duration(days: 3)),
      createdDate: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Guide(
      id: 4,
      title: 'Hades - All Keepsakes and Effects',
      gameTitle: 'Hades',
      type: GuideType.pdf,
      source: GuideSource.gamefaqs,
      localPath: '/guides/hades-keepsakes.pdf',
      url: 'https://gamefaqs.com/hades',
      currentPage: 8,
      totalPages: 25,
      lastAccessed: DateTime.now().subtract(const Duration(hours: 12)),
      createdDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Guide(
      id: 5,
      title: 'Portal 2 - Advanced Test Chambers',
      gameTitle: 'Portal 2',
      type: GuideType.url,
      source: GuideSource.other,
      url: 'https://portal.fandom.com/wiki/Advanced_Chambers',
      scrollPosition: 0.0,
      createdDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Sort by last accessed (most recent first), null last accessed go to end
    final sortedGuides = List<Guide>.from(_guides)
      ..sort((a, b) {
        if (a.lastAccessed == null && b.lastAccessed == null) return 0;
        if (a.lastAccessed == null) return 1;
        if (b.lastAccessed == null) return -1;
        return b.lastAccessed!.compareTo(a.lastAccessed!);
      });

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
                    'Guides',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Game walkthroughs and resources',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              // Add guide button
              ElevatedButton.icon(
                onPressed: () {
                  _showAddGuideDialog();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Guide'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Guides list
          Expanded(
            child: Focus(
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: ListView.builder(
                itemCount: sortedGuides.length,
                itemBuilder: (context, index) {
                  final guide = sortedGuides[index];
                  final isSelected = index == _selectedIndex;
                  return _buildGuideCard(guide, isSelected);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(Guide guide, bool isSelected) {
    final color = _getColorForGuideType(guide.type);
    final icon = _getIconForGuideType(guide.type);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = _guides.indexOf(guide));
        _openGuide(guide);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            // Guide type icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),

            // Guide info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    guide.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Game and source
                  Row(
                    children: [
                      if (guide.gameTitle != null) ...[
                        Icon(
                          Icons.videogame_asset,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          guide.gameTitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(
                        _getIconForSource(guide.source),
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getSourceLabel(guide.source),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            guide.progressText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (guide.lastAccessed != null)
                            Text(
                              _getRelativeTime(guide.lastAccessed!),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: guide.progress,
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade800,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Actions
            Row(
              children: [
                if (guide.url != null)
                  IconButton(
                    icon: Icon(
                      Icons.download,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    tooltip: 'Download/Update',
                    onPressed: () => _downloadGuide(guide),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  tooltip: 'Options',
                  onPressed: () => _showGuideOptions(guide),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForGuideType(GuideType type) {
    switch (type) {
      case GuideType.pdf:
        return Colors.red;
      case GuideType.text:
        return Colors.green;
      case GuideType.url:
        return Colors.cyan;
    }
  }

  IconData _getIconForGuideType(GuideType type) {
    switch (type) {
      case GuideType.pdf:
        return Icons.picture_as_pdf;
      case GuideType.text:
        return Icons.description;
      case GuideType.url:
        return Icons.language;
    }
  }

  IconData _getIconForSource(GuideSource source) {
    switch (source) {
      case GuideSource.gamefaqs:
        return Icons.public;
      case GuideSource.manual:
        return Icons.edit;
      case GuideSource.other:
        return Icons.link;
    }
  }

  String _getSourceLabel(GuideSource source) {
    switch (source) {
      case GuideSource.gamefaqs:
        return 'GameFAQs';
      case GuideSource.manual:
        return 'Manual';
      case GuideSource.other:
        return 'Web';
    }
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

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + _guides.length) % _guides.length;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _guides.length;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _openGuide(_guides[_selectedIndex]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _openGuide(Guide guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuideDetailScreen(guide: guide),
      ),
    );
  }

  void _downloadGuide(Guide guide) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading: ${guide.title}'),
        backgroundColor: Colors.cyan.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showGuideOptions(Guide guide) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Options for: ${guide.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Add Guide'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Upload PDF'),
              subtitle: const Text('Add a PDF guide from your device'),
              onTap: () {
                Navigator.pop(context);
                _addPDFGuide();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.green),
              title: const Text('Upload Text File'),
              subtitle: const Text('Add a text guide from your device'),
              onTap: () {
                Navigator.pop(context);
                _addTextGuide();
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.cyan),
              title: const Text('Add URL'),
              subtitle: const Text('Link to GameFAQs or any web guide'),
              onTap: () {
                Navigator.pop(context);
                _addURLGuide();
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

  void _addPDFGuide() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('PDF upload (coming soon)'),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addTextGuide() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Text file upload (coming soon)'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addURLGuide() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('URL input (coming soon)'),
        backgroundColor: Colors.cyan.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
