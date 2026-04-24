class InventoryItem {
  final int? id;
  final String name;
  final String location;
  final int quantity;
  final String unit;
  final String? receiptNumber;
  final String? receiptDateTime;

  InventoryItem({
    this.id,
    required this.name,
    required this.location,
    required this.quantity,
    required this.unit,
    this.receiptNumber,
    this.receiptDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'quantity': quantity,
      'unit': unit,
      'receiptNumber': receiptNumber,
      'receiptDateTime': receiptDateTime,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      quantity: map['quantity'],
      unit: map['unit'],
      receiptNumber: map['receiptNumber'],
      receiptDateTime: map['receiptDateTime'],
    );
  }
}

