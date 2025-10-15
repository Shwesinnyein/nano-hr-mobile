import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  static const _kLoggedInKey = 'logged_in';
  static const _kUserId = 'user_id';
  static const _kUserToken = 'user_token';
  static const _kEmployeeId = 'employee_id';

  AuthRepository(this._authService);

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_kLoggedInKey) ?? false;
    final token = prefs.getString(_kUserToken);
    final userId = prefs.getString(_kUserId);
    final employeeId = prefs.getString(_kEmployeeId);

    // Check if we have a valid token, user ID, and employee ID
    if (isLoggedIn && token != null && userId != null && employeeId != null) {
      // Restore auth service state
      _authService.setCurrentUser(userId);
      _authService.setCurrentEmployeeId(employeeId);

      return true;
    }

    // If no valid token, clear login state
    if (!isLoggedIn || token == null) {
      await _clearLoginState();
    }

    return false;
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'] as Map<String, dynamic>;
        final userId = userData['authId'] ?? userData['id'] ?? email;
        final employeeId = userData['id'] ?? userData['uid'];
        final token =
            response['token'] ?? userData['token'] ?? userData['accessToken'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kLoggedInKey, true);
        await prefs.setString(_kUserId, userId);
        await prefs.setString(_kEmployeeId, employeeId);
        if (token != null) {
          await prefs.setString(_kUserToken, token);
        }

        // Update auth service with both user ID and employee ID
        _authService.setCurrentUser(userId);
        _authService.setCurrentEmployeeId(employeeId);
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      await _clearLoginState();
      rethrow;
    }
  }

  Future<void> loginMobile({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Starting mobile login for: $email');
      final response = await _authService.signInWithEmailAndPasswordMobile(
        email,
        password,
      );

      print('📡 Login response: $response');

      if (response['success'] == true && response['employee'] != null) {
        print('🔍 Login response employee data: ${response['employee']}');
        final userData = response['employee'] as Map<String, dynamic>;
        final userId = userData['authId'] ?? userData['id'] ?? email;
        final employeeId = userData['id'] ?? userData['uid'];
        final token =
            response['token'] ?? userData['token'] ?? userData['accessToken'];

        print('🔑 Extracted data:');
        print('  - userId: $userId');
        print('  - employeeId: $employeeId');
        print(
          '  - token: ${token != null ? '${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'null'}',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kLoggedInKey, true);
        await prefs.setString(_kUserId, userId);
        await prefs.setString(_kEmployeeId, employeeId);
        if (token != null) {
          await prefs.setString(_kUserToken, token);
          print('✅ Token stored successfully');
        } else {
          print('❌ No token to store');
        }

        // Store profile image URL
        final profileImageUrl = userData['profileImage'];
        if (profileImageUrl != null) {
          await prefs.setString('user_profile_image', profileImageUrl);
          print('🖼️ Profile image stored: $profileImageUrl');
        } else {
          print('❌ No profile image URL found');
        }

        // Update auth service with both user ID and employee ID
        _authService.setCurrentUser(userId);
        _authService.setCurrentEmployeeId(employeeId);
      } else {
        throw Exception(response['message'] ?? 'Mobile login failed');
      }
    } catch (e) {
      await _clearLoginState();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Call API to logout
      await _authService.signOut();
    } catch (e) {
    } finally {
      // Clear local login state
      await _clearLoginState();
    }
  }

  Future<String?> currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserId);
  }

  Future<String?> getCurrentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserToken);
  }

  Future<void> _clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, false);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserToken);
    await prefs.remove(_kEmployeeId);
    _authService.setCurrentUser(null);
    _authService.setCurrentEmployeeId(null);
  }
}

class AuthController extends StateNotifier<AsyncValue<bool>> {
  AuthController(this._repo) : super(const AsyncValue.loading()) {
    check();
  }
  final AuthRepository _repo;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get authStream => _controller.stream;

  Future<void> check() async {
    state = const AsyncValue.loading();
    final loggedIn = await _repo.isLoggedIn();
    state = AsyncValue.data(loggedIn);
    _controller.add(loggedIn);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.login(email: email, password: password);
      state = const AsyncValue.data(true);
      _controller.add(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginMobile(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.loginMobile(email: email, password: password);
      state = const AsyncValue.data(true);
      _controller.add(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Re-throw the exception so the UI can catch it
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(false);
    _controller.add(false);
  }

  void setLoggedIn(bool isLoggedIn) {
    state = AsyncValue.data(isLoggedIn);
    _controller.add(isLoggedIn);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authServiceProvider)),
);

final authStateProvider =
    StateNotifierProvider<AuthController, AsyncValue<bool>>(
      (ref) => AuthController(ref.watch(authRepositoryProvider)),
    );
