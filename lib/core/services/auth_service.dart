import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import 'firebase_auth_service.dart';

class AuthService {
  final ApiClient _apiClient;
  final FirebaseAuthService _firebaseAuth;
  String? _currentUserId;

  AuthService(this._apiClient, this._firebaseAuth);

  // Get current user
  String? get currentUserId => _currentUserId;

  // Set current user (for internal use)
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  // Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;

  // Auth state stream
  Stream<String?> get authStateChanges => Stream.value(_currentUserId);

  // Sign in with email and password using Firebase
  Future<ApiResponse<Map<String, dynamic>>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔄 AuthService: Starting Firebase authentication');

      // First, authenticate with Firebase
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential.user == null) {
        throw Exception('Firebase authentication failed');
      }

      // Get the ID token from Firebase
      final idToken = await userCredential.user!.getIdToken();
      print('✅ AuthService: Got Firebase ID token');

      // Try to send the ID token to your backend for verification
      try {
        final response = await _apiClient.post(
          ApiEndpoints.login,
          data: {'idToken': idToken},
          options: Options(headers: {'Authorization': 'Bearer $idToken'}),
        );

        final apiResponse = ApiResponse.fromJson(
          response.data,
          (data) => data as Map<String, dynamic>,
        );

        if (apiResponse.success) {
          _currentUserId = userCredential.user!.uid;
          print('✅ AuthService: Backend verification successful');

          // Return a successful response with user data
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: 'Login successful',
            data: {
              'userId': userCredential.user!.uid,
              'email': userCredential.user!.email,
              'token': idToken,
            },
          );
        } else {
          // If backend verification fails, sign out from Firebase
          await _firebaseAuth.signOut();
          throw Exception(apiResponse.message ?? 'Backend verification failed');
        }
      } catch (backendError) {
        // If backend is not available, proceed with Firebase-only authentication
        print(
          '⚠️ Backend not available, proceeding with Firebase authentication: $backendError',
        );
        _currentUserId = userCredential.user!.uid;

        // Return a successful response with user data
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: 'Login successful (Firebase only)',
          data: {
            'userId': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'token': idToken,
          },
        );
      }
    } catch (e) {
      print('❌ AuthService: Authentication error: $e');
      // Make sure to sign out from Firebase if there's an error
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Register with email and password
  Future<ApiResponse<Map<String, dynamic>>> registerWithEmailAndPassword(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Send user data to backend
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {'email': email, 'password': password, 'userData': userData},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.success) {
        _currentUserId = apiResponse.data?['userId'] ?? 'demo_user';
      }

      return apiResponse;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from backend (optional)
      try {
        await _apiClient.post(ApiEndpoints.logout);
      } catch (e) {
        print('⚠️ Backend logout failed: $e');
        // Continue with logout even if backend fails
      }

      // Clear local user
      _currentUserId = null;
      print('✅ AuthService: Sign out successful');
    } catch (e) {
      // Even if logout fails, clear local user
      _currentUserId = null;
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _apiClient.post(
        ApiEndpoints.refreshToken, // Use appropriate endpoint
        data: {'email': email},
      );
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _apiClient.post(
        ApiEndpoints.changePassword,
        data: {'newPassword': newPassword},
      );
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  // Get user profile from backend
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.profile);
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<ApiResponse<Map<String, dynamic>>> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.updateProfile,
        data: profileData,
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final firebaseAuth = ref.watch(firebaseAuthServiceProvider);
  return AuthService(apiClient, firebaseAuth);
});

// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Provider for current user
final currentUserProvider = StreamProvider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Provider for authentication state
final authStateProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (userId) => userId != null,
    loading: () => false,
    error: (_, __) => false,
  );
});
