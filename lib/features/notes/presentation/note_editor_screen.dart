import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../domain/note_model.dart';
import '../data/notes_repository.dart';
import '../../auth/data/auth_repository.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final Note? note;

  const NoteEditorScreen({super.key, this.noteId, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime? _dueDate;
  late List<String> _tags;
  late List<String> _imageUrls; // In a real app, these would be uploaded URLs. For now we might store local paths if testing locally, but Firestore needs remote URLs. 
  // We will assume for this MVP we just store the path string, but practically we'd need Firebase Storage upload.
  // I will implement the UI for picking, but maybe comment out the actual upload to Keep it simple for now, or just store the path.
  
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    _isNew = widget.noteId == 'new';
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _dueDate = widget.note?.dueDate;
    _tags = List.from(widget.note?.tags ?? []);
    _imageUrls = List.from(widget.note?.imageUrls ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final note = Note(
      id: _isNew ? const Uuid().v4() : widget.noteId!,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      isDone: widget.note?.isDone ?? false,
      isFavorite: widget.note?.isFavorite ?? false,
      tags: _tags,
      createdAt: _isNew ? DateTime.now() : widget.note!.createdAt,
      dueDate: _dueDate,
      creatorId: user.uid,
      assignedToId: widget.note?.assignedToId,
      imageUrls: _imageUrls,
    );

    try {
      if (widget.noteId == 'new') {
        await ref.read(notesRepositoryProvider).addNote(note);
      } else {
        await ref.read(notesRepositoryProvider).updateNote(note);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    }
  }
  
  Future<void> _deleteNote() async {
    if (_isNew) {
      context.pop();
      return;
    }
    await ref.read(notesRepositoryProvider).deleteNote(widget.noteId!);
    if (mounted) context.pop();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      // TODO: Upload to Firebase Storage here and get URL.
      // For now, we'll just add the local path as a placeholder for the UI.
      setState(() {
        _imageUrls.add(image.path); 
      });
    }
  }

  Future<void> _shareNote() async {
    final text = '${_titleController.text}\n\n${_contentController.text}';
    if (_imageUrls.isNotEmpty) {
      // Share with files
      final files = _imageUrls.map((path) => XFile(path)).toList();
      await Share.shareXFiles(files, text: text);
    } else {
      await Share.share(text);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareNote,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Note?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) _deleteNote();
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: () => _pickImage(ImageSource.gallery),
              tooltip: 'Add Image',
            ),
             IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: () => _pickImage(ImageSource.camera),
              tooltip: 'Take Photo',
            ),
            IconButton(
              icon: const Icon(Icons.event_outlined),
              onPressed: _pickDate,
              tooltip: 'Set Date',
            ),
            // Tag icon could go here
            if (_dueDate != null)
              Chip(
                label: Text(DateFormat('MM/dd/yyyy').format(_dueDate!)),
                onDeleted: () => setState(() => _dueDate = null),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) {
                    final path = _imageUrls[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file( // Using Image.file since we stored local path
                              File(path), 
                              height: 200, 
                              width: 200, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if it was a remote URL in real app
                                return Container(
                                  height: 200,
                                  width: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: InkWell(
                              onTap: () => setState(() => _imageUrls.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),
             TextField(
              controller: _contentController,
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Start typing...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
