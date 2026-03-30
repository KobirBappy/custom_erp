import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessUser {
  const BusinessUser({
    required this.id,
    required this.businessId,
    required this.name,
    required this.email,
    this.role = 'cashier',
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  BusinessUser copyWith({
    String? name,
    String? email,
    String? role,
    bool? isActive,
  }) {
    return BusinessUser(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  factory BusinessUser.fromMap(Map<String, dynamic> map, String id, String businessId) {
    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return BusinessUser(
      id: id,
      businessId: businessId,
      name: map['name'] as String? ?? map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'cashier',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'isActive': isActive,
      };
}
