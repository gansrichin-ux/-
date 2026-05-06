import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/role_permissions.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // Legacy fallback
  final List<String> roles; // Modern array-based roles
  final String? companyId;
  final String? preferredLanguage;
  final String? username;
  final String? name;
  final String? car;
  final String? fcmToken;
  final String? avatarUrl;
  final String? aboutMe;
  final int ratingCount;
  final int ratingSum;
  final bool emailCodeVerified;

  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.roles = const [],
    this.companyId,
    this.preferredLanguage,
    this.username,
    this.name,
    this.car,
    this.fcmToken,
    this.avatarUrl,
    this.aboutMe,
    this.ratingCount = 0,
    this.ratingSum = 0,
    this.emailCodeVerified = false,
  });

  bool get isDriver => RolePermissions.hasRole(this, RolePermissions.driver);
  bool get isLogistician => RolePermissions.hasRole(this, RolePermissions.logistician);
  bool get isAdmin => RolePermissions.hasRole(this, RolePermissions.admin);

  // Business logic getters
  bool get canCreateCargo => RolePermissions.canCreateCargo(this);
  bool get canApplyToCargo => RolePermissions.canApplyToCargo(this);
  bool get canManageUsers => RolePermissions.canManageUsers(this);

  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    List<String>? roles,
    String? companyId,
    String? preferredLanguage,
    String? username,
    String? name,
    String? car,
    String? fcmToken,
    String? avatarUrl,
    String? aboutMe,
    int? ratingCount,
    int? ratingSum,
    bool? emailCodeVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      companyId: companyId ?? this.companyId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      username: username ?? this.username,
      name: name ?? this.name,
      car: car ?? this.car,
      fcmToken: fcmToken ?? this.fcmToken,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      aboutMe: aboutMe ?? this.aboutMe,
      ratingCount: ratingCount ?? this.ratingCount,
      ratingSum: ratingSum ?? this.ratingSum,
      emailCodeVerified: emailCodeVerified ?? this.emailCodeVerified,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return UserModel(uid: doc.id, email: '', role: 'logistician', roles: ['logistician']);
    }
    
    // Support legacy documents where 'roles' doesn't exist yet
    final legacyRole = data['role'] as String? ?? 'logistician';
    final parsedRoles = data['roles'] as List<dynamic>?;
    final List<String> currentRoles = parsedRoles != null 
        ? parsedRoles.map((e) => e.toString()).toList()
        : [legacyRole];

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      role: legacyRole,
      roles: currentRoles,
      companyId: data['companyId'] as String?,
      preferredLanguage: data['preferredLanguage'] as String?,
      username: data['username'] as String?,
      name: data['name'] as String?,
      car: data['car'] as String?,
      fcmToken: data['fcmToken'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      aboutMe: data['aboutMe'] as String?,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      ratingSum: (data['ratingSum'] as num?)?.toInt() ?? 0,
      emailCodeVerified: data['emailCodeVerified'] as bool? ?? false,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final legacyRole = map['role'] as String? ?? 'logistician';
    final parsedRoles = map['roles'] as List<dynamic>?;
    final List<String> currentRoles = parsedRoles != null 
        ? parsedRoles.map((e) => e.toString()).toList()
        : [legacyRole];

    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      role: legacyRole,
      roles: currentRoles,
      companyId: map['companyId'] as String?,
      preferredLanguage: map['preferredLanguage'] as String?,
      username: map['username'] as String?,
      name: map['name'] as String?,
      car: map['car'] as String?,
      fcmToken: map['fcmToken'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      aboutMe: map['aboutMe'] as String?,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      ratingSum: (map['ratingSum'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'roles': roles.isEmpty ? [role] : roles,
      if (companyId != null) 'companyId': companyId,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
      if (username != null) 'username': username,
      if (username != null) 'usernameLower': username!.toLowerCase(),
      if (name != null) 'name': name,
      if (car != null) 'car': car,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (aboutMe != null) 'aboutMe': aboutMe,
      'ratingCount': ratingCount,
      'ratingSum': ratingSum,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String get displayName => name ?? email;
  String get profileSlug {
    if (username?.isNotEmpty == true) return username!;
    final length = uid.length < 6 ? uid.length : 6;
    return uid.substring(0, length).toLowerCase();
  }

  String get displayUsername {
    if (username?.isNotEmpty == true) return '@$username';
    return '@$profileSlug';
  }

  String get displayRole {
    // If the user has a primary modern role in `roles`, use it.
    // Otherwise fallback to old display logic.
    final effectiveRole = roles.isNotEmpty ? roles.first : role;

    switch (effectiveRole) {
      case 'logistician': return 'Логист';
      case 'driver': return 'Водитель';
      case 'forwarder': return 'Экспедитор';
      case 'cargo_owner': return 'Грузовладелец';
      case 'driver_forwarder': return 'Водитель-экспедитор';
      case 'driver_cargo_owner': return 'Водитель-Грузовладелец';
      case 'admin': return 'Администратор';
      default: return isDriver ? 'Водитель' : 'Логист';
    }
  }

  double get rating => ratingCount == 0 ? 0 : ratingSum / ratingCount;
}
