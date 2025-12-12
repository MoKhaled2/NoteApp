import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/notes_repository.dart';
import '../domain/note_model.dart';
import '../../auth/data/auth_repository.dart';
import 'note_search_delegate.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  // TODO: Add filter state here (All, Favorites, etc.)
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = ref.watch(notesStreamProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Notes'),
            if (user != null)
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ref.read(notesStreamProvider).whenData((notes) {
                showSearch(
                  context: context,
                  delegate: NoteSearchDelegate(notes),
                );
              });
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: Icon(
                _showFavoritesOnly ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
            tooltip: 'Filter Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: notesAsyncValue.when(
        data: (notes) {
          final filteredNotes = _showFavoritesOnly
              ? notes.where((n) => n.isFavorite).toList()
              : notes;

          if (filteredNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    _showFavoritesOnly
                        ? 'No favorites yet'
                        : 'Create your first note',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return _NoteCard(note: note);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/note/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/note/${note.id}', extra: note),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            decoration:
                                note.isDone ? TextDecoration.lineThrough : null,
                            color: note.isDone
                                ? Theme.of(context).colorScheme.outline
                                : null,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      note.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: note.isFavorite
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    onPressed: () {
                      ref.read(notesRepositoryProvider).toggleFavorite(note);
                    },
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (note.dueDate != null)
                    Chip(
                      label: Text(
                        DateFormat('MMM d').format(note.dueDate!),
                        style: const TextStyle(fontSize: 12),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  const Spacer(),
                  Checkbox(
                      value: note.isDone,
                      onChanged: (_) {
                        ref.read(notesRepositoryProvider).toggleDone(note);
                      }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
