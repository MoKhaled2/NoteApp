import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/notes/presentation/notes_list_screen.dart';
import '../../features/notes/presentation/note_editor_screen.dart';
import '../../features/notes/domain/note_model.dart';

// Simple provider for the router
// ده بيساعد في ال auth redirect
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login', // Start at login for now
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const NotesListScreen(),
        routes: [
           GoRoute(
            path: 'note/new',
            builder: (context, state) => const NoteEditorScreen(noteId: 'new'),
          ),
          GoRoute(
            path: 'note/:id',
            builder: (context, state) {
              final noteId = state.pathParameters['id'];
              final note = state.extra as Note?;
              return NoteEditorScreen(noteId: noteId, note: note);
            },
          ),
        ]
      ),
      // Fallback or explicit login route if needed, usually handled by redirect logic
    ],
  );
});
