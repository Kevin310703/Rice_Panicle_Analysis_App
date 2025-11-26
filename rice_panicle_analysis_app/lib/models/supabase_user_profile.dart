class SupabaseUserProfile {
  final String? id;
  final String username;
  final String passwordHash;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? imageProfileUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool flag;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final bool isActive;

  const SupabaseUserProfile({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.imageProfileUrl,
    this.createdAt,
    this.updatedAt,
    this.flag = false,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.isActive = false,
  });

  factory SupabaseUserProfile.fromMap(Map<String, dynamic> data) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return SupabaseUserProfile(
      id: data['id']?.toString(),
      username: data['username'] as String? ?? '',
      passwordHash: data['password_hash'] as String? ?? '',
      fullName: data['full_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phone_number'] as String?,
      imageProfileUrl: data['image_profile_url'] as String?,
      createdAt: _parseDate(data['created_at']),
      updatedAt: _parseDate(data['updated_at']),
      flag: data['flag'] as bool? ?? false,
      dateOfBirth: _parseDate(data['date_of_birth']),
      gender: data['gender'] as String?,
      address: data['address'] as String?,
      isActive: data['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'image_profile_url': imageProfileUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'is_active': isActive,
      'flag': flag,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'image_profile_url': imageProfileUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'is_active': isActive,
      'flag': flag,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  SupabaseUserProfile copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? imageProfileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? flag,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    bool? isActive,
  }) {
    return SupabaseUserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageProfileUrl: imageProfileUrl ?? this.imageProfileUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      flag: flag ?? this.flag,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }
}
