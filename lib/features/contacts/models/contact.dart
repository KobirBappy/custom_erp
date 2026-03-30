enum ContactType { customer, supplier, both }

class Contact {
  const Contact({
    required this.id,
    required this.businessId,
    required this.name,
    this.type = ContactType.customer,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.taxNumber = '',
    this.openingBalance = 0.0,
    this.creditBalance = 0.0,
    this.debitBalance = 0.0,
    this.payTermDays = 0,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String name;
  final ContactType type;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String taxNumber;
  final double openingBalance;
  final double creditBalance;
  final double debitBalance;
  final int payTermDays;
  final bool isActive;
  final DateTime? createdAt;

  double get balance => debitBalance - creditBalance;

  String get typeLabel {
    switch (type) {
      case ContactType.customer:
        return 'Customer';
      case ContactType.supplier:
        return 'Supplier';
      case ContactType.both:
        return 'Customer & Supplier';
    }
  }

  Contact copyWith({
    String? name,
    ContactType? type,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? taxNumber,
    double? openingBalance,
    double? creditBalance,
    double? debitBalance,
    int? payTermDays,
    bool? isActive,
  }) {
    return Contact(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      taxNumber: taxNumber ?? this.taxNumber,
      openingBalance: openingBalance ?? this.openingBalance,
      creditBalance: creditBalance ?? this.creditBalance,
      debitBalance: debitBalance ?? this.debitBalance,
      payTermDays: payTermDays ?? this.payTermDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  factory Contact.fromMap(Map<String, dynamic> map, String id) {
    return Contact(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: ContactType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'customer'),
        orElse: () => ContactType.customer,
      ),
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      taxNumber: map['taxNumber'] as String? ?? '',
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      creditBalance: (map['creditBalance'] as num?)?.toDouble() ?? 0.0,
      debitBalance: (map['debitBalance'] as num?)?.toDouble() ?? 0.0,
      payTermDays: map['payTermDays'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'name': name,
      'type': type.name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'taxNumber': taxNumber,
      'openingBalance': openingBalance,
      'creditBalance': creditBalance,
      'debitBalance': debitBalance,
      'payTermDays': payTermDays,
      'isActive': isActive,
    };
  }
}
