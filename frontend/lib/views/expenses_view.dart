import 'package:flutter/material.dart';

import '../viewmodels/trip_view_model.dart';

class ExpensesView extends StatelessWidget {
  const ExpensesView({
    super.key,
    required this.trip,
    required this.currentUserId,
    required this.onAdd,
  });

  final TripViewModel trip;
  final int? currentUserId;
  final VoidCallback onAdd;

  Future<void> _showSettlement(BuildContext context) async {
    await trip.refreshSettlement();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'รายการที่ต้องโอน',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (trip.settlement.isEmpty)
                const Text('ทุกคนเคลียร์ยอดเรียบร้อยแล้ว'),
              ...trip.settlement.map(
                (transfer) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF176B87),
                  ),
                  title: Text(
                    '${transfer['from_username']} โอนให้ ${transfer['to_username']}',
                  ),
                  trailing: Text('฿${transfer['amount']}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ค่าใช้จ่าย',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: onAdd,
            tooltip: 'เพิ่มค่าใช้จ่าย',
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      const Text('ระบบคำนวณยอดที่แต่ละคนต้องคืนให้โดยอัตโนมัติ'),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE5F2E6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ยอดที่คุณต้องจ่ายคืน',
              style: TextStyle(color: Color(0xFF386641)),
            ),
            const SizedBox(height: 5),
            Text(
              '฿${trip.amountOwedBy(currentUserId).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF386641),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'รายการล่าสุด',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (trip.expenses.isEmpty)
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ยังไม่มีค่าใช้จ่ายที่บันทึกไว้'),
          ),
        ),
      ...trip.expenses.map(
        (expense) => Card(
          child: ListTile(
            leading: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF176B87),
            ),
            title: Text(
              '${expense['description'] ?? ''} ${expense['amount'] ?? ''} บาท',
            ),
            subtitle: Text(
              'จ่ายโดย ${expense['paid_by_name'] ?? '-'} • หาร${expense['split_type'] == 'custom' ? 'ไม่เท่ากัน' : 'เท่ากัน'} ${(expense['shares'] as List?)?.length ?? 0} คน',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: () => _showSettlement(context),
        icon: const Icon(Icons.payments_outlined),
        label: const Text('ดูรายการที่ต้องโอนทั้งหมด'),
      ),
    ],
  );
}
