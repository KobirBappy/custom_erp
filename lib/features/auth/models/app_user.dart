class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = 'admin',
    this.businessIds = const [],
    this.currentBusinessId,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role;
  final List<String> businessIds;
  final String? currentBusinessId;

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
    List<String>? businessIds,
    String? currentBusinessId,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      businessIds: businessIds ?? this.businessIds,
      currentBusinessId: currentBusinessId ?? this.currentBusinessId,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String? ?? 'cashier',
      businessIds: List<String>.from(map['businessIds'] as List? ?? []),
      currentBusinessId: map['currentBusinessId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'businessIds': businessIds,
      'currentBusinessId': currentBusinessId,
    };
  }
}
