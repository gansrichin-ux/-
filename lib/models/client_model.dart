import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? company;
  final String? notes;
  final String? ownerId;
  final DateTime createdAt;
  final DateTime? lastContactDate;
  final int totalOrders;
  final double totalRevenue;
  final bool isActive;

  const ClientModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.company,
    this.notes,
    this.ownerId,
    required this.createdAt,
    this.lastContactDate,
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
    this.isActive = true,
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      address: data['address'] as String?,
      company: data['company'] as String?,
      notes: data['notes'] as String?,
      ownerId: data['ownerId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastContactDate: (data['lastContactDate'] as Timestamp?)?.toDate(),
      totalOrders: data['totalOrders'] as int? ?? 0,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'company': company,
      'notes': notes,
      if (ownerId != null) 'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
      if (lastContactDate != null)
        'lastContactDate': Timestamp.fromDate(lastContactDate!),
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'company': company,
      'notes': notes,
      if (ownerId != null) 'ownerId': ownerId,
      if (lastContactDate != null)
        'lastContactDate': Timestamp.fromDate(lastContactDate!),
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'isActive': isActive,
    };
  }

  ClientModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? company,
    String? notes,
    String? ownerId,
    DateTime? createdAt,
    DateTime? lastContactDate,
    int? totalOrders,
    double? totalRevenue,
    bool? isActive,
  }) {
    return ClientModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      company: company ?? this.company,
      notes: notes ?? this.notes,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      isActive: isActive ?? this.isActive,
    );
  }

  String get displayName => name.isNotEmpty ? name : 'Без имени';

  String get contactInfo {
    final parts = <String>[];
    if (phone != null && phone!.isNotEmpty) parts.add(phone!);
    if (email != null && email!.isNotEmpty) parts.add(email!);
    return parts.join(' • ');
  }

  String get fullInfo {
    final parts = <String>[name];
    if (company != null && company!.isNotEmpty) parts.add(company!);
    if (phone != null && phone!.isNotEmpty) parts.add(phone!);
    if (email != null && email!.isNotEmpty) parts.add(email!);
    if (address != null && address!.isNotEmpty) parts.add(address!);
    return parts.join('\n');
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      company: map['company'] as String?,
      notes: map['notes'] as String?,
      ownerId: map['ownerId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      lastContactDate: map['lastContactDate'] != null
          ? DateTime.parse(map['lastContactDate'] as String)
          : null,
      totalOrders: map['totalOrders'] as int? ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'company': company,
      'notes': notes,
      if (ownerId != null) 'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      if (lastContactDate != null)
        'lastContactDate': lastContactDate!.toIso8601String(),
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'isActive': isActive,
    };
  }
}
