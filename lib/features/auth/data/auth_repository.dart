import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_user.dart';
// import 'mock_auth_repository.dart';

// Provider for the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // SWITCH HERE: Use Real Firebase Repository
  // return MockAuthRepository();
  return FirebaseAuthRepository(firebase_auth.FirebaseAuth.instance);
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
  Future<void> createUserWithEmailAndPassword(
      String email, String password, String name);
  Future<void> signOut();
}

/// Real Implementation using Firebase
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  AppUser? _mapFirebaseUser(firebase_auth.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  AppUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is not valid.';
      }
      throw 'Login failed: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  @override
  Future<void> createUserWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (name.isNotEmpty && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'This email is already registered. Please login instead.';
      } else if (e.code == 'weak-password') {
        throw 'The password is too weak.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is not valid.';
      }
      throw 'Registration failed: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
