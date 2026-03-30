class StockTransfer {
  const StockTransfer({
    required this.id,
    required this.businessId,
    required this.productId,
    required this.productName,
    required this.fromLocationId,
    required this.fromLocationName,
    required this.toLocationId,
    required this.toLocationName,
    required this.qty,
    required this.transferDate,
    this.note = '',
    this.createdBy = '',
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String productId;
  final String productName;
  final String fromLocationId;
  final String fromLocationName;
  final String toLocationId;
  final String toLocationName;
  final double qty;
  final DateTime transferDate;
  final String note;
  final String createdBy;
  final DateTime? createdAt;

  factory StockTransfer.fromMap(Map<String, dynamic> map, String id) {
    return StockTransfer(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      fromLocationId: map['fromLocationId'] as String? ?? '',
      fromLocationName: map['fromLocationName'] as String? ?? '',
      toLocationId: map['toLocationId'] as String? ?? '',
      toLocationName: map['toLocationName'] as String? ?? '',
      qty: (map['qty'] as num?)?.toDouble() ?? 0.0,
      transferDate: DateTime.tryParse(map['transferDate'] as String? ?? '') ??
          DateTime.now(),
      note: map['note'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'productId': productId,
      'productName': productName,
      'fromLocationId': fromLocationId,
      'fromLocationName': fromLocationName,
      'toLocationId': toLocationId,
      'toLocationName': toLocationName,
      'qty': qty,
      'transferDate': transferDate.toIso8601String(),
      'note': note,
      'createdBy': createdBy,
    };
  }
}
