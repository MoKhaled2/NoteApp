import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/note_model.dart';
import '../../auth/data/auth_repository.dart';
// import 'mock_notes_repository.dart';

class SortOptionNotifier extends Notifier<String> {
  @override
  String build() => 'createdAt';
  void set(String value) => state = value;
}

final sortOptionProvider =
    NotifierProvider<SortOptionNotifier, String>(SortOptionNotifier.new);

class SortDescendingNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

final sortDescendingProvider =
    NotifierProvider<SortDescendingNotifier, bool>(SortDescendingNotifier.new);

class NotesRefreshTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

final notesRefreshTriggerProvider =
    NotifierProvider<NotesRefreshTriggerNotifier, int>(
        NotesRefreshTriggerNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  // SWITCH HERE: Use Real Firestore Repository
  // return MockNotesRepository(ref.watch(authRepositoryProvider));
  return FirestoreNotesRepository(FirebaseFirestore.instance, ref);
});

final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  ref.watch(authStateProvider); // Force rebuild on auth change
  return ref.watch(notesRepositoryProvider).getNotesStream();
});

abstract class NotesRepository {
  Future<void> addNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String noteId);
  Stream<List<Note>> getNotesStream();
  Future<void> toggleFavorite(Note note);
  Future<void> toggleDone(Note note);
}

class FirestoreNotesRepository implements NotesRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  FirestoreNotesRepository(this._firestore, this._ref);

  @override
  Future<void> addNote(Note note) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(note.id)
        .set(note.toMap());
    _ref.read(notesRefreshTriggerProvider.notifier).refresh();
  }

  @override
  Future<void> updateNote(Note note) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(note.id)
        .update(note.toMap());
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  @override
  Stream<List<Note>> getNotesStream() {
    final user = _ref.watch(authRepositoryProvider).currentUser;
    final sortBy = _ref.watch(sortOptionProvider);
    final descending = _ref.watch(sortDescendingProvider);
    final searchQuery =
        _ref.watch(searchQueryProvider).toLowerCase(); // Watch search query

    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .orderBy(sortBy, descending: descending)
        .snapshots()
        .map((snapshot) {
      final notes = snapshot.docs.map((doc) => Note.fromDocument(doc)).toList();

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        return notes.where((note) {
          final title = note.title.toLowerCase();
          final content = note.content.toLowerCase();
          return title.contains(searchQuery) || content.contains(searchQuery);
        }).toList();
      }

      return notes;
    });
  }

  @override
  Future<void> toggleFavorite(Note note) async {
    await updateNote(note.copyWith(isFavorite: !note.isFavorite));
  }

  @override
  Future<void> toggleDone(Note note) async {
    await updateNote(note.copyWith(isDone: !note.isDone));
  }
}
