import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/notes_repository.dart';
import '../../auth/data/auth_repository.dart';
import 'note_search_delegate.dart';
import 'widgets/staggered_note_card.dart';
import '../../../../core/theme/theme_provider.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = ref.watch(notesStreamProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (user != null)
                  Text(
                    user.displayName ?? user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode),
                onPressed: () => ref.read(themeProvider.notifier).toggle(),
                tooltip: 'Toggle Theme',
              ),
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort by',
                onSelected: (value) {
                  final notifier = ref.read(sortOptionProvider.notifier);
                  final descNotifier =
                      ref.read(sortDescendingProvider.notifier);
                  if (value == 'date_newest') {
                    notifier.set('createdAt');
                    descNotifier.set(true);
                  } else if (value == 'date_oldest') {
                    notifier.set('createdAt');
                    descNotifier.set(false);
                  } else if (value == 'title_az') {
                    notifier.set('title');
                    descNotifier.set(false);
                  } else if (value == 'title_za') {
                    notifier.set('title');
                    descNotifier.set(true);
                  }
                },
                itemBuilder: (context) {
                  final currentSort = ref.read(sortOptionProvider);
                  final isDescending = ref.read(sortDescendingProvider);

                  return [
                    PopupMenuItem(
                      value: 'date_newest',
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 20,
                            color: currentSort == 'createdAt' && isDescending
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Date (Newest First)',
                            style: TextStyle(
                              color: currentSort == 'createdAt' && isDescending
                                  ? Theme.of(context).primaryColor
                                  : null,
                              fontWeight:
                                  currentSort == 'createdAt' && isDescending
                                      ? FontWeight.bold
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'date_oldest',
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 20,
                            color: currentSort == 'createdAt' && !isDescending
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Date (Oldest First)',
                            style: TextStyle(
                              color: currentSort == 'createdAt' && !isDescending
                                  ? Theme.of(context).primaryColor
                                  : null,
                              fontWeight:
                                  currentSort == 'createdAt' && !isDescending
                                      ? FontWeight.bold
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'title_az',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            color: currentSort == 'title' && !isDescending
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Title (A-Z)',
                            style: TextStyle(
                              color: currentSort == 'title' && !isDescending
                                  ? Theme.of(context).primaryColor
                                  : null,
                              fontWeight:
                                  currentSort == 'title' && !isDescending
                                      ? FontWeight.bold
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'title_za',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            color: currentSort == 'title' && isDescending
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Title (Z-A)',
                            style: TextStyle(
                              color: currentSort == 'title' && isDescending
                                  ? Theme.of(context).primaryColor
                                  : null,
                              fontWeight: currentSort == 'title' && isDescending
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
              IconButton(
                icon: Icon(_showFavoritesOnly
                    ? Icons.favorite
                    : Icons.favorite_border),
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
          notesAsyncValue.when(
            data: (notes) {
              final filteredNotes = _showFavoritesOnly
                  ? notes.where((n) => n.isFavorite).toList()
                  : notes;

              if (filteredNotes.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_alt_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          _showFavoritesOnly
                              ? 'No favorites yet'
                              : 'Create your first note',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return StaggeredNoteCard(note: note);
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/note/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
