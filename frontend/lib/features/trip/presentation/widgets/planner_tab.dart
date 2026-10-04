import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/trip_models.dart';
import '../trip_detail_view_model.dart';
import 'dialogs.dart';

class PlannerTab extends StatelessWidget {
  const PlannerTab({super.key});

  Future<void> _report(BuildContext context, Future<String?> action) async {
    final error = await action;
    if (error != null && context.mounted) showMessage(context, error);
  }

  Future<void> _addSlot(BuildContext context) async {
    final viewModel = context.read<TripDetailViewModel>();
    final slot = await showSlotDialog(context);
    if (slot == null || !context.mounted) return;
    await _report(
      context,
      viewModel.addSlot(
        title: slot.title,
        slotType: slot.slotType,
        capacity: slot.capacity,
        price: slot.price,
      ),
    );
  }

  Future<void> _addTask(BuildContext context) async {
    final viewModel = context.read<TripDetailViewModel>();
    final title = await showTaskDialog(context);
    if (title == null || !context.mounted) return;
    await _report(context, viewModel.addTask(title));
  }

  Future<void> _deleteTask(BuildContext context, TripTask task) async {
    final viewModel = context.read<TripDetailViewModel>();
    final confirmed = await confirmDelete(
      context,
      title: 'ลบงาน',
      message: 'ต้องการลบ "${task.title}" หรือไม่?',
    );
    if (!confirmed || !context.mounted) return;
    await _report(context, viewModel.deleteTask(task));
  }

  IconData _icon(String slotType) => switch (slotType) {
    'accommodation' => Icons.cabin_rounded,
    'transport' => Icons.train_rounded,
    _ => Icons.event_available_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TripDetailViewModel>();
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          title: 'รายการจอง',
          tooltip: 'เพิ่มรายการจอง',
          onAdd: () => _addSlot(context),
        ),
        if (viewModel.slots.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('ยังไม่มีรายการจอง'),
              subtitle: Text('กดปุ่ม + เพื่อเพิ่มที่พัก การเดินทาง หรือกิจกรรม'),
            ),
          ),
        for (final slot in viewModel.slots)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: Icon(_icon(slot.slotType), color: scheme.primary),
                title: Text(
                  slot.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${slot.bookedCount}/${slot.capacity} ที่ • ฿${slot.price.toStringAsFixed(0)}',
                ),
                trailing: slot.isFull
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : OutlinedButton(
                        onPressed: () =>
                            _report(context, viewModel.bookSlot(slot)),
                        child: const Text('จอง'),
                      ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'เช็กลิสต์ทีม',
          tooltip: 'เพิ่มงาน',
          onAdd: () => _addTask(context),
        ),
        if (viewModel.tasks.isEmpty)
          const Text('ยังไม่มีงานเตรียมทริป', style: TextStyle(color: Colors.grey)),
        for (final task in viewModel.tasks)
          CheckboxListTile(
            value: task.isDone,
            onChanged: (value) => _report(
              context,
              viewModel.setTaskDone(task, value ?? false),
            ),
            contentPadding: EdgeInsets.zero,
            title: Text(task.title),
            subtitle: Text(task.assignedToName ?? 'ยังไม่ได้มอบหมาย'),
            controlAffinity: ListTileControlAffinity.leading,
            secondary: IconButton(
              tooltip: 'ลบงาน',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteTask(context, task),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.tooltip,
    required this.onAdd,
  });

  final String title;
  final String tooltip;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      IconButton(
        onPressed: onAdd,
        tooltip: tooltip,
        icon: const Icon(Icons.add_circle_outline_rounded),
      ),
    ],
  );
}
