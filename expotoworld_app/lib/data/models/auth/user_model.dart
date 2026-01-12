/// User Model
/// 
/// Represents an authenticated user in the system.
/// Maps to the app_users table in the database.
library;

/// User role enumeration
enum UserRole {
  customer,
  admin;

  factory UserRole.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.customer:
        return 'Customer';
    }
  }
}

/// User status enumeration
enum UserStatus {
  active,
  inactive,
  banned;

  factory UserStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'inactive':
        return UserStatus.inactive;
      case 'banned':
        return UserStatus.banned;
      case 'active':
      default:
        return UserStatus.active;
    }
  }
}

/// User model representing an authenticated user
class UserModel {
  /// Unique user identifier (UUID)
  final String id;

  /// Username (often set to email initially)
  final String username;

  /// User's email address
  final String? email;

  /// User's phone number
  final String? phone;

  /// First name
  final String? firstName;

  /// Middle name
  final String? middleName;

  /// Last name
  final String? lastName;

  /// User role (Customer or Admin)
  final UserRole role;

  /// Account status
  final UserStatus status;

  /// Last login timestamp
  final DateTime? lastLogin;

  /// Account creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    this.firstName,
    this.middleName,
    this.lastName,
    required this.role,
    required this.status,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get display name (full name or username)
  String get displayName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (middleName != null && middleName!.isNotEmpty) parts.add(middleName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    return username;
  }

  /// Get initials for avatar
  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      final first = firstName![0].toUpperCase();
      if (lastName != null && lastName!.isNotEmpty) {
        return '$first${lastName![0].toUpperCase()}';
      }
      return first;
    }
    if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }
    return '?';
  }

  /// Check if user is active
  bool get isActive => status == UserStatus.active;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Create from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'Customer'),
      status: UserStatus.fromString(json['status'] as String? ?? 'active'),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'role': role.name,
      'status': status.name,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a minimal user from JWT payload
  factory UserModel.fromJwt({
    required String id,
    String? email,
    String? phone,
    String? role,
  }) {
    final now = DateTime.now();
    // For username, prefer email, then phone (stripped of +), then id
    String username = id;
    if (email != null && email.isNotEmpty) {
      username = email;
    } else if (phone != null && phone.isNotEmpty) {
      // Create username from phone: user + digits only
      username = 'user${phone.replaceAll(RegExp(r'[^\d]'), '')}';
    }
    
    return UserModel(
      id: id,
      username: username,
      email: email,
      phone: phone,
      role: UserRole.fromString(role ?? 'Customer'),
      status: UserStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with updated fields
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? firstName,
    String? middleName,
    String? lastName,
    UserRole? role,
    UserStatus? status,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
