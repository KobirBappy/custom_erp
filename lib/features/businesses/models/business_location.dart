enum LocationType { storefront, warehouse, office }

class BusinessLocation {
  const BusinessLocation({
    required this.id,
    required this.businessId,
    required this.name,
    this.type = LocationType.storefront,
    this.address = '',
    this.city = '',
    this.phone = '',
    this.invoicePrefix = '',
    this.isActive = true,
  });

  final String id;
  final String businessId;
  final String name;
  final LocationType type;
  final String address;
  final String city;
  final String phone;
  final String invoicePrefix;
  final bool isActive;

  BusinessLocation copyWith({
    String? name,
    LocationType? type,
    String? address,
    String? city,
    String? phone,
    String? invoicePrefix,
    bool? isActive,
  }) {
    return BusinessLocation(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      isActive: isActive ?? this.isActive,
    );
  }

  factory BusinessLocation.fromMap(Map<String, dynamic> map, String id) {
    return BusinessLocation(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: LocationType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'storefront'),
        orElse: () => LocationType.storefront,
      ),
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      invoicePrefix: map['invoicePrefix'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'name': name,
      'type': type.name,
      'address': address,
      'city': city,
      'phone': phone,
      'invoicePrefix': invoicePrefix,
      'isActive': isActive,
    };
  }
}
