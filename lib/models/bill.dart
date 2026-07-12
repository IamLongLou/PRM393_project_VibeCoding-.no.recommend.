class Bill {
  final int? id;
  final int customerId;
  final String? customerName;
  final String? customerCode;
  final String billCode;
  final DateTime date;
  final int oldReading;
  final int newReading;
  final double consumption;
  final double unitPrice;
  final double amount;
  final double vat;
  final double totalAmount;
  final String? imagePath;
  final bool isSynced;
  final bool isPaid;

  Bill({this.id, required this.customerId, this.customerName, this.customerCode, required this.billCode, required this.date, required this.oldReading, required this.newReading, required this.consumption, required this.unitPrice, required this.amount, required this.vat, required this.totalAmount, this.imagePath, this.isSynced = false, this.isPaid = false});

  Map<String, dynamic> toMap() => {
    'id': id, 'customerId': customerId, 'customerName': customerName, 'customerCode': customerCode, 'billCode': billCode, 'date': date.toIso8601String(), 'oldReading': oldReading, 'newReading': newReading, 'consumption': consumption, 'unitPrice': unitPrice, 'amount': amount, 'vat': vat, 'totalAmount': totalAmount, 'imagePath': imagePath, 'isSynced': isSynced ? 1 : 0, 'isPaid': isPaid ? 1 : 0,
  };

  factory Bill.fromMap(Map<String, dynamic> map) => Bill(
    id: map['id'],
    customerId: map['customerId'],
    customerName: map['customerName'],
    customerCode: map['customerCode'],
    billCode: map['billCode'] ?? '',
    date: DateTime.parse(map['date']),
    oldReading: map['oldReading'],
    newReading: map['newReading'],
    consumption: (map['consumption'] as num).toDouble(),
    unitPrice: (map['unitPrice'] as num).toDouble(),
    amount: (map['amount'] as num).toDouble(),
    vat: (map['vat'] as num).toDouble(),
    totalAmount: (map['totalAmount'] as num).toDouble(),
    imagePath: map['imagePath'],
    isSynced: map['isSynced'] == 1 || map['isSynced'] == true || map['synced'] == 1 || map['synced'] == true,
    isPaid: map['isPaid'] == 1 || map['isPaid'] == true || map['paid'] == 1 || map['paid'] == true,
  );

  Bill copyWith({int? id, int? customerId, String? customerName, String? customerCode, String? billCode, DateTime? date, int? oldReading, int? newReading, double? consumption, double? unitPrice, double? amount, double? vat, double? totalAmount, String? imagePath, bool? isSynced, bool? isPaid}) {
    return Bill(
      id: id ?? this.id, customerId: customerId ?? this.customerId, customerName: customerName ?? this.customerName, customerCode: customerCode ?? this.customerCode, billCode: billCode ?? this.billCode, date: date ?? this.date, oldReading: oldReading ?? this.oldReading, newReading: newReading ?? this.newReading, consumption: consumption ?? this.consumption, unitPrice: unitPrice ?? this.unitPrice, amount: amount ?? this.amount, vat: vat ?? this.vat, totalAmount: totalAmount ?? this.totalAmount, imagePath: imagePath ?? this.imagePath, isSynced: isSynced ?? this.isSynced, isPaid: isPaid ?? this.isPaid,
    );
  }
}
