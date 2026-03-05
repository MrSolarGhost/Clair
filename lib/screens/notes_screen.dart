import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int _selectedIndex = 0;
  String _filterTag = 'All';

  // Mock notes data
  final List<Note> _notes = [
    Note(
      id: 1,
      title: 'Elden Ring Boss Strategies',
      content: '''
Malenia Tips:
- Waterfowl Dance: Run away for first flurry, roll into second, roll away from third
- Use Bloodhound Step for easier dodging
- Frost pots interrupt her attacks
- She heals on hit even if blocked, so dodge everything
- Phase 2: Watch for the dive bomb flower attack

Margit the Fell:
- Summon Rogier outside the fog gate
- Use Margit's Shackle for easy phase 1
- Stay close to avoid his projectile spam
''',
      type: NoteType.text,
      gameTitle: 'Elden Ring',
      tags: ['bosses', 'strategies'],
      isPinned: true,
      createdDate: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Note(
      id: 2,
      title: 'Hollow Knight Completion Checklist',
      content: '''
☐ Get all Charms (40/40)
☐ Defeat all bosses including pantheons
☐ Collect all Grubs (46/46)
☐ Get all Mask Shards and Vessel Fragments
☐ Complete White Palace
☐ Beat Path of Pain
☐ Get True Ending
☐ Complete Godmaster content
''',
      type: NoteType.checklist,
      gameTitle: 'Hollow Knight',
      tags: ['completion', 'checklist'],
      isPinned: true,
      createdDate: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Note(
      id: 3,
      title: 'Games to Try Next',
      content: '''
Indie recommendations from friends:
- Outer Wilds (mystery/exploration)
- Return of the Obra Dinn (detective)
- Disco Elysium (RPG/story)
- Tunic (Zelda-like with secrets)
- SOMA (horror/story)

Current mood: Something cozy and relaxing
Maybe: Stardew Valley, A Short Hike, Unpacking
''',
      type: NoteType.text,
      tags: ['recommendations', 'backlog'],
      isPinned: false,
      createdDate: DateTime.now().subtract(const Duration(days: 8)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Note(
      id: 4,
      title: 'Celeste B-Sides Progress',
      content: '''
Completed B-Sides:
✓ Forsaken City
✓ Old Site
✓ Celestial Resort
✓ Golden Ridge
- Mirror Temple (stuck on last screen)
- Reflection (haven't started)
- The Summit (haven't started)

Current deaths: 2,847
Best time: Forsaken City B-Side in 4:23
''',
      type: NoteType.text,
      gameTitle: 'Celeste',
      tags: ['progress', 'speedrun'],
      isPinned: false,
      createdDate: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    Note(
      id: 5,
      title: 'Hades Build Ideas',
      content: '''
Zeus + Poseidon combo:
- Sea Storm is amazing for clearing
- Get Splitting Bolt from Zeus
- Lightning Rod for boss DPS
- Works best with Rail or Bow

Artemis Crit Build:
- Pressure Points from Artemis
- Hunter's Mark for bosses
- Duo with Aphrodite for heart rend
- Best with Chiron Bow
''',
      type: NoteType.text,
      gameTitle: 'Hades',
      tags: ['builds', 'strategies'],
      isPinned: false,
      createdDate: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Note(
      id: 6,
      title: 'Couch Co-op Games',
      content: '''
Great local multiplayer games:
- It Takes Two (2p, must play!)
- Overcooked 2 (up to 4p)
- A Way Out (2p story)
- Cuphead (2p run & gun)
- Divinity Original Sin 2 (up to 4p RPG)
- Moving Out (up to 4p chaos)

Next game night: Try It Takes Two
''',
      type: NoteType.text,
      tags: ['multiplayer', 'recommendations'],
      isPinned: false,
      createdDate: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  List<String> get _allTags {
    final tags = <String>{'All'};
    for (var note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  List<Note> get _filteredNotes {
    if (_filterTag == 'All') {
      return _notes;
    }
    return _notes.where((note) => note.tags.contains(_filterTag)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Sort by pinned first, then by updated date
    final sortedNotes = List<Note>.from(_filteredNotes)
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
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
                    'Notes',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sortedNotes.length} notes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              // New note button
              ElevatedButton.icon(
                onPressed: _createNewNote,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tag filters
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _allTags.length,
              itemBuilder: (context, index) {
                final tag = _allTags[index];
                final isSelected = tag == _filterTag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _filterTag = tag);
                    },
                    backgroundColor: const Color(0xFF1A1A1A),
                    selectedColor: Colors.orange.withValues(alpha: 0.3),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.orange
                          : Colors.grey.shade800,
                      width: 1,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.orange
                          : Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Notes grid
          Expanded(
            child: Focus(
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: sortedNotes.length,
                itemBuilder: (context, index) {
                  final note = sortedNotes[index];
                  final isSelected = index == _selectedIndex;
                  return _buildNoteCard(note, isSelected);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note, bool isSelected) {
    final color = _getColorForNote(note);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = _filteredNotes.indexOf(note));
        _openNote(note);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
            // Header row
            Row(
              children: [
                // Pin indicator
                if (note.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: Colors.orange,
                    ),
                  ),
                // Note type icon
                Icon(
                  note.type == NoteType.checklist
                      ? Icons.checklist
                      : Icons.description,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                // Game association
                if (note.gameTitle != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.videogame_asset,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            note.gameTitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              note.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Content preview
            Expanded(
              child: Text(
                note.preview,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tags
                if (note.tags.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: note.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 9,
                              color: color,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                // Updated time
                Text(
                  _getRelativeTime(note.updatedAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForNote(Note note) {
    if (note.isPinned) return Colors.orange;
    if (note.type == NoteType.checklist) return Colors.cyan;
    return Colors.blue;
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

    final itemsPerRow = 3;
    final totalItems = _filteredNotes.length;

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
      final sortedNotes = List<Note>.from(_filteredNotes)
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
      _openNote(sortedNotes[_selectedIndex]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _openNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
  }

  void _createNewNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Create Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Text Note'),
              subtitle: const Text('Create a freeform text note'),
              onTap: () {
                Navigator.pop(context);
                _createTextNote();
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist, color: Colors.cyan),
              title: const Text('Checklist'),
              subtitle: const Text('Create a task checklist'),
              onTap: () {
                Navigator.pop(context);
                _createChecklist();
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

  void _createTextNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Create text note (coming soon)'),
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _createChecklist() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Create checklist (coming soon)'),
        backgroundColor: Colors.cyan.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
