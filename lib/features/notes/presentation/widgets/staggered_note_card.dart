import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/note_model.dart';
import '../../data/notes_repository.dart';
import '../../../../core/utils/delete_dialog.dart';

class StaggeredNoteCard extends ConsumerWidget {
  final Note note;

  const StaggeredNoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDefaultColor = note.color == 0xFFFFFFFF;

    // In Dark Mode, default notes use a lighter surface color to stand out from background.
    // In Light Mode, they are white.
    // Colored notes (pastels) keep their color.
    final bgColor = isDefaultColor
        ? (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
        : Color(note.color);

    final textColor = isDefaultColor ? null : Colors.black87;
    final secondaryTextColor = isDefaultColor
        ? Theme.of(context).textTheme.bodySmall?.color
        : Colors.black54;

    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: (isDefaultColor && !isDarkMode)
            ? BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withOpacity(0.5))
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/note/${note.id}', extra: note),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview at the Top
            if (note.imageUrls.isNotEmpty)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Builder(builder: (context) {
                  final path = note.imageUrls.first;
                  if (kIsWeb || path.startsWith('http')) {
                    return Image.network(
                      path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[200]),
                    );
                  } else {
                    return Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[200]),
                    );
                  }
                }),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    decoration: note.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: note.isDone
                                        ? secondaryTextColor
                                        : textColor,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => ref
                            .read(notesRepositoryProvider)
                            .toggleFavorite(note),
                        child: Icon(
                          note.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: note.isFavorite
                              ? Colors.red
                              : (isDefaultColor ? Colors.grey : Colors.black45),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_vert,
                            size: 18,
                            color:
                                isDefaultColor ? Colors.grey : Colors.black45),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            final confirm =
                                await showDeleteConfirmation(context);
                            if (confirm) {
                              await ref
                                  .read(notesRepositoryProvider)
                                  .deleteNote(note.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Note deleted'),
                                    backgroundColor: Colors.red,
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        ref
                                            .read(notesRepositoryProvider)
                                            .addNote(note);
                                      },
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (note.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      note.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                            height: 1.5,
                            fontSize: 14,
                          ),
                    ),
                  ],
                  if (note.dueDate != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.event,
                            size: 12,
                            color: (secondaryTextColor ?? Colors.black54)
                                .withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(note.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: (secondaryTextColor ?? Colors.black54)
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
