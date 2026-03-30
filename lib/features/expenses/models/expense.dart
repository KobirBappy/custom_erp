class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.businessId,
    required this.name,
    this.description = '',
  });

  final String id;
  final String businessId;
  final String name;
  final String description;

  factory ExpenseCategory.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseCategory(
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

class Expense {
  const Expense({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.date,
    this.paymentMethod = 'cash',
    this.note = '',
    this.receiptUrl,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String locationId;
  final String categoryId;
  final String categoryName;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String note;
  final String? receiptUrl;
  final DateTime? createdAt;

  Expense copyWith({
    String? locationId,
    String? categoryId,
    String? categoryName,
    double? amount,
    DateTime? date,
    String? paymentMethod,
    String? note,
    String? receiptUrl,
  }) {
    return Expense(
      id: id,
      businessId: businessId,
      locationId: locationId ?? this.locationId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt,
    );
  }

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      locationId: map['locationId'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] as String? ?? 'cash',
      note: map['note'] as String? ?? '',
      receiptUrl: map['receiptUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'locationId': locationId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'amount': amount,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
        'note': note,
        'receiptUrl': receiptUrl,
      };
}
