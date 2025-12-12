import 'dart:async';
import '../domain/note_model.dart';
import '../../auth/data/auth_repository.dart';
import '../../notes/data/notes_repository.dart';

class MockNotesRepository implements NotesRepository {
  final AuthRepository _authRepository;
  final _notesController = StreamController<List<Note>>.broadcast();
  final List<Note> _notes = [];

  MockNotesRepository(this._authRepository) {
    // Generate some dummy notes
    _notes.addAll([
      Note(
        id: '1',
        title: 'Welcome to Notes App',
        content: 'This is a sample note to get you started.',
        createdAt: DateTime.now(),
        isDone: false,
        isFavorite: false,
        tags: ['welcome'],
        creatorId: 'mock_user_123',
        imageUrls: [],
      ),
      Note(
        id: '2',
        title: 'Ideas',
        content: '1. Build a cool app\n2. Use Flutter\n3. Profit?',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isDone: false,
        isFavorite: true,
        tags: ['ideas'],
        creatorId: 'mock_user_123',
        imageUrls: [],
      ),
    ]);
  }

  @override
  Future<void> addNote(Note note) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newNote =
        note.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    _notes.insert(0, newNote);
    _notesController.add(List.from(_notes));
  }

  @override
  Future<void> updateNote(Note note) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      _notesController.add(List.from(_notes));
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _notes.removeWhere((n) => n.id == noteId);
    _notesController.add(List.from(_notes));
  }

  @override
  Stream<List<Note>> getNotesStream() {
    // Return current notes immediately
    return _notesController.stream.startWith(List.from(_notes));
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

// Extension to start stream with value (rxdart style but simple here)
extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T value) {
    return Stream.value(value).concatWith([this]);
  }
}

extension StreamConcatWith<T> on Stream<T> {
  Stream<T> concatWith(Iterable<Stream<T>> other) async* {
    yield* this;
    for (final stream in other) {
      yield* stream;
    }
  }
}
