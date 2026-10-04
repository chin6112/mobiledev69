import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../data/trip_repository.dart';
import '../domain/trip_models.dart';

class TripDetailViewModel extends ChangeNotifier {
  TripDetailViewModel(this._repository, this.tripId);

  final TripRepository _repository;
  final int tripId;

  Trip? trip;
  List<BookingSlot> slots = [];
  List<TripTask> tasks = [];
  List<Expense> expenses = [];
  List<SettlementTransfer> transfers = [];
  bool loading = false;
  String? error;

  double get expenseTotal =>
      expenses.fold<double>(0, (total, expense) => total + expense.amount);

  double amountOwedBy(int? userId) => userId == null
      ? 0
      : transfers
            .where((transfer) => transfer.fromUser == userId)
            .fold<double>(0, (sum, transfer) => sum + transfer.amount);

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    final results = await Future.wait<Result<Object?>>([
      _repository.getTrip(tripId),
      _repository.getSlots(tripId),
      _repository.getTasks(tripId),
      _repository.getExpenses(tripId),
      _repository.getSettlement(tripId),
    ]);
    trip = results[0].valueOrNull as Trip? ?? trip;
    slots = results[1].valueOrNull as List<BookingSlot>? ?? slots;
    tasks = results[2].valueOrNull as List<TripTask>? ?? tasks;
    expenses = results[3].valueOrNull as List<Expense>? ?? expenses;
    transfers = results[4].valueOrNull as List<SettlementTransfer>? ?? transfers;
    error = results.map((r) => r.errorMessage).whereType<String>().firstOrNull;
    loading = false;
    notifyListeners();
  }

  /// Applies [onOk] on success and returns the error message on failure.
  Future<String?> _run<T>(
    Future<Result<T>> call,
    void Function(T value) onOk,
  ) async {
    final result = await call;
    final message = result.errorMessage;
    if (message == null) {
      onOk((result as Ok<T>).value);
      notifyListeners();
    }
    return message;
  }

  Future<String?> updateTrip({
    required String title,
    required String destination,
    required DateTime start,
    required DateTime end,
  }) => _run(
    _repository.updateTrip(
      tripId,
      title: title,
      destination: destination,
      start: start,
      end: end,
    ),
    (updated) => trip = updated,
  );

  Future<String?> deleteTrip() => _run(_repository.deleteTrip(tripId), (_) {});

  Future<void> _refreshSettlement() async {
    transfers = (await _repository.getSettlement(tripId)).valueOrNull ?? [];
  }

  Future<String?> addExpense(String description, double amount) async {
    final message = await _run(
      _repository.createExpense(
        tripId,
        description: description,
        amount: amount,
      ),
      (created) => expenses = [created, ...expenses],
    );
    if (message == null) {
      await _refreshSettlement();
      notifyListeners();
    }
    return message;
  }

  Future<String?> editExpense(
    Expense expense,
    String description,
    double amount,
  ) async {
    final message = await _run(
      _repository.updateExpense(
        expense.id,
        description: description,
        amount: amount,
      ),
      (updated) => expenses = [
        for (final item in expenses) item.id == updated.id ? updated : item,
      ],
    );
    if (message == null) {
      await _refreshSettlement();
      notifyListeners();
    }
    return message;
  }

  Future<String?> deleteExpense(Expense expense) async {
    final message = await _run(
      _repository.deleteExpense(expense.id),
      (_) => expenses = expenses.where((e) => e.id != expense.id).toList(),
    );
    if (message == null) {
      await _refreshSettlement();
      notifyListeners();
    }
    return message;
  }

  Future<String?> addSlot({
    required String title,
    required String slotType,
    required int capacity,
    required double price,
  }) => _run(
    _repository.createSlot(
      tripId,
      title: title,
      slotType: slotType,
      capacity: capacity,
      price: price,
    ),
    (created) => slots = [...slots, created],
  );

  Future<String?> bookSlot(BookingSlot slot) => _run(
    _repository.bookSlot(slot.id),
    (updated) => slots = [
      for (final item in slots) item.id == updated.id ? updated : item,
    ],
  );

  Future<String?> addTask(String title) => _run(
    _repository.createTask(tripId, title: title),
    (created) => tasks = [...tasks, created],
  );

  Future<String?> setTaskDone(TripTask task, bool isDone) => _run(
    _repository.setTaskDone(task.id, isDone: isDone),
    (updated) => tasks = [
      for (final item in tasks) item.id == updated.id ? updated : item,
    ],
  );

  Future<String?> deleteTask(TripTask task) => _run(
    _repository.deleteTask(task.id),
    (_) => tasks = tasks.where((t) => t.id != task.id).toList(),
  );
}
