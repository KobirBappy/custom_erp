class Business {
  const Business({
    required this.id,
    required this.name,
    this.logoUrl,
    this.currencySymbol = '৳',
    this.currencyCode = 'BDT',
    this.timezone = 'Asia/Dhaka',
    this.financialYearStart = 1,
    this.defaultProfitMargin = 0.0,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.taxNumber = '',
    this.ownerId = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String currencySymbol;
  final String currencyCode;
  final String timezone;
  final int financialYearStart; // month number 1-12
  final double defaultProfitMargin;
  final String phone;
  final String email;
  final String address;
  final String taxNumber;
  final String ownerId;
  final DateTime? createdAt;

  Business copyWith({
    String? name,
    String? logoUrl,
    String? currencySymbol,
    String? currencyCode,
    String? timezone,
    int? financialYearStart,
    double? defaultProfitMargin,
    String? phone,
    String? email,
    String? address,
    String? taxNumber,
  }) {
    return Business(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      timezone: timezone ?? this.timezone,
      financialYearStart: financialYearStart ?? this.financialYearStart,
      defaultProfitMargin: defaultProfitMargin ?? this.defaultProfitMargin,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      ownerId: ownerId,
      createdAt: createdAt,
    );
  }

  factory Business.fromMap(Map<String, dynamic> map, String id) {
    return Business(
      id: id,
      name: map['name'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      currencySymbol: map['currencySymbol'] as String? ?? '৳',
      currencyCode: map['currencyCode'] as String? ?? 'BDT',
      timezone: map['timezone'] as String? ?? 'Asia/Dhaka',
      financialYearStart: map['financialYearStart'] as int? ?? 1,
      defaultProfitMargin:
          (map['defaultProfitMargin'] as num?)?.toDouble() ?? 0.0,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      taxNumber: map['taxNumber'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'currencySymbol': currencySymbol,
      'currencyCode': currencyCode,
      'timezone': timezone,
      'financialYearStart': financialYearStart,
      'defaultProfitMargin': defaultProfitMargin,
      'phone': phone,
      'email': email,
      'address': address,
      'taxNumber': taxNumber,
      'ownerId': ownerId,
    };
  }
}
