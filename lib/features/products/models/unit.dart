class Unit {
  const Unit({
    required this.id,
    required this.businessId,
    required this.name,
    this.abbreviation = '',
    this.allowDecimals = false,
  });

  final String id;
  final String businessId;
  final String name;
  final String abbreviation;
  final bool allowDecimals;

  Unit copyWith({String? name, String? abbreviation, bool? allowDecimals}) {
    return Unit(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      allowDecimals: allowDecimals ?? this.allowDecimals,
    );
  }

  factory Unit.fromMap(Map<String, dynamic> map, String id) {
    return Unit(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      abbreviation: map['abbreviation'] as String? ?? '',
      allowDecimals: map['allowDecimals'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'name': name,
        'abbreviation': abbreviation,
        'allowDecimals': allowDecimals,
      };
}
