import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guide.dart';

class GuideDetailScreen extends StatefulWidget {
  final Guide guide;

  const GuideDetailScreen({
    super.key,
    required this.guide,
  });

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  late int _currentPage;
  late double _scrollPosition;
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollSaveTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.guide.currentPage;
    _scrollPosition = widget.guide.scrollPosition;
    _scrollController.addListener(_handleScroll);
    _restoreScrollOffset();
  }

  @override
  void dispose() {
    _scrollSaveTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForGuideType(widget.guide.type);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Back button and actions row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 24),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Back',
                        ),
                        const Spacer(),

                        // Action buttons
                        if (widget.guide.url != null)
                          IconButton(
                            icon: const Icon(Icons.open_in_browser, size: 20),
                            onPressed: _openInBrowser,
                            tooltip: 'Open in browser',
                          ),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border, size: 20),
                          onPressed: _toggleBookmark,
                          tooltip: 'Bookmark',
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, size: 20),
                          onPressed: _searchInGuide,
                          tooltip: 'Search',
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: _showOptions,
                          tooltip: 'Options',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Guide info
                    Row(
                      children: [
                        // Icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getIconForGuideType(widget.guide.type),
                            color: color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Title and metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.guide.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (widget.guide.gameTitle != null) ...[
                                    Icon(
                                      Icons.videogame_asset,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.guide.gameTitle!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Icon(
                                    _getIconForSource(widget.guide.source),
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getSourceLabel(widget.guide.source),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Progress bar
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getProgressText(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(_getProgress() * 100).toInt()}% complete',
                              style: TextStyle(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _getProgress(),
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content area
          Expanded(
            child: _buildContent(color),
          ),

          // Navigation controls (for PDFs)
          if (widget.guide.type == GuideType.pdf) _buildPDFControls(color),
        ],
      ),
    );
  }

  Widget _buildContent(Color color) {
    switch (widget.guide.type) {
      case GuideType.pdf:
        return _buildPDFContent(color);
      case GuideType.text:
        return _buildTextContent(color);
      case GuideType.url:
        return _buildURLContent(color);
    }
  }

  Widget _buildPDFContent(Color color) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handlePDFKeyEvent,
      child: Container(
        color: Colors.grey.shade900,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 8.5 / 11, // Standard letter size
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Page $_currentPage',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDF viewer coming soon',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(Color color) {
    // Mock text content
    final mockContent = '''
# ${widget.guide.title}

## Introduction
This is a placeholder for text guide content. In the final implementation, this would load the actual guide content from the local file.

## Section 1: Getting Started
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

## Section 2: Advanced Techniques
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

## Section 3: Tips and Tricks
* Tip 1: Use keyboard shortcuts for faster navigation
* Tip 2: Bookmark important sections
* Tip 3: Search for specific keywords

## Section 4: Common Issues
Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis.

## Section 5: Advanced Strategies
At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores.

## Conclusion
Thank you for reading this guide. For more information, visit the official resources.
''';

    return Container(
      color: const Color(0xFF0D0D0D),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(48),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SelectableText(
            mockContent,
            style: TextStyle(
              fontSize: 15,
              height: 1.8,
              color: Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildURLContent(Color color) {
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language,
              size: 64,
              color: color.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Web Guide',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (widget.guide.url != null) ...[
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.guide.url!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('Open in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Web viewer coming soon',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFControls(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous page
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: _currentPage > 1 ? _previousPage : null,
            tooltip: 'Previous page',
            color: _currentPage > 1 ? color : Colors.grey.shade700,
          ),
          const SizedBox(width: 24),

          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Page $_currentPage of ${widget.guide.totalPages}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Next page
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed:
                _currentPage < widget.guide.totalPages ? _nextPage : null,
            tooltip: 'Next page',
            color: _currentPage < widget.guide.totalPages
                ? color
                : Colors.grey.shade700,
          ),
        ],
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

  String? get _scrollKey {
    if (widget.guide.type != GuideType.text) return null;
    final id = widget.guide.id;
    if (id == null) return null;
    return 'guides.scroll.$id';
  }

  Future<void> _restoreScrollOffset() async {
    final key = _scrollKey;
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(key) ?? 0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final target = saved.clamp(0.0, max);
      if (max > 0) {
        _scrollPosition = target / max;
      } else {
        _scrollPosition = 0.0;
      }
      if (target > 0) {
        _scrollController.jumpTo(target);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleScroll() {
    final key = _scrollKey;
    if (key == null || !_scrollController.hasClients) return;

    final max = _scrollController.position.maxScrollExtent;
    if (max > 0) {
      _scrollPosition = (_scrollController.offset / max).clamp(0.0, 1.0);
    } else {
      _scrollPosition = 0.0;
    }

    _scrollSaveTimer?.cancel();
    _scrollSaveTimer = Timer(const Duration(milliseconds: 200), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, _scrollController.offset);
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _getProgressText() {
    if (widget.guide.type == GuideType.pdf) {
      return 'Page $_currentPage of ${widget.guide.totalPages}';
    }
    return '${(_scrollPosition * 100).toInt()}% read';
  }

  double _getProgress() {
    if (widget.guide.type == GuideType.pdf && widget.guide.totalPages > 0) {
      return _currentPage / widget.guide.totalPages;
    }
    return _scrollPosition;
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _saveProgress();
    }
  }

  void _nextPage() {
    if (_currentPage < widget.guide.totalPages) {
      setState(() {
        _currentPage++;
      });
      _saveProgress();
    }
  }

  void _saveProgress() {
    // TODO: Persist guide progress (page/scroll) to database when storage model/service exists.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Progress saved: ${_getProgressText()}'),
        duration: const Duration(seconds: 1),
        backgroundColor: _getColorForGuideType(widget.guide.type),
      ),
    );
  }

  KeyEventResult _handlePDFKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _previousPage();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _nextPage();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _openInBrowser() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${widget.guide.url} in browser'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleBookmark() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark added'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _searchInGuide() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search in guide (coming soon)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guide options (coming soon)'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
