import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../data/trip_repository.dart';
import '../domain/trip_models.dart';

enum TripSort { newestFirst, oldestFirst, titleAZ }

class TripListViewModel extends ChangeNotifier {
  TripListViewModel(this._repository);

  final TripRepository _repository;

  List<Trip> _trips = [];
  String _query = '';
  TripSort _sort = TripSort.newestFirst;
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  TripSort get sort => _sort;
  bool get hasTrips => _trips.isNotEmpty;

  List<Trip> get visibleTrips {
    final needle = _query.trim().toLowerCase();
    final trips = _trips
        .where(
          (trip) =>
              needle.isEmpty ||
              trip.title.toLowerCase().contains(needle) ||
              trip.destination.toLowerCase().contains(needle),
        )
        .toList();
    trips.sort(
      (a, b) => switch (_sort) {
        TripSort.newestFirst => b.startDate.compareTo(a.startDate),
        TripSort.oldestFirst => a.startDate.compareTo(b.startDate),
        TripSort.titleAZ => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
      },
    );
    return trips;
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSort(TripSort value) {
    _sort = value;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final result = await _repository.getTrips();
    result.when(ok: (trips) => _trips = trips, err: (e) => _error = e.message);
    _loading = false;
    notifyListeners();
  }

  /// Returns the new trip's id, or an error message.
  Future<({int? id, String? error})> createTrip({
    required String title,
    required String destination,
    required DateTime start,
    required DateTime end,
  }) async {
    final result = await _repository.createTrip(
      title: title,
      destination: destination,
      start: start,
      end: end,
    );
    if (result case Ok(:final value)) {
      _trips = [value, ..._trips];
      notifyListeners();
      return (id: value.id, error: null);
    }
    return (id: null, error: result.errorMessage);
  }
}
