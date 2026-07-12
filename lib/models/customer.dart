class Customer {
  final int? id;
  final String code;
  final String name;
  final String address;
  final String phone;
  final int currentReading;

  Customer({this.id, required this.code, required this.name, required this.address, required this.phone, required this.currentReading});

  Map<String, dynamic> toMap() => {
    'id': id, 'code': code, 'name': name, 'address': address, 'phone': phone, 'currentReading': currentReading,
  };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
    id: map['id'],
    code: map['code'] ?? '',
    name: map['name'] ?? '',
    address: map['address'] ?? '',
    phone: map['phone'] ?? '',
    currentReading: map['currentReading'] ?? 0,
  );

  Customer copyWith({int? id, String? code, String? name, String? address, String? phone, int? currentReading}) {
    return Customer(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      currentReading: currentReading ?? this.currentReading,
    );
  }
}
