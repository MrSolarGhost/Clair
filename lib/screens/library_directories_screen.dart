import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/library_directory.dart';
import '../services/library_directory_service.dart';

class LibraryDirectoriesScreen extends StatefulWidget {
  const LibraryDirectoriesScreen({super.key});

  @override
  State<LibraryDirectoriesScreen> createState() =>
      _LibraryDirectoriesScreenState();
}

class _LibraryDirectoriesScreenState extends State<LibraryDirectoriesScreen> {
  final LibraryDirectoryService _service = LibraryDirectoryService();
  List<LibraryDirectory> _directories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectories();
  }

  Future<void> _loadDirectories() async {
    setState(() => _isLoading = true);
    final dirs = await _service.getAllDirectories();
    setState(() {
      _directories = dirs;
      _isLoading = false;
    });
  }

  Future<void> _addDirectory() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddDirectoryDialog(),
    );

    if (result != null) {
      try {
        await _service.addDirectory(
          result['path'],
          result['system'],
          result['recursive'],
        );
        _loadDirectories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Directory added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _refreshDirectory(LibraryDirectory dir) async {
    try {
      await _service.refreshDirectory(dir.id!);
      _loadDirectories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Directory refreshed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeDirectory(LibraryDirectory dir) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Directory?'),
        content: Text(
          'Remove ${dir.path}?\n\nGames from this directory will remain in your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.removeDirectory(dir.id!);
      _loadDirectories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Directory removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Directories'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton.icon(
                  onPressed: _addDirectory,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Directory'),
                ),
                const SizedBox(height: 24),
                ..._directories.map((dir) => Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dir.system,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(dir.path),
                            const SizedBox(height: 4),
                            Text(
                              'Subdirectories: ${dir.scanRecursive ? "Yes" : "No"}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (dir.lastScannedAt != null)
                              Text(
                                'Last scanned: ${_formatDate(dir.lastScannedAt!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _refreshDirectory(dir),
                                  child: const Text('Refresh'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _removeDirectory(dir),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.month}/${date.day}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class AddDirectoryDialog extends StatefulWidget {
  const AddDirectoryDialog({super.key});

  @override
  State<AddDirectoryDialog> createState() => _AddDirectoryDialogState();
}

class _AddDirectoryDialogState extends State<AddDirectoryDialog> {
  String? _selectedPath;
  String _selectedSystem = 'PC (Windows)';
  bool _scanRecursive = true;

  final List<String> _systems = [
    'PC (Windows)',
    'PC (Linux)',
    'PC (Mac)',
    'Steam',
    'GOG',
    'Epic Games',
    'PlayStation Vita',
    'Nintendo 3DS',
    'Nintendo Switch',
    'GameCube',
    'Wii',
    'PlayStation 2',
    'Xbox',
    'Xbox 360',
  ];

  Future<void> _pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => _selectedPath = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Directory'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickDirectory,
              icon: const Icon(Icons.folder),
              label: const Text('Select Directory'),
            ),
            if (_selectedPath != null) ...[
              const SizedBox(height: 8),
              Text(_selectedPath!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSystem,
              decoration: const InputDecoration(labelText: 'Platform'),
              items: _systems
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSystem = value);
                }
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Include subdirectories'),
              value: _scanRecursive,
              onChanged: (value) {
                setState(() => _scanRecursive = value ?? true);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedPath != null
              ? () {
                  Navigator.of(context).pop({
                    'path': _selectedPath,
                    'system': _selectedSystem,
                    'recursive': _scanRecursive,
                  });
                }
              : null,
          child: const Text('Scan & Import'),
        ),
      ],
    );
  }
}
