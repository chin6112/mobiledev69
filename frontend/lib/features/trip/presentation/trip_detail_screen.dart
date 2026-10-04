import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_view_model.dart';
import 'trip_detail_view_model.dart';
import 'widgets/dialogs.dart';
import 'widgets/expenses_tab.dart';
import 'widgets/overview_tab.dart';
import 'widgets/planner_tab.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key});

  Future<void> _edit(BuildContext context) async {
    final viewModel = context.read<TripDetailViewModel>();
    final value = await showTripDialog(context, initial: viewModel.trip);
    if (value == null || !context.mounted) return;
    final error = await viewModel.updateTrip(
      title: value.title,
      destination: value.destination,
      start: value.start,
      end: value.end,
    );
    if (!context.mounted) return;
    showMessage(context, error == null ? 'บันทึกการแก้ไขแล้ว' : 'แก้ไขไม่สำเร็จ: $error');
  }

  Future<void> _delete(BuildContext context) async {
    final viewModel = context.read<TripDetailViewModel>();
    final confirmed = await confirmDelete(
      context,
      title: 'ลบทริป',
      message: 'ต้องการลบ "${viewModel.trip?.title}" พร้อมข้อมูลทั้งหมดหรือไม่?',
    );
    if (!confirmed || !context.mounted) return;
    final error = await viewModel.deleteTrip();
    if (!context.mounted) return;
    if (error == null) {
      context.pop();
    } else {
      showMessage(context, 'ลบไม่สำเร็จ: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TripDetailViewModel>();
    final user = context.watch<AuthViewModel>().user;
    final trip = viewModel.trip;
    final isOwner = trip != null && trip.owner == user?.username;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(trip?.title ?? 'ทริป'),
          actions: [
            if (isOwner) ...[
              IconButton(
                tooltip: 'แก้ไขทริป',
                onPressed: () => _edit(context),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'ลบทริป',
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home_outlined), text: 'ภาพรวม'),
              Tab(icon: Icon(Icons.event_note_outlined), text: 'แผนทริป'),
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined),
                text: 'ค่าใช้จ่าย',
              ),
            ],
          ),
        ),
        body: viewModel.trip == null
            ? _Loading(viewModel: viewModel)
            : Column(
                children: [
                  if (viewModel.loading) const LinearProgressIndicator(minHeight: 2),
                  if (viewModel.error != null)
                    MaterialBanner(
                      content: Text(viewModel.error!),
                      actions: [
                        TextButton(
                          onPressed: viewModel.load,
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  const Expanded(
                    child: TabBarView(
                      children: [OverviewTab(), PlannerTab(), ExpensesTab()],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.viewModel});

  final TripDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) => Center(
    child: viewModel.error == null
        ? const CircularProgressIndicator()
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(viewModel.error!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: viewModel.load,
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
  );
}
