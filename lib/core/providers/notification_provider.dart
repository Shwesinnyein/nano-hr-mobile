import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationState {
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService;

  NotificationNotifier(this._authService) : super(const NotificationState()) {
    // _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final employeeId = _authService.currentEmployeeId;
    if (employeeId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _notificationService.getNotifications(
        employeeId: employeeId,
        unreadOnly:
            false, 
        limit: 100, 
      );

      if (response['success'] == true) {
        final data = response['data'];

        if (data is List<dynamic>) {
          final unreadCount = data.where((notification) {
            final senderId = notification['senderId'];
            if (notification['type'] == 'leave_request' &&
                senderId == employeeId) {
              return false; 
            }

            final isRead = notification['isRead'];

            final isUnread =
                isRead == false ||
                isRead == null ||
                isRead == 'false' ||
                isRead == 0;

            return isUnread;
          }).length;

          state = state.copyWith(unreadCount: unreadCount, isLoading: false);
        } else {
          state = state.copyWith(unreadCount: 0, isLoading: false);
        }
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Failed to load notifications',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error loading notifications: $e',
        isLoading: false,
      );
    }
  }

  Future<void> initialize() async {
    await _loadUnreadCount();
  }

  Future<void> refreshUnreadCount() async {
    await _loadUnreadCount();
  }

  void updateUnreadCount(int count) {
    state = state.copyWith(unreadCount: count, isLoading: false);
  }

  void markAsRead() {
    if (state.unreadCount > 0) {
      state = state.copyWith(unreadCount: state.unreadCount - 1);
    }
  }

  void markAllAsRead() {
    state = state.copyWith(unreadCount: 0);
  }

  void addNotification() {
    state = state.copyWith(unreadCount: state.unreadCount + 1);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final authService = ref.read(authServiceProvider);
      return NotificationNotifier(authService);
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
