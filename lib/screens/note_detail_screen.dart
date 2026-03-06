import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({
    super.key,
    required this.note,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isPinned;
  late List<String> _tags;
  late ScrollController _scrollController;
  Timer? _scrollSaveTimer;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _isPinned = widget.note.isPinned;
    _tags = List.from(widget.note.tags);
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _restoreScrollOffset();
  }

  @override
  void dispose() {
    _scrollSaveTimer?.cancel();
    _scrollController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForNote();

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
                    // Top action bar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 24),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Back',
                        ),
                        const Spacer(),

                        // Pin button
                        IconButton(
                          icon: Icon(
                            _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 20,
                          ),
                          onPressed: _togglePin,
                          tooltip: _isPinned ? 'Unpin' : 'Pin',
                          color: _isPinned ? Colors.orange : null,
                        ),

                        // Edit/Save button
                        IconButton(
                          icon: Icon(
                            _isEditing ? Icons.save : Icons.edit,
                            size: 20,
                          ),
                          onPressed: _toggleEdit,
                          tooltip: _isEditing ? 'Save' : 'Edit',
                          color: _isEditing ? Colors.green : null,
                        ),

                        // More options
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: _showOptions,
                          tooltip: 'Options',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Note metadata
                    Row(
                      children: [
                        // Type icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            widget.note.type == NoteType.checklist
                                ? Icons.checklist
                                : Icons.description,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (widget.note.gameTitle != null) ...[
                                    Icon(
                                      Icons.videogame_asset,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.note.gameTitle!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      widget.note.type == NoteType.checklist
                                          ? 'Checklist'
                                          : 'Note',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Updated ${_getRelativeTime(widget.note.updatedAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.text_fields,
                                    size: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.note.wordCount} words',
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
                    const SizedBox(height: 16),

                    // Tags
                    if (_tags.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Content area
          Expanded(
            child: _isEditing ? _buildEditView() : _buildReadView(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadView() {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(48),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              SelectableText(
                widget.note.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getColorForNote(),
                    ),
              ),
              const SizedBox(height: 32),

              // Content
              SelectableText(
                widget.note.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditView() {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(48),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title editor
              TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getColorForNote(),
                    ),
                decoration: InputDecoration(
                  hintText: 'Note title',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              const SizedBox(height: 32),

              // Content editor
              TextField(
                controller: _contentController,
                maxLines: null,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: Colors.grey.shade300,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _scrollKey {
    final id = widget.note.id;
    if (id == null) return null;
    return 'notes.scroll.$id';
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
      if (target > 0) {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _handleScroll() {
    final key = _scrollKey;
    if (key == null) return;
    final offset = _scrollController.offset;

    _scrollSaveTimer?.cancel();
    _scrollSaveTimer = Timer(const Duration(milliseconds: 200), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, offset);
    });
  }

  Color _getColorForNote() {
    if (_isPinned) return Colors.orange;
    if (widget.note.type == NoteType.checklist) return Colors.cyan;
    return Colors.blue;
  }

  String _getRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _togglePin() {
    setState(() {
      _isPinned = !_isPinned;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPinned ? 'Note pinned' : 'Note unpinned'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.orange.shade700,
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
    if (!_isEditing) {
      // Save changes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note saved'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.label, color: Colors.blue),
              title: const Text('Manage Tags'),
              onTap: () {
                Navigator.pop(context);
                _manageTags();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videogame_asset, color: Colors.purple),
              title: const Text('Link to Game'),
              subtitle: widget.note.gameTitle != null
                  ? Text(widget.note.gameTitle!)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _linkToGame();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.cyan),
              title: const Text('Export Note'),
              onTap: () {
                Navigator.pop(context);
                _exportNote();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Note'),
              onTap: () {
                Navigator.pop(context);
                _deleteNote();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _manageTags() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manage tags (coming soon)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _linkToGame() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link to game (coming soon)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export note (coming soon)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Note deleted'),
                  backgroundColor: Colors.red.shade700,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
