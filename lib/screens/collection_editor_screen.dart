import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/collection.dart';
import '../services/collections_service.dart';

class CollectionEditorScreen extends StatefulWidget {
  final Collection? collection;

  const CollectionEditorScreen({super.key, this.collection});

  @override
  State<CollectionEditorScreen> createState() => _CollectionEditorScreenState();
}

class _CollectionEditorScreenState extends State<CollectionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final CollectionsService _collectionsService = CollectionsService();

  String? _coverPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) {
      _nameController.text = widget.collection!.name;
      _descriptionController.text = widget.collection!.description ?? '';
      _coverPath = widget.collection!.coverPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _coverPath = result.files.single.path;
        });
      }
    } catch (_) {
      // Silent error handling
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.collection == null) {
        // Create new collection
        await _collectionsService.createCollection(
          Collection(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            coverPath: _coverPath,
            createdAt: DateTime.now(),
            gameCount: 0,
          ),
        );
      } else {
        // Update existing collection
        final updated = Collection(
          id: widget.collection!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          coverPath: _coverPath,
          createdAt: widget.collection!.createdAt,
          gameCount: widget.collection!.gameCount,
        );
        await _collectionsService.updateCollection(updated);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      // Silent error handling
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.collection?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: const Text(
          'Are you sure you want to delete this collection? Games will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _collectionsService.deleteCollection(widget.collection!.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      // Silent error handling
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.collection != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Collection' : 'New Collection'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _delete,
              tooltip: 'Delete collection',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover image picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickCover,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade800,
                              width: 2,
                            ),
                          ),
                          child: _coverPath != null && _coverPath!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_coverPath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Cover',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Collection Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEdit ? 'Save Changes' : 'Create Collection'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
