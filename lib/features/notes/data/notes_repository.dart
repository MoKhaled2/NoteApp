import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/note_model.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/data/auth_repository.dart';
import 'mock_notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  // SWITCH HERE: Use MockNotesRepository
  return MockNotesRepository(ref.watch(authRepositoryProvider));
  // return FirestoreNotesRepository(FirebaseFirestore.instance, ref);
});

final notesStreamProvider = StreamProvider<List<Note>>((ref) {
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
        .add(note.toMap());
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
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Note.fromDocument(doc)).toList());
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
