import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/auth_view_model.dart';
import '../../domain/trip_models.dart';
import '../trip_detail_view_model.dart';
import 'dialogs.dart';
import 'formatters.dart';

enum _ExpenseAction { edit, delete }

class ExpensesTab extends StatelessWidget {
  const ExpensesTab({super.key});

  Future<void> _report(
    BuildContext context,
    Future<String?> action,
    String success,
  ) async {
    final error = await action;
    if (context.mounted) showMessage(context, error ?? success);
  }

  Future<void> _add(BuildContext context) async {
    final viewModel = context.read<TripDetailViewModel>();
    final value = await showExpenseDialog(context);
    if (value == null || !context.mounted) return;
    await _report(
      context,
      viewModel.addExpense(value.description, value.amount),
      'เพิ่มค่าใช้จ่ายแล้ว',
    );
  }

  Future<void> _edit(BuildContext context, Expense expense) async {
    final viewModel = context.read<TripDetailViewModel>();
    final value = await showExpenseDialog(context, initial: expense);
    if (value == null || !context.mounted) return;
    await _report(
      context,
      viewModel.editExpense(expense, value.description, value.amount),
      'แก้ไขค่าใช้จ่ายแล้ว',
    );
  }

  Future<void> _delete(BuildContext context, Expense expense) async {
    final viewModel = context.read<TripDetailViewModel>();
    final confirmed = await confirmDelete(
      context,
      title: 'ลบค่าใช้จ่าย',
      message: 'ต้องการลบ "${expense.description}" หรือไม่?',
    );
    if (!confirmed || !context.mounted) return;
    await _report(context, viewModel.deleteExpense(expense), 'ลบค่าใช้จ่ายแล้ว');
  }

  Future<void> _showSettlement(BuildContext context) async {
    final viewModel = context.read<TripDetailViewModel>();
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
              if (viewModel.transfers.isEmpty)
                const Text('ทุกคนเคลียร์ยอดเรียบร้อยแล้ว'),
              for (final transfer in viewModel.transfers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.arrow_forward_rounded),
                  title: Text(
                    '${transfer.fromUsername} โอนให้ ${transfer.toUsername}',
                  ),
                  trailing: Text(baht(transfer.amount)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TripDetailViewModel>();
    final user = context.watch<AuthViewModel>().user;
    final scheme = Theme.of(context).colorScheme;
    final isTripOwner = viewModel.trip?.owner == user?.username;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ค่าใช้จ่าย',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            IconButton(
              onPressed: () => _add(context),
              tooltip: 'เพิ่มค่าใช้จ่าย',
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ยอดที่คุณต้องจ่ายคืน',
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
              const SizedBox(height: 5),
              Text(
                baht(viewModel.amountOwedBy(user?.id)),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (viewModel.expenses.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('ยังไม่มีค่าใช้จ่ายที่บันทึกไว้'),
            ),
          ),
        for (final expense in viewModel.expenses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.receipt_long_rounded, color: scheme.primary),
                title: Text('${expense.description}  ${baht(expense.amount)}'),
                subtitle: Text(
                  'จ่ายโดย ${expense.paidByName} • หาร${expense.splitType == 'custom' ? 'ไม่เท่ากัน' : 'เท่ากัน'} ${expense.shareCount} คน',
                ),
                trailing: (isTripOwner || expense.paidById == user?.id)
                    ? PopupMenuButton<_ExpenseAction>(
                        onSelected: (action) => switch (action) {
                          _ExpenseAction.edit => _edit(context, expense),
                          _ExpenseAction.delete => _delete(context, expense),
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _ExpenseAction.edit,
                            child: Text('แก้ไข'),
                          ),
                          PopupMenuItem(
                            value: _ExpenseAction.delete,
                            child: Text('ลบ'),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _showSettlement(context),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('ดูรายการที่ต้องโอนทั้งหมด'),
        ),
      ],
    );
  }
}
