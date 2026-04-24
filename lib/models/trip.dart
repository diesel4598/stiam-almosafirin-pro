class Trip {
  final int? id;
  final String fromCity;
  final String toCity;
  final String time;
  final String tripDate;
  final String busId;
  final String status;
  final int passengersCount;
  final int bottlesDistributed;

  Trip({
    this.id,
    required this.fromCity,
    required this.toCity,
    required this.time,
    required this.tripDate,
    required this.busId,
    required this.status,
    this.passengersCount = 0,
    this.bottlesDistributed = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromCity': fromCity,
      'toCity': toCity,
      'time': time,
      'tripDate': tripDate,
      'busId': busId,
      'status': status,
      'passengersCount': passengersCount,
      'bottlesDistributed': bottlesDistributed,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      fromCity: map['fromCity'],
      toCity: map['toCity'],
      time: map['time'],
      tripDate: map['tripDate'] ?? '',
      busId: map['busId'],
      status: map['status'],
      passengersCount: map['passengersCount'] ?? 0,
      bottlesDistributed: map['bottlesDistributed'] ?? 0,
    );
  }
}
