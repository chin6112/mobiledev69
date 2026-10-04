import 'package:flutter/material.dart';

import '../viewmodels/trip_view_model.dart';
import 'dialogs.dart';

class PlannerView extends StatelessWidget {
  const PlannerView({
    super.key,
    required this.trip,
    required this.onOpenExpenses,
    this.focus,
  });

  final TripViewModel trip;
  final VoidCallback onOpenExpenses;
  final String? focus;

  Future<void> _report(BuildContext context, Future<String?> action) async {
    final error = await action;
    if (error != null && context.mounted) showMessage(context, error);
  }

  Future<void> _addSlot(BuildContext context) async {
    final slot = await showSlotDialog(context);
    if (slot == null || !context.mounted) return;
    await _report(
      context,
      trip.addSlot(
        title: slot.title,
        slotType: slot.slotType,
        capacity: slot.capacity,
        price: slot.price,
      ),
    );
  }

  Future<void> _addTask(BuildContext context) async {
    final title = await showTaskDialog(context);
    if (title == null || !context.mounted) return;
    await _report(context, trip.addTask(title));
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'แผนทริป',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      const Text('วางแผนร่วมกัน แล้วให้ทุกคนเห็นภาพเดียวกัน'),
      const SizedBox(height: 16),
      Card(
        color: const Color(0xFFE5F2E6),
        child: ListTile(
          onTap: onOpenExpenses,
          leading: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Color(0xFF386641),
            ),
          ),
          title: Text(
            'ค่าใช้จ่ายของ ${trip.tripTitle}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('${trip.expenses.length} รายการที่บันทึกแล้ว'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '฿${trip.expenseTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF386641),
                ),
              ),
              const Text(
                'ดูรายละเอียด',
                style: TextStyle(fontSize: 11, color: Color(0xFF386641)),
              ),
            ],
          ),
        ),
      ),
      if (focus != null) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F1F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: Color(0xFF176B87)),
              const SizedBox(width: 8),
              Text(
                'กำลังจัดการ: $focus',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 22),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'รายการจอง',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: () => _addSlot(context),
            tooltip: 'เพิ่มรายการจอง',
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (trip.plannerLoading) const LinearProgressIndicator(),
      if (trip.slots.isEmpty)
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ยังไม่มีสล็อตจอง'),
            subtitle: Text('กดปุ่ม + เพื่อเพิ่มที่พักหรือกิจกรรม'),
          ),
        ),
      ...trip.slots.map(
        (slot) => Card(
          child: ListTile(
            leading: Icon(
              slot['slot_type'] == 'accommodation'
                  ? Icons.cabin_rounded
                  : slot['slot_type'] == 'transport'
                  ? Icons.train_rounded
                  : Icons.event_available_rounded,
              color: const Color(0xFF176B87),
            ),
            title: Text(
              slot['title']?.toString() ?? 'สล็อตจอง',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${slot['booked_count'] ?? 0}/${slot['capacity'] ?? 0} ที่ • ฿${slot['price'] ?? 0}',
            ),
            trailing: (slot['booked_count'] ?? 0) >= (slot['capacity'] ?? 0)
                ? const Icon(Icons.check_circle, color: Colors.green)
                : OutlinedButton(
                    onPressed: () => _report(context, trip.bookSlot(slot)),
                    child: const Text('จอง'),
                  ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'เช็กลิสต์ทีม',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: () => _addTask(context),
            tooltip: 'เพิ่มงาน',
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      if (trip.tasks.isEmpty)
        const Text(
          'ยังไม่มีงานเตรียมทริป',
          style: TextStyle(color: Colors.grey),
        ),
      ...trip.tasks.map(
        (task) => CheckboxListTile(
          value: task['is_done'] == true,
          onChanged: (value) =>
              _report(context, trip.toggleTask(task, value ?? false)),
          contentPadding: EdgeInsets.zero,
          title: Text(task['title']?.toString() ?? 'งานเตรียมทริป'),
          subtitle: Text(
            task['assigned_to_name']?.toString() ?? 'ยังไม่ได้มอบหมาย',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    ],
  );
}
