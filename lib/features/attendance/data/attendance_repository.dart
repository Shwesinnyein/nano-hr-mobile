import 'package:flutter_riverpod/flutter_riverpod.dart';

class Attendance {
  Attendance({required this.id, required this.userId, required this.checkInAt, this.checkOutAt, required this.location});
  final String id;
  final String userId;
  final DateTime checkInAt;
  DateTime? checkOutAt;
  final String location;
}

class AttendanceRepository {
  // in-memory store
  final _items = <Attendance>[];

  Future<List<Attendance>> listMyAttendance(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _items.where((e) => e.userId == userId).toList().reversed.toList();
  }

  Future<Attendance> checkIn({required String userId, required String location}) async {
    final a = Attendance(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      checkInAt: DateTime.now().toUtc(),
      location: location,
    );
    _items.add(a);
    return a;
  }

  Future<Attendance> checkOut({required String attendanceId}) async {
    final idx = _items.indexWhere((e) => e.id == attendanceId);
    if (idx == -1) throw Exception('Open attendance not found');
    _items[idx].checkOutAt = DateTime.now().toUtc();
    return _items[idx];
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) => AttendanceRepository());

class AttendanceController extends StateNotifier<AsyncValue<List<Attendance>>> {
  AttendanceController(this._repo, this._userId) : super(const AsyncValue.loading()) {
    load();
  }
  final AttendanceRepository _repo;
  final String _userId;
  String? _openId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.listMyAttendance(_userId);
      state = AsyncValue.data(data);
      _openId = data.cast<Attendance?>().firstWhere(
        (a) => a != null && a.checkOutAt == null,
        orElse: () => null,
      )?.id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleCheck() async {
    try {
      if (_openId == null) {
        final created = await _repo.checkIn(userId: _userId, location: 'Office');
        _openId = created.id;
      } else {
        await _repo.checkOut(attendanceId: _openId!);
        _openId = null;
      }
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final attendanceControllerProvider = StateNotifierProvider.family<AttendanceController, AsyncValue<List<Attendance>>, String>((ref, userId) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return AttendanceController(repo, userId);
});
