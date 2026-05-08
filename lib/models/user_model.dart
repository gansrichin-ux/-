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
  final String? profileStatus;
  final int? profileCompletenessPercent;
  final String? profileReviewComment;
  final bool onboardingCompleted;
  final int onboardingStep;
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
    this.profileStatus,
    this.profileCompletenessPercent,
    this.profileReviewComment,
    this.onboardingCompleted = false,
    this.onboardingStep = 0,
    this.ratingCount = 0,
    this.ratingSum = 0,
    this.emailCodeVerified = false,
  });

  bool get isCarrier =>
      RolePermissions.hasRole(this, RolePermissions.carrier) ||
      RolePermissions.hasRole(this, 'driver');
  bool get isLogistician =>
      RolePermissions.hasRole(this, RolePermissions.logistician);
  bool get isCargoOwner =>
      RolePermissions.hasRole(this, RolePermissions.cargoOwner);
  bool get isForwarder =>
      RolePermissions.hasRole(this, RolePermissions.forwarder);
  bool get isLawyer => RolePermissions.hasRole(this, RolePermissions.lawyer);
  bool get isCarrierForwarder =>
      RolePermissions.hasRole(this, RolePermissions.carrierForwarder) ||
      RolePermissions.hasRole(this, 'driver_forwarder');
  bool get isCargoOwnerCarrier =>
      RolePermissions.hasRole(this, RolePermissions.cargoOwnerCarrier) ||
      RolePermissions.hasRole(this, 'driver_cargo_owner');
  bool get isLogisticianCarrier =>
      RolePermissions.hasRole(this, RolePermissions.logisticianCarrier);
  bool get isAdmin => RolePermissions.hasRole(this, RolePermissions.admin);

  // Legacy compatibility
  bool get isDriver => isCarrier;

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
    String? profileStatus,
    int? profileCompletenessPercent,
    String? profileReviewComment,
    bool? onboardingCompleted,
    int? onboardingStep,
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
      profileStatus: profileStatus ?? this.profileStatus,
      profileCompletenessPercent:
          profileCompletenessPercent ?? this.profileCompletenessPercent,
      profileReviewComment: profileReviewComment ?? this.profileReviewComment,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      ratingCount: ratingCount ?? this.ratingCount,
      ratingSum: ratingSum ?? this.ratingSum,
      emailCodeVerified: emailCodeVerified ?? this.emailCodeVerified,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return UserModel(
          uid: doc.id, email: '', role: 'logistician', roles: ['logistician']);
    }

    // Support legacy documents where 'roles' doesn't exist yet
    final rawLegacyRole = data['role'] as String? ?? 'logistician';
    final parsedRoles = data['roles'] as List<dynamic>?;

    final normalizedRoles = normalizeRoles(
      parsedRoles?.map((e) => e.toString()).toList() ?? [],
      rawLegacyRole,
    );

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      role: normalizedRoles.isNotEmpty ? normalizedRoles.first : rawLegacyRole,
      roles: normalizedRoles,
      companyId: data['companyId'] as String?,
      preferredLanguage: data['preferredLanguage'] as String?,
      username: data['username'] as String?,
      name: data['name'] as String?,
      car: data['car'] as String?,
      fcmToken: data['fcmToken'] as String?,
      avatarUrl: (data['avatarUrl'] ?? data['photoURL'] ?? data['photoUrl'])
          as String?,
      aboutMe: data['aboutMe'] as String?,
      profileStatus: data['profileStatus'] as String?,
      profileCompletenessPercent:
          (data['profileCompletenessPercent'] as num?)?.toInt(),
      profileReviewComment: data['profileReviewComment'] as String?,
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      onboardingStep: (data['onboardingStep'] as num?)?.toInt() ?? 0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      ratingSum: (data['ratingSum'] as num?)?.toInt() ?? 0,
      emailCodeVerified: data['emailCodeVerified'] as bool? ?? false,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawLegacyRole = map['role'] as String? ?? 'logistician';
    final parsedRoles = map['roles'] as List<dynamic>?;

    final normalizedRoles = normalizeRoles(
      parsedRoles?.map((e) => e.toString()).toList() ?? [],
      rawLegacyRole,
    );

    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      role: normalizedRoles.isNotEmpty ? normalizedRoles.first : rawLegacyRole,
      roles: normalizedRoles,
      companyId: map['companyId'] as String?,
      preferredLanguage: map['preferredLanguage'] as String?,
      username: map['username'] as String?,
      name: map['name'] as String?,
      car: map['car'] as String?,
      fcmToken: map['fcmToken'] as String?,
      avatarUrl:
          (map['avatarUrl'] ?? map['photoURL'] ?? map['photoUrl']) as String?,
      aboutMe: map['aboutMe'] as String?,
      profileStatus: map['profileStatus'] as String?,
      profileCompletenessPercent:
          (map['profileCompletenessPercent'] as num?)?.toInt(),
      profileReviewComment: map['profileReviewComment'] as String?,
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      onboardingStep: (map['onboardingStep'] as num?)?.toInt() ?? 0,
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
      if (avatarUrl != null) 'photoURL': avatarUrl,
      if (aboutMe != null) 'aboutMe': aboutMe,
      if (profileStatus != null) 'profileStatus': profileStatus,
      if (profileCompletenessPercent != null)
        'profileCompletenessPercent': profileCompletenessPercent,
      if (profileReviewComment != null)
        'profileReviewComment': profileReviewComment,
      'onboardingCompleted': onboardingCompleted,
      'onboardingStep': onboardingStep,
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
    final effectiveRole =
        role.isNotEmpty ? role : (roles.isNotEmpty ? roles.first : '');

    switch (effectiveRole) {
      case 'carrier':
      case 'driver':
        return 'Перевозчик';
      case 'logistician':
        return 'Логист';
      case 'cargo_owner':
        return 'Грузовладелец';
      case 'forwarder':
        return 'Экспедитор';
      case 'lawyer':
        return 'Юрист';
      case 'carrier_forwarder':
      case 'driver_forwarder':
        return 'Перевозчик-Экспедитор';
      case 'cargo_owner_carrier':
      case 'driver_cargo_owner':
        return 'Грузовладелец-Перевозчик';
      case 'logistician_carrier':
        return 'Логист-Перевозчик';
      case 'admin':
        return 'Администратор';
      default:
        return isCarrier ? 'Перевозчик' : 'Логист';
    }
  }

  static List<String> normalizeRoles(List<String> roles, String? legacyRole) {
    final result = <String>{};

    // 1. Process array
    for (var r in roles) {
      result.add(_normalizeRoleKey(r));
    }

    // 2. Process legacy single role if array is empty
    if (result.isEmpty && legacyRole != null) {
      result.add(_normalizeRoleKey(legacyRole));
    }

    // 3. Handle hybrid role expansions
    // We clone the current set to avoid modification during iteration if we were using a list,
    // but with a set and explicit checks it's fine.
    if (result.contains('carrier_forwarder')) {
      result.add('carrier');
      result.add('forwarder');
    }
    if (result.contains('cargo_owner_carrier')) {
      result.add('cargo_owner');
      result.add('carrier');
    }
    if (result.contains('logistician_carrier')) {
      result.add('logistician');
      result.add('carrier');
    }

    return result.toList();
  }

  static String _normalizeRoleKey(String key) {
    switch (key) {
      case 'driver':
        return 'carrier';
      case 'driver_forwarder':
        return 'carrier_forwarder';
      case 'driver_cargo_owner':
        return 'cargo_owner_carrier';
      default:
        return key;
    }
  }

  double get rating => ratingCount == 0 ? 0 : ratingSum / ratingCount;

  int get calculatedProfileCompletenessPercent {
    final checks = <bool>[
      name?.trim().isNotEmpty == true,
      email.trim().isNotEmpty,
      roles.isNotEmpty || role.trim().isNotEmpty,
      username?.trim().isNotEmpty == true,
      aboutMe?.trim().isNotEmpty == true,
      avatarUrl?.trim().isNotEmpty == true,
      if (isCarrier) car?.trim().isNotEmpty == true,
      if (!isCarrier) companyId?.trim().isNotEmpty == true,
    ];
    if (checks.isEmpty) return 0;
    final filled = checks.where((value) => value).length;
    return ((filled / checks.length) * 100).round().clamp(0, 100).toInt();
  }

  int get effectiveProfileCompletenessPercent =>
      (profileCompletenessPercent ?? calculatedProfileCompletenessPercent)
          .clamp(0, 100)
          .toInt();

  String get effectiveProfileStatus {
    final stored = profileStatus?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return effectiveProfileCompletenessPercent >= 90
        ? 'verified'
        : 'profile_incomplete';
  }

  List<String> get profileMissingItems {
    final missing = <String>[];
    if (name?.trim().isNotEmpty != true) missing.add('имя');
    if (email.trim().isEmpty) missing.add('email');
    if (roles.isEmpty && role.trim().isEmpty) missing.add('роль');
    if (username?.trim().isNotEmpty != true) missing.add('логин');
    if (aboutMe?.trim().isNotEmpty != true) missing.add('описание');
    if (avatarUrl?.trim().isNotEmpty != true) missing.add('фото');
    if (isCarrier && car?.trim().isNotEmpty != true) {
      missing.add('транспорт');
    }
    if (!isCarrier && companyId?.trim().isNotEmpty != true) {
      missing.add('компания');
    }
    return missing;
  }
}
