import 'dart:async';
import '../domain/app_user.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;
  final _authStateController = StreamController<AppUser?>.broadcast();

  MockAuthRepository() {
    // Start with no user or check shared prefs if we were fancy
    _currentUser = null;
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    _currentUser = AppUser(uid: 'mock_user_123', email: email);
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> createUserWithEmailAndPassword(
      String email, String password, String name) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    _currentUser = AppUser(uid: 'mock_user_123', email: email);
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
  }
}
