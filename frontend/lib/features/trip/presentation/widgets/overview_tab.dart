import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../trip_detail_view_model.dart';
import 'formatters.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TripDetailViewModel>();
    final trip = viewModel.trip!;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.destination,
                style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 8),
              Text(
                trip.title,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateRange(trip.startDate, trip.endDate),
                style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('เจ้าของทริป'),
                trailing: Text(trip.owner),
              ),
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('สมาชิก'),
                subtitle: Text(trip.memberNames.join(', ')),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('สถานะ'),
                trailing: Text(trip.status),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('รายการจอง'),
                trailing: Text('${viewModel.slots.length}'),
              ),
              ListTile(
                leading: const Icon(Icons.checklist_rounded),
                title: const Text('งานเตรียมทริป'),
                trailing: Text(
                  '${viewModel.tasks.where((t) => t.isDone).length}/${viewModel.tasks.length}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('ค่าใช้จ่ายรวม'),
                trailing: Text(baht(viewModel.expenseTotal)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
