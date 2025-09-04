import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../data/leave_repository.dart';
import '../../../core/widgets/async_value_widget.dart';

class LeaveBalanceScreen extends ConsumerWidget {
  const LeaveBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(authRepositoryProvider).currentUserId(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final state = ref.watch(leaveControllerProvider(snap.data ?? ''));
        return Scaffold(
          appBar: AppBar(title: const Text('Leave Balance')),
          body: AsyncValueWidget<LeaveVm>(
            value: state,
            data: (d) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('ลาพักร้อน (Annual)'),
                    trailing: Text(d.balance.vacationLeave.toStringAsFixed(1)),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('ลาป่วย (Sick)'),
                    trailing: Text(d.balance.sickLeave.toStringAsFixed(1)),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('ลาโดยไม่ได้รับค่าจ้าง (Unpaid)'),
                    trailing: Text(
                      d.balance.leaveWithoutPay.toStringAsFixed(1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'My Requests',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...d.requests.map(
                  (r) => Card(
                    child: ListTile(
                      title: Text('${r.type.toUpperCase()} — ${r.status}'),
                      subtitle: Text(
                        '${r.start.toLocal()} → ${r.end.toLocal()}\n${r.reason}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
