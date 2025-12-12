import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_user.dart';
import 'mock_auth_repository.dart';

// Provider for the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // SWITCH HERE: Use MockAuthRepository for now
  return MockAuthRepository();
  // return FirebaseAuthRepository(firebase_auth.FirebaseAuth.instance);
});

// Stream provider for auth state changes
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Abstract Interface for Authentication
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
}

/// Real Implementation using Firebase
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  AppUser? _mapFirebaseUser(firebase_auth.User? user) {
    if (user == null) return null;
    return AppUser(uid: user.uid, email: user.email ?? '');
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  AppUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> createUserWithEmailAndPassword(
      String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
