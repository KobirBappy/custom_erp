class ReturnEntry {
  const ReturnEntry({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.referenceId,
    required this.referenceNo,
    required this.partyId,
    required this.partyName,
    required this.amount,
    required this.paidAmount,
    required this.date,
    this.reason = '',
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String locationId;
  final String referenceId;
  final String referenceNo;
  final String partyId;
  final String partyName;
  final double amount;
  final double paidAmount;
  final DateTime date;
  final String reason;
  final DateTime? createdAt;

  double get dueAmount => amount - paidAmount;

  ReturnEntry copyWith({
    double? paidAmount,
    double? amount,
    String? reason,
  }) {
    return ReturnEntry(
      id: id,
      businessId: businessId,
      locationId: locationId,
      referenceId: referenceId,
      referenceNo: referenceNo,
      partyId: partyId,
      partyName: partyName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      date: date,
      reason: reason ?? this.reason,
      createdAt: createdAt,
    );
  }

  factory ReturnEntry.fromMap(Map<String, dynamic> map, String id) {
    return ReturnEntry(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      locationId: map['locationId'] as String? ?? '',
      referenceId: map['referenceId'] as String? ?? '',
      referenceNo: map['referenceNo'] as String? ?? '',
      partyId: map['partyId'] as String? ?? '',
      partyName: map['partyName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      reason: map['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'locationId': locationId,
        'referenceId': referenceId,
        'referenceNo': referenceNo,
        'partyId': partyId,
        'partyName': partyName,
        'amount': amount,
        'paidAmount': paidAmount,
        'date': date.toIso8601String(),
        'reason': reason,
      };
}
