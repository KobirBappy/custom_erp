enum PurchaseStatus { ordered, pending, received }

enum PaymentStatus { paid, due, partial }

class PurchaseLine {
  const PurchaseLine({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.unitCost,
    this.taxPercent = 0.0,
    this.discount = 0.0,
  });

  final String productId;
  final String productName;
  final String sku;
  final double qty;
  final double unitCost;
  final double taxPercent;
  final double discount;

  double get subTotal => qty * unitCost;
  double get taxAmount => subTotal * taxPercent / 100;
  double get lineTotal => subTotal + taxAmount - discount;

  PurchaseLine copyWith({double? qty, double? unitCost, double? taxPercent, double? discount}) {
    return PurchaseLine(
      productId: productId,
      productName: productName,
      sku: sku,
      qty: qty ?? this.qty,
      unitCost: unitCost ?? this.unitCost,
      taxPercent: taxPercent ?? this.taxPercent,
      discount: discount ?? this.discount,
    );
  }

  factory PurchaseLine.fromMap(Map<String, dynamic> map) {
    return PurchaseLine(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      qty: (map['qty'] as num?)?.toDouble() ?? 1.0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'qty': qty,
        'unitCost': unitCost,
        'taxPercent': taxPercent,
        'discount': discount,
        'lineTotal': lineTotal,
      };
}

class Purchase {
  const Purchase({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.supplierId,
    required this.supplierName,
    required this.purchaseDate,
    this.referenceNo = '',
    this.status = PurchaseStatus.received,
    this.paymentStatus = PaymentStatus.due,
    this.lines = const [],
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.shippingCost = 0.0,
    this.paidAmount = 0.0,
    this.notes = '',
    this.dueDate,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String locationId;
  final String supplierId;
  final String supplierName;
  final DateTime purchaseDate;
  final String referenceNo;
  final PurchaseStatus status;
  final PaymentStatus paymentStatus;
  final List<PurchaseLine> lines;
  final double discountAmount;
  final double taxAmount;
  final double shippingCost;
  final double paidAmount;
  final String notes;
  final DateTime? dueDate;
  final DateTime? createdAt;

  double get subTotal =>
      lines.fold(0.0, (sum, l) => sum + l.qty * l.unitCost);
  double get grandTotal =>
      subTotal + taxAmount + shippingCost - discountAmount;
  double get dueAmount => grandTotal - paidAmount;

  Purchase copyWith({
    String? locationId,
    String? supplierId,
    String? supplierName,
    DateTime? purchaseDate,
    String? referenceNo,
    PurchaseStatus? status,
    PaymentStatus? paymentStatus,
    List<PurchaseLine>? lines,
    double? discountAmount,
    double? taxAmount,
    double? shippingCost,
    double? paidAmount,
    String? notes,
    DateTime? dueDate,
  }) {
    return Purchase(
      id: id,
      businessId: businessId,
      locationId: locationId ?? this.locationId,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      referenceNo: referenceNo ?? this.referenceNo,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      lines: lines ?? this.lines,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
    );
  }

  factory Purchase.fromMap(Map<String, dynamic> map, String id) {
    final linesList = (map['lines'] as List<dynamic>? ?? [])
        .map((e) => PurchaseLine.fromMap(e as Map<String, dynamic>))
        .toList();
    return Purchase(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      locationId: map['locationId'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      supplierName: map['supplierName'] as String? ?? '',
      purchaseDate: DateTime.tryParse(map['purchaseDate'] as String? ?? '') ??
          DateTime.now(),
      referenceNo: map['referenceNo'] as String? ?? '',
      status: PurchaseStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'received'),
        orElse: () => PurchaseStatus.received,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (map['paymentStatus'] as String? ?? 'due'),
        orElse: () => PaymentStatus.due,
      ),
      lines: linesList,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (map['shippingCost'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'locationId': locationId,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'referenceNo': referenceNo,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'lines': lines.map((l) => l.toMap()).toList(),
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'shippingCost': shippingCost,
      'grandTotal': grandTotal,
      'paidAmount': paidAmount,
      'notes': notes,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
