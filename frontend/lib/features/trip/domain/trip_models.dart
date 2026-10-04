double _toDouble(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;

class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.owner,
    required this.memberNames,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as int,
    title: json['title'] as String,
    destination: json['destination'] as String,
    startDate: DateTime.parse(json['start_date'] as String),
    endDate: DateTime.parse(json['end_date'] as String),
    status: json['status'] as String? ?? 'upcoming',
    owner: json['owner'] as String? ?? '',
    memberNames: [
      for (final member in (json['members'] as List? ?? const []))
        (member as Map)['username'] as String,
    ],
  );

  final int id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String owner;
  final List<String> memberNames;
}

class BookingSlot {
  const BookingSlot({
    required this.id,
    required this.title,
    required this.slotType,
    required this.capacity,
    required this.price,
    required this.bookedCount,
  });

  factory BookingSlot.fromJson(Map<String, dynamic> json) => BookingSlot(
    id: json['id'] as int,
    title: json['title'] as String,
    slotType: json['slot_type'] as String? ?? 'activity',
    capacity: json['capacity'] as int? ?? 1,
    price: _toDouble(json['price']),
    bookedCount: json['booked_count'] as int? ?? 0,
  );

  final int id;
  final String title;
  final String slotType;
  final int capacity;
  final double price;
  final int bookedCount;

  bool get isFull => bookedCount >= capacity;
}

class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.paidByName,
    required this.splitType,
    required this.shareCount,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as int,
    description: json['description'] as String,
    amount: _toDouble(json['amount']),
    paidById: json['paid_by'] as int,
    paidByName: json['paid_by_name'] as String? ?? '-',
    splitType: json['split_type'] as String? ?? 'equal',
    shareCount: (json['shares'] as List?)?.length ?? 0,
  );

  final int id;
  final String description;
  final double amount;
  final int paidById;
  final String paidByName;
  final String splitType;
  final int shareCount;
}

class TripTask {
  const TripTask({
    required this.id,
    required this.title,
    required this.isDone,
    required this.assignedToName,
  });

  factory TripTask.fromJson(Map<String, dynamic> json) => TripTask(
    id: json['id'] as int,
    title: json['title'] as String,
    isDone: json['is_done'] as bool? ?? false,
    assignedToName: json['assigned_to_name'] as String?,
  );

  final int id;
  final String title;
  final bool isDone;
  final String? assignedToName;
}

class SettlementTransfer {
  const SettlementTransfer({
    required this.fromUser,
    required this.fromUsername,
    required this.toUsername,
    required this.amount,
  });

  factory SettlementTransfer.fromJson(Map<String, dynamic> json) =>
      SettlementTransfer(
        fromUser: json['from_user'] as int,
        fromUsername: json['from_username'] as String,
        toUsername: json['to_username'] as String,
        amount: _toDouble(json['amount']),
      );

  final int fromUser;
  final String fromUsername;
  final String toUsername;
  final double amount;
}
