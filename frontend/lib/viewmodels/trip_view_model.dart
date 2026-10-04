import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../repositories/trip_repository.dart';

class TripViewModel extends ChangeNotifier {
  TripViewModel(this._repository);

  final TripRepository _repository;

  int? tripId;
  String tripTitle = 'เชียงใหม่หน้าฝน';
  String tripDestination = 'เชียงใหม่';
  DateTime tripStart = DateTime(2026, 10, 12);
  DateTime tripEnd = DateTime(2026, 10, 15);

  bool syncing = false;
  bool plannerLoading = false;
  String? error;

  List<Json> slots = [];
  List<Json> tasks = [];
  List<Json> expenses = [];
  List<Json> settlement = [];

  double get expenseTotal => expenses.fold<double>(
    0,
    (total, expense) =>
        total + (double.tryParse(expense['amount']?.toString() ?? '') ?? 0),
  );

  double amountOwedBy(int? userId) {
    if (userId == null) return 0;
    return settlement
        .where((transfer) => transfer['from_user'] == userId)
        .fold<double>(
          0,
          (sum, transfer) =>
              sum + (double.tryParse(transfer['amount']?.toString() ?? '') ?? 0),
        );
  }

  Future<void> load() async {
    syncing = true;
    notifyListeners();
    try {
      final trips = await _repository.getTrips();
      if (trips.isNotEmpty) {
        final trip = trips.first;
        tripId = int.tryParse(trip['id']?.toString() ?? '');
        tripTitle = trip['title']?.toString() ?? tripTitle;
        tripDestination = trip['destination']?.toString() ?? tripDestination;
        tripStart =
            DateTime.tryParse(trip['start_date']?.toString() ?? '') ??
            tripStart;
        tripEnd =
            DateTime.tryParse(trip['end_date']?.toString() ?? '') ?? tripEnd;
        await Future.wait([loadPlanner(), loadExpenses()]);
      }
    } on AppException catch (e) {
      error = e.message;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> loadPlanner() async {
    final id = tripId;
    if (id == null) return;
    plannerLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getSlots(id),
        _repository.getTasks(id),
      ]);
      slots = results[0];
      tasks = results[1];
    } on AppException catch (e) {
      error = e.message;
    } finally {
      plannerLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpenses() async {
    final id = tripId;
    if (id == null) return;
    try {
      final results = await Future.wait([
        _repository.getExpenses(id),
        _repository.getSettlement(id),
      ]);
      expenses = results[0];
      settlement = results[1];
    } on AppException catch (e) {
      error = e.message;
      expenses = [];
      settlement = [];
    }
    notifyListeners();
  }

  Future<void> refreshSettlement() async {
    final id = tripId;
    if (id == null) return;
    try {
      settlement = await _repository.getSettlement(id);
    } on AppException {
      settlement = [];
    }
    notifyListeners();
  }

  /// Runs [action]; returns null on success or the error message to display.
  Future<String?> _guard(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> createTrip({
    required String title,
    required String destination,
    required DateTime start,
    required DateTime end,
  }) => _guard(() async {
    final created = await _repository.createTrip(
      title: title,
      destination: destination,
      startDate: _dateValue(start),
      endDate: _dateValue(end),
    );
    tripId = int.tryParse(created['id']?.toString() ?? '');
    tripTitle = title;
    tripDestination = destination;
    tripStart = start;
    tripEnd = end;
    slots = [];
    tasks = [];
    expenses = [];
    settlement = [];
    notifyListeners();
  });

  Future<String?> addExpense(String description, double amount) {
    final id = tripId;
    if (id == null) return Future.value('ยังไม่มีทริปสำหรับบันทึกค่าใช้จ่าย');
    return _guard(() async {
      await _repository.createExpense(
        tripId: id,
        description: description,
        amount: amount,
      );
      await loadExpenses();
    });
  }

  Future<String?> addSlot({
    required String title,
    required String slotType,
    required int capacity,
    required double price,
  }) {
    final id = tripId;
    if (id == null) return Future.value('ยังไม่มีทริป');
    return _guard(() async {
      await _repository.createSlot(
        tripId: id,
        title: title,
        slotType: slotType,
        capacity: capacity,
        price: price,
      );
      await loadPlanner();
    });
  }

  Future<String?> bookSlot(Json slot) {
    final slotId = int.tryParse(slot['id']?.toString() ?? '');
    if (slotId == null) return Future.value(null);
    return _guard(() async {
      final updated = await _repository.bookSlot(slotId);
      final index = slots.indexWhere((item) => item['id'] == slot['id']);
      if (index >= 0) slots[index] = updated;
      notifyListeners();
    });
  }

  Future<String?> addTask(String title) {
    final id = tripId;
    if (id == null) return Future.value('ยังไม่มีทริป');
    return _guard(() async {
      await _repository.createTask(tripId: id, title: title);
      await loadPlanner();
    });
  }

  Future<String?> toggleTask(Json task, bool value) {
    final taskId = int.tryParse(task['id']?.toString() ?? '');
    if (taskId == null) return Future.value(null);
    return _guard(() async {
      final updated = await _repository.updateTask(
        taskId: taskId,
        isDone: value,
      );
      final index = tasks.indexWhere((item) => item['id'] == task['id']);
      if (index >= 0) tasks[index] = updated;
      notifyListeners();
    });
  }

  static String _dateValue(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
