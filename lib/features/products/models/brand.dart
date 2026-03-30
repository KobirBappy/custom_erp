class Brand {
  const Brand({
    required this.id,
    required this.businessId,
    required this.name,
    this.description = '',
  });

  final String id;
  final String businessId;
  final String name;
  final String description;

  Brand copyWith({String? name, String? description}) {
    return Brand(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  factory Brand.fromMap(Map<String, dynamic> map, String id) {
    return Brand(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'name': name,
        'description': description,
      };
}
