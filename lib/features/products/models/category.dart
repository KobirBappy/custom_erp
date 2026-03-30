class Category {
  const Category({
    required this.id,
    required this.businessId,
    required this.name,
    this.parentId,
    this.description = '',
  });

  final String id;
  final String businessId;
  final String name;
  final String? parentId;
  final String description;

  bool get isSubCategory => parentId != null && parentId!.isNotEmpty;

  Category copyWith({String? name, String? parentId, String? description}) {
    return Category(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      description: description ?? this.description,
    );
  }

  factory Category.fromMap(Map<String, dynamic> map, String id) {
    return Category(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      parentId: map['parentId'] as String?,
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'name': name,
        'parentId': parentId,
        'description': description,
      };
}
