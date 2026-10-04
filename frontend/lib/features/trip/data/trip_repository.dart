import '../../../core/api/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/trip_models.dart';

typedef _Json = Map<String, dynamic>;

class TripRepository {
  TripRepository(this._api);

  final ApiClient _api;

  Future<List<_Json>> _list(String path) async =>
      ((await _api.get(path)) as List).cast<_Json>();

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<Result<List<Trip>>> getTrips() => Result.guard(
    () async => [for (final json in await _list('trips/')) Trip.fromJson(json)],
  );

  Future<Result<Trip>> getTrip(int id) =>
      Result.guard(() async => Trip.fromJson(await _api.get('trips/$id/')));

  Future<Result<Trip>> createTrip({
    required String title,
    required String destination,
    required DateTime start,
    required DateTime end,
  }) => Result.guard(
    () async => Trip.fromJson(
      await _api.post('trips/', {
        'title': title,
        'destination': destination,
        'start_date': _date(start),
        'end_date': _date(end),
      }),
    ),
  );

  Future<Result<Trip>> updateTrip(
    int id, {
    required String title,
    required String destination,
    required DateTime start,
    required DateTime end,
  }) => Result.guard(
    () async => Trip.fromJson(
      await _api.patch('trips/$id/', {
        'title': title,
        'destination': destination,
        'start_date': _date(start),
        'end_date': _date(end),
      }),
    ),
  );

  Future<Result<void>> deleteTrip(int id) =>
      Result.guard(() => _api.delete('trips/$id/'));

  Future<Result<List<BookingSlot>>> getSlots(int tripId) => Result.guard(
    () async => [
      for (final json in await _list('trips/$tripId/slots/'))
        BookingSlot.fromJson(json),
    ],
  );

  Future<Result<BookingSlot>> createSlot(
    int tripId, {
    required String title,
    required String slotType,
    required int capacity,
    required double price,
  }) => Result.guard(
    () async => BookingSlot.fromJson(
      await _api.post('trips/$tripId/slots/', {
        'title': title,
        'slot_type': slotType,
        'capacity': capacity,
        'price': price,
      }),
    ),
  );

  Future<Result<BookingSlot>> bookSlot(int slotId) => Result.guard(
    () async => BookingSlot.fromJson(await _api.post('slots/$slotId/book/')),
  );

  Future<Result<List<Expense>>> getExpenses(int tripId) => Result.guard(
    () async => [
      for (final json in await _list('trips/$tripId/expenses/'))
        Expense.fromJson(json),
    ],
  );

  Future<Result<Expense>> createExpense(
    int tripId, {
    required String description,
    required double amount,
  }) => Result.guard(
    () async => Expense.fromJson(
      await _api.post('trips/$tripId/expenses/', {
        'description': description,
        'amount': amount,
      }),
    ),
  );

  Future<Result<Expense>> updateExpense(
    int expenseId, {
    required String description,
    required double amount,
  }) => Result.guard(
    () async => Expense.fromJson(
      await _api.patch('expenses/$expenseId/', {
        'description': description,
        'amount': amount,
      }),
    ),
  );

  Future<Result<void>> deleteExpense(int expenseId) =>
      Result.guard(() => _api.delete('expenses/$expenseId/'));

  Future<Result<List<SettlementTransfer>>> getSettlement(int tripId) =>
      Result.guard(() async {
        final data = (await _api.get('trips/$tripId/settlement/')) as _Json;
        return [
          for (final json in (data['transfers'] as List).cast<_Json>())
            SettlementTransfer.fromJson(json),
        ];
      });

  Future<Result<List<TripTask>>> getTasks(int tripId) => Result.guard(
    () async => [
      for (final json in await _list('trips/$tripId/tasks/'))
        TripTask.fromJson(json),
    ],
  );

  Future<Result<TripTask>> createTask(int tripId, {required String title}) =>
      Result.guard(
        () async => TripTask.fromJson(
          await _api.post('trips/$tripId/tasks/', {
            'title': title,
            'category': 'team',
          }),
        ),
      );

  Future<Result<TripTask>> setTaskDone(int taskId, {required bool isDone}) =>
      Result.guard(
        () async => TripTask.fromJson(
          await _api.patch('tasks/$taskId/', {'is_done': isDone}),
        ),
      );

  Future<Result<void>> deleteTask(int taskId) =>
      Result.guard(() => _api.delete('tasks/$taskId/'));
}
