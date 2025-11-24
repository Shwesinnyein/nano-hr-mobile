import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/push_notification_service.dart';

class AuthRepository {
  final AuthService _authService;
  final PushNotificationService _pushNotificationService;
  static const _kLoggedInKey = 'logged_in';
  static const _kUserId = 'user_id';
  static const _kUserToken = 'user_token';
  static const _kEmployeeId = 'employee_id';
  static const _kEmployeeName = 'employee_name';
  static const _kEmployeeFirstName = 'employee_first_name';
  static const _kEmployeeLastName = 'employee_last_name';
  static const _kPositionName = 'position_name';

  AuthRepository(this._authService, this._pushNotificationService);

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_kLoggedInKey) ?? false;
    final token = prefs.getString(_kUserToken);
    final userId = prefs.getString(_kUserId);
    final employeeId = prefs.getString(_kEmployeeId);

    if (isLoggedIn && token != null && userId != null && employeeId != null) {
     
      _authService.setCurrentUser(userId);
      _authService.setCurrentEmployeeId(employeeId);

      
      final firstName = prefs.getString(_kEmployeeFirstName);
      final lastName = prefs.getString(_kEmployeeLastName);
      final positionName = prefs.getString(_kPositionName);
      _authService.setCurrentEmployeeName(firstName, lastName, positionName);

      
      await _pushNotificationService.initialize();

      return true;
    }

    
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

        
        _authService.setCurrentUser(userId);
        _authService.setCurrentEmployeeId(employeeId);

        try {
          await _pushNotificationService.initialize();
        } catch (e) {
          
        }
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
      final response = await _authService.signInWithEmailAndPasswordMobile(
        email,
        password,
      );

      if (response['success'] == true && response['employee'] != null) {
        final userData = response['employee'] as Map<String, dynamic>;
        final userId = userData['authId'] ?? userData['id'] ?? email;
        final employeeId = userData['id'] ?? userData['uid'];
        final token =
            response['token'] ?? userData['token'] ?? userData['accessToken'];

        
        final firstName = userData['firstName'] ?? userData['first_name'];
        final lastName = userData['lastName'] ?? userData['last_name'];
        final positionName =
            userData['positionName'] ??
            userData['position_name'] ??
            userData['jobTitle'] ??
            userData['job_title'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kLoggedInKey, true);
        await prefs.setString(_kUserId, userId);
        await prefs.setString(_kEmployeeId, employeeId);
        if (token != null) {
          await prefs.setString(_kUserToken, token);
        }

        
        final profileImageUrl = userData['profileImage'];
        if (profileImageUrl != null) {
          await prefs.setString('user_profile_image', profileImageUrl);
        }

        
        if (firstName != null) {
          await prefs.setString(_kEmployeeFirstName, firstName);
        }
        if (lastName != null) {
          await prefs.setString(_kEmployeeLastName, lastName);
        }
        if (positionName != null) {
          await prefs.setString(_kPositionName, positionName);
        }

        
        _authService.setCurrentUser(userId);
        _authService.setCurrentEmployeeId(employeeId);
        _authService.setCurrentEmployeeName(firstName, lastName, positionName);

        try {
          await _pushNotificationService.initialize();
        } catch (e) {
          
        }
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
      
      await _authService.signOut();
    } catch (e) {
    } finally {

      
      
      await _clearLoginState();

      await _clearUserSpecificCaches();
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

    const fcmTokenKey = 'fcm_device_token';
    final fcmToken = prefs.getString(fcmTokenKey);

    await prefs.clear();

    if (fcmToken != null && fcmToken.isNotEmpty) {
      await prefs.setString(fcmTokenKey, fcmToken);
    }

    _authService.setCurrentUser(null);
    _authService.setCurrentEmployeeId(null);
    _authService.setCurrentEmployeeName(null, null, null);
  } 

  Future<void> _clearUserSpecificCaches() async {
   
    try {
     
    } catch (e) {
     
    }
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
      rethrow; 
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
  (ref) => AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(pushNotificationServiceProvider),
  ),
);

final authStateProvider =
    StateNotifierProvider<AuthController, AsyncValue<bool>>(
      (ref) => AuthController(ref.watch(authRepositoryProvider)),
    );
