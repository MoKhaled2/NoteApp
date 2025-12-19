import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../domain/note_model.dart';
import '../data/notes_repository.dart';
import '../../../../core/utils/delete_dialog.dart';
import '../../auth/data/auth_repository.dart';
import 'widgets/note_color_picker.dart';

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
  late List<String>
      _imageUrls; // In a real app, these would be uploaded URLs. For now we might store local paths if testing locally, but Firestore needs remote URLs.
  // We will assume for this MVP we just store the path string, but practically we'd need Firebase Storage upload.
  // I will implement the UI for picking, but maybe comment out the actual upload to Keep it simple for now, or just store the path.

  bool _isNew = true;
  int _selectedColor = 0xFFFFFFFF; // Default white

  @override
  void initState() {
    super.initState();
    _isNew = widget.noteId == 'new';
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _dueDate = widget.note?.dueDate;
    _tags = List.from(widget.note?.tags ?? []);
    _imageUrls = List.from(widget.note?.imageUrls ?? []);
    _selectedColor = widget.note?.color ?? 0xFFFFFFFF;
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
      color: _selectedColor,
    );

    try {
      if (widget.noteId == 'new') {
        await ref.read(notesRepositoryProvider).addNote(note);
      } else {
        await ref.read(notesRepositoryProvider).updateNote(note);
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    }
  }

  Future<void> _deleteNote() async {
    if (_isNew) {
      context.pop();
      return;
    }

    final repo = ref.read(notesRepositoryProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Call custom dialog
    final confirm = await showDeleteConfirmation(context);
    if (!confirm) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final noteToDelete = Note(
      id: widget.noteId!,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      isDone: widget.note?.isDone ?? false,
      isFavorite: widget.note?.isFavorite ?? false,
      tags: _tags,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      dueDate: _dueDate,
      creatorId: user.uid,
      assignedToId: widget.note?.assignedToId,
      imageUrls: _imageUrls,
      color: _selectedColor,
    );

    await repo.deleteNote(widget.noteId!);

    if (mounted) {
      context.pop();
    }

    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Note deleted'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            repo.addNote(noteToDelete);
          },
        ),
      ),
    );
      Future.delayed(const Duration(seconds: 3), () {
        scaffoldMessenger.hideCurrentSnackBar();
      });
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

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 100,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: NoteColorPicker(
            selectedColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDefaultColor = _selectedColor == 0xFFFFFFFF;
    final bgColor =
        isDefaultColor ? colorScheme.surface : Color(_selectedColor);

    // Determine icon colors based on background
    final iconColor = isDefaultColor ? colorScheme.onSurface : Colors.black87;
    final textColor = isDefaultColor ? colorScheme.onSurface : Colors.black87;
    final hintColor = isDefaultColor
        ? colorScheme.onSurface.withOpacity(0.5)
        : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () {
            if (_titleController.text.isNotEmpty ||
                _contentController.text.isNotEmpty) {
              _saveNote();
            } else {
              context.pop();
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_outlined, color: iconColor),
            onPressed: _shareNote,
            tooltip: 'Share',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: iconColor),
            onPressed: _deleteNote,
            tooltip: 'Delete',
          ),
          IconButton(
            icon: Icon(Icons.check_rounded, color: iconColor),
            onPressed: _saveNote,
            tooltip: 'Save',
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: bgColor, // Match background
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.palette_outlined, color: iconColor),
                onPressed: _showColorPicker,
                tooltip: 'Color',
              ),
              IconButton(
                icon: Icon(Icons.image_outlined, color: iconColor),
                onPressed: () => _pickImage(ImageSource.gallery),
                tooltip: 'Image',
              ),
              IconButton(
                icon: Icon(Icons.camera_alt_outlined, color: iconColor),
                onPressed: () => _pickImage(ImageSource.camera),
                tooltip: 'Camera',
              ),
              IconButton(
                icon: Icon(Icons.event_outlined, color: iconColor),
                onPressed: _pickDate,
                tooltip: 'Reminder',
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDefaultColor
                              ? colorScheme.surfaceContainerHighest
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event,
                                size: 16, color: iconColor.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMMM d, yyyy').format(_dueDate!),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setState(() => _dueDate = null),
                              child: Icon(Icons.close,
                                  size: 16, color: iconColor.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Image Gallery
              if (_imageUrls.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageUrls.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final path = _imageUrls[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? Image.network(
                                    path,
                                    height: 220,
                                    width:
                                        220, // Square aspect for cleaner look
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        Container(
                                            height: 220,
                                            width: 220,
                                            color: Colors.black12,
                                            child: const Icon(Icons.error)),
                                  )
                                : Image.file(
                                    File(path),
                                    height: 220,
                                    width: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 220,
                                        width: 220,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _imageUrls.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              if (_imageUrls.isNotEmpty) const SizedBox(height: 24),

              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.6,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Type something...',
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
