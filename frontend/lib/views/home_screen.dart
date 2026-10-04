import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_view_model.dart';
import '../viewmodels/trip_view_model.dart';
import 'dashboard_view.dart';
import 'dialogs.dart';
import 'expenses_view.dart';
import 'planner_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  String? _plannerFocus;

  void _openPlanner([String? focus]) => setState(() {
    _plannerFocus = focus;
    _tabIndex = 1;
  });

  Future<void> _createTrip() async {
    final trip = context.read<TripViewModel>();
    final details = await showTripDialog(context);
    if (details == null || !mounted) return;
    final firstDate = DateTime.now();
    final lastDate = firstDate.add(const Duration(days: 730));
    final start = await showDatePicker(
      context: context,
      initialDate: trip.tripStart.isBefore(firstDate) ? firstDate : trip.tripStart,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: start.add(const Duration(days: 1)),
      firstDate: start,
      lastDate: lastDate,
    );
    if (end == null || !mounted) return;
    final error = await trip.createTrip(
      title: details.title,
      destination: details.destination,
      start: start,
      end: end,
    );
    if (!mounted) return;
    showMessage(
      context,
      error == null ? 'สร้างทริป ${details.title} แล้ว' : 'บันทึกทริปไม่สำเร็จ: $error',
    );
  }

  Future<void> _addExpense() async {
    final trip = context.read<TripViewModel>();
    final expense = await showExpenseDialog(context);
    if (expense == null || !mounted) return;
    final error = await trip.addExpense(expense.description, expense.amount);
    if (!mounted) return;
    showMessage(
      context,
      error == null ? 'เพิ่มค่าใช้จ่ายแล้ว' : 'บันทึกค่าใช้จ่ายไม่สำเร็จ: $error',
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripViewModel>();
    final user = context.watch<AuthViewModel>().user;
    final pages = [
      DashboardView(
        userName: user?.name ?? 'ผู้ใช้',
        trip: trip,
        onOpenPlanner: _openPlanner,
        onCreateTrip: _createTrip,
      ),
      PlannerView(
        trip: trip,
        focus: _plannerFocus,
        onOpenExpenses: () => setState(() => _tabIndex = 2),
      ),
      ExpensesView(
        trip: trip,
        currentUserId: user?.id,
        onAdd: _addExpense,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TripMate',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: context.read<AuthViewModel>().logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              child: Text((user?.name ?? '?').characters.first.toUpperCase()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _tabIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Expenses',
          ),
        ],
      ),
    );
  }
}
