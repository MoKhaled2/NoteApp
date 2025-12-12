import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../notes/domain/note_model.dart';

class NoteSearchDelegate extends SearchDelegate {
  final List<Note> notes;

  NoteSearchDelegate(this.notes);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final results = notes.where((note) {
      final titleLower = note.title.toLowerCase();
      final contentLower = note.content.toLowerCase();
      final queryLower = query.toLowerCase();
      return titleLower.contains(queryLower) || contentLower.contains(queryLower);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return ListTile(
          title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: note.content.isNotEmpty 
              ? Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis) 
              : null,
          onTap: () {
            close(context, null);
            context.go('/note/${note.id}', extra: note);
          },
        );
      },
    );
  }
}
