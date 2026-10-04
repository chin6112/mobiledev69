import '../services/api_service.dart';

typedef Json = Map<String, dynamic>;

class TripRepository {
  TripRepository(this._api);

  final ApiService _api;

  Future<List<Json>> _list(String path) async =>
      ((await _api.get(path)) as List).cast<Json>();

  Future<List<Json>> getTrips() => _list('trips/');

  Future<Json> createTrip({
    required String title,
    required String destination,
    required String startDate,
    required String endDate,
  }) async => (await _api.post('trips/', {
    'title': title,
    'destination': destination,
    'start_date': startDate,
    'end_date': endDate,
  })) as Json;

  Future<List<Json>> getSlots(int tripId) => _list('trips/$tripId/slots/');

  Future<Json> createSlot({
    required int tripId,
    required String title,
    required String slotType,
    required int capacity,
    required double price,
  }) async => (await _api.post('trips/$tripId/slots/', {
    'title': title,
    'slot_type': slotType,
    'capacity': capacity,
    'price': price,
  })) as Json;

  Future<Json> bookSlot(int slotId) async =>
      (await _api.post('slots/$slotId/book/')) as Json;

  Future<List<Json>> getExpenses(int tripId) =>
      _list('trips/$tripId/expenses/');

  Future<Json> createExpense({
    required int tripId,
    required String description,
    required double amount,
  }) async => (await _api.post('trips/$tripId/expenses/', {
    'description': description,
    'amount': amount,
  })) as Json;

  Future<List<Json>> getSettlement(int tripId) async {
    final data = (await _api.get('trips/$tripId/settlement/')) as Json;
    return (data['transfers'] as List).cast<Json>();
  }

  Future<List<Json>> getTasks(int tripId) => _list('trips/$tripId/tasks/');

  Future<Json> createTask({
    required int tripId,
    required String title,
    String category = 'team',
  }) async => (await _api.post('trips/$tripId/tasks/', {
    'title': title,
    'category': category,
  })) as Json;

  Future<Json> updateTask({required int taskId, required bool isDone}) async =>
      (await _api.patch('tasks/$taskId/', {'is_done': isDone})) as Json;
}
