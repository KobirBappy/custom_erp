import '../../purchases/models/purchase.dart' show PaymentStatus;

export '../../purchases/models/purchase.dart' show PaymentStatus;

enum SaleStatus { draft, final_ }

class SaleLine {
  const SaleLine({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.unitPrice,
    this.taxPercent = 0.0,
    this.discount = 0.0,
  });

  final String productId;
  final String productName;
  final String sku;
  final double qty;
  final double unitPrice;
  final double taxPercent;
  final double discount;

  double get subTotal => qty * unitPrice;
  double get taxAmount => subTotal * taxPercent / 100;
  double get lineTotal => subTotal + taxAmount - discount;

  SaleLine copyWith(
      {double? qty, double? unitPrice, double? taxPercent, double? discount}) {
    return SaleLine(
      productId: productId,
      productName: productName,
      sku: sku,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      taxPercent: taxPercent ?? this.taxPercent,
      discount: discount ?? this.discount,
    );
  }

  factory SaleLine.fromMap(Map<String, dynamic> map) {
    return SaleLine(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      qty: (map['qty'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'qty': qty,
        'unitPrice': unitPrice,
        'taxPercent': taxPercent,
        'discount': discount,
        'lineTotal': lineTotal,
      };
}

class Sale {
  const Sale({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.saleDate,
    this.invoiceNo = '',
    this.customerId = '',
    this.customerName = 'Walk-In Customer',
    this.cashierId = '',
    this.status = SaleStatus.final_,
    this.paymentStatus = PaymentStatus.paid,
    this.paymentMethod = 'cash',
    this.lines = const [],
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.transportCost = 0.0,
    this.paidAmount = 0.0,
    this.notes = '',
    this.isSynced = false,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String locationId;
  final DateTime saleDate;
  final String invoiceNo;
  final String customerId;
  final String customerName;
  final String cashierId;
  final SaleStatus status;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final List<SaleLine> lines;
  final double discountAmount;
  final double taxAmount;
  final double transportCost;
  final double paidAmount;
  final String notes;
  final bool isSynced;
  final DateTime? createdAt;

  double get subTotal => lines.fold(0.0, (sum, l) => sum + l.qty * l.unitPrice);
  double get grandTotal => subTotal + taxAmount - discountAmount;
  double get dueAmount => grandTotal - paidAmount;
  int get totalItems => lines.fold(0, (sum, l) => sum + l.qty.toInt());

  Sale copyWith({
    String? invoiceNo,
    String? customerId,
    String? customerName,
    SaleStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    List<SaleLine>? lines,
    double? discountAmount,
    double? taxAmount,
    double? transportCost,
    double? paidAmount,
    String? notes,
    bool? isSynced,
  }) {
    return Sale(
      id: id,
      businessId: businessId,
      locationId: locationId,
      saleDate: saleDate,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      cashierId: cashierId,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      lines: lines ?? this.lines,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      transportCost: transportCost ?? this.transportCost,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
    );
  }

  factory Sale.fromMap(Map<String, dynamic> map, String id) {
    final linesList = (map['lines'] as List<dynamic>? ?? [])
        .map((e) => SaleLine.fromMap(e as Map<String, dynamic>))
        .toList();
    return Sale(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      locationId: map['locationId'] as String? ?? '',
      saleDate:
          DateTime.tryParse(map['saleDate'] as String? ?? '') ?? DateTime.now(),
      invoiceNo: map['invoiceNo'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Walk-In Customer',
      cashierId: map['cashierId'] as String? ?? '',
      status: SaleStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'final_'),
        orElse: () => SaleStatus.final_,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (map['paymentStatus'] as String? ?? 'paid'),
        orElse: () => PaymentStatus.paid,
      ),
      paymentMethod: map['paymentMethod'] as String? ?? 'cash',
      lines: linesList,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      transportCost: (map['transportCost'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String? ?? '',
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'locationId': locationId,
      'saleDate': saleDate.toIso8601String(),
      'invoiceNo': invoiceNo,
      'customerId': customerId,
      'customerName': customerName,
      'cashierId': cashierId,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod,
      'lines': lines.map((l) => l.toMap()).toList(),
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'transportCost': transportCost,
      'grandTotal': grandTotal,
      'paidAmount': paidAmount,
      'notes': notes,
      'isSynced': isSynced,
    };
  }
}
