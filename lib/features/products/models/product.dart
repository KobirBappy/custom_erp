enum ProductType { single, variable }

class ProductVariation {
  const ProductVariation({
    this.id = '',
    required this.name,
    this.sku = '',
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.stockQuantity = 0.0,
    this.alertQuantity = 5.0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String sku;
  final double purchasePrice;
  final double sellingPrice;
  final double stockQuantity;
  final double alertQuantity;
  final bool isActive;

  bool get isLowStock => stockQuantity <= alertQuantity;

  factory ProductVariation.fromMap(Map<String, dynamic> map) {
    return ProductVariation(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      alertQuantity: (map['alertQuantity'] as num?)?.toDouble() ?? 5.0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'alertQuantity': alertQuantity,
      'isActive': isActive,
    };
  }
}

class Product {
  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    this.sku = '',
    this.type = ProductType.single,
    this.locationId,
    this.categoryId,
    this.brandId,
    this.unitId,
    this.description = '',
    this.imageUrl,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.taxPercent = 0.0,
    this.stockQuantity = 0.0,
    this.stockByLocation = const {},
    this.alertQuantity = 5.0,
    this.variations = const [],
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String sku;
  final ProductType type;
  final String? locationId;
  final String? categoryId;
  final String? brandId;
  final String? unitId;
  final String description;
  final String? imageUrl;
  final double purchasePrice;
  final double sellingPrice;
  final double taxPercent;
  final double stockQuantity;
  final Map<String, double> stockByLocation;
  final double alertQuantity;
  final List<ProductVariation> variations;
  final bool isActive;
  final DateTime? createdAt;

  bool get isLowStock {
    if (type == ProductType.variable && variations.isNotEmpty) {
      return variations.any((v) => v.isLowStock);
    }
    return stockQuantity <= alertQuantity;
  }

  double stockForLocation(String? branchId) {
    if (branchId == null || branchId.isEmpty) {
      return stockQuantity;
    }
    if (stockByLocation.containsKey(branchId)) {
      return stockByLocation[branchId] ?? 0.0;
    }
    if (locationId == branchId) {
      return stockQuantity;
    }
    return 0.0;
  }

  double get totalVariationStock => variations.fold(
        0.0,
        (sum, v) => sum + v.stockQuantity,
      );

  double get profitMargin => sellingPrice > 0
      ? ((sellingPrice - purchasePrice) / sellingPrice) * 100
      : 0;

  Product copyWith({
    String? name,
    String? sku,
    ProductType? type,
    String? locationId,
    String? categoryId,
    String? brandId,
    String? unitId,
    String? description,
    String? imageUrl,
    double? purchasePrice,
    double? sellingPrice,
    double? taxPercent,
    double? stockQuantity,
    Map<String, double>? stockByLocation,
    double? alertQuantity,
    List<ProductVariation>? variations,
    bool? isActive,
  }) {
    return Product(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      type: type ?? this.type,
      locationId: locationId ?? this.locationId,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      unitId: unitId ?? this.unitId,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      taxPercent: taxPercent ?? this.taxPercent,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockByLocation: stockByLocation ?? this.stockByLocation,
      alertQuantity: alertQuantity ?? this.alertQuantity,
      variations: variations ?? this.variations,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    final rawVariations = map['variations'];
    final variations = rawVariations is List
        ? rawVariations
            .whereType<Map>()
            .map(
              (v) => ProductVariation.fromMap(
                Map<String, dynamic>.from(v),
              ),
            )
            .toList()
        : const <ProductVariation>[];
    final rawStockByLocation = map['stockByLocation'];
    final stockByLocation = <String, double>{};
    if (rawStockByLocation is Map) {
      rawStockByLocation.forEach((k, v) {
        stockByLocation[k.toString()] = (v as num?)?.toDouble() ?? 0.0;
      });
    }

    return Product(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      type: ProductType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'single'),
        orElse: () => ProductType.single,
      ),
      locationId: map['locationId'] as String?,
      categoryId: map['categoryId'] as String?,
      brandId: map['brandId'] as String?,
      unitId: map['unitId'] as String?,
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      stockByLocation: stockByLocation,
      alertQuantity: (map['alertQuantity'] as num?)?.toDouble() ?? 5.0,
      variations: variations,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'name': name,
      'sku': sku,
      'type': type.name,
      'locationId': locationId,
      'categoryId': categoryId,
      'brandId': brandId,
      'unitId': unitId,
      'description': description,
      'imageUrl': imageUrl,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'taxPercent': taxPercent,
      'stockQuantity': stockQuantity,
      'stockByLocation': stockByLocation,
      'alertQuantity': alertQuantity,
      'variations': variations.map((v) => v.toMap()).toList(),
      'isActive': isActive,
    };
  }
}
