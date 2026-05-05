import 'package:cloud_firestore/cloud_firestore.dart';

class CargoModel {
  final String id;
  final String title;
  final String from;
  final String to;
  final String status;
  final String? driverId;
  final String? driverName;
  final String? ownerId;
  final List<String> photos;
  final DateTime? createdAt;
  final String? description;
  final double? weightKg;
  final double? volumeM3;
  final String? bodyType;
  final DateTime? loadingDate;
  final String? loadingType;
  final String? paymentType;
  final double? lengthM;
  final double? heightM;
  final double? widthM;
  final double? distanceKm;
  final double? price;

  const CargoModel({
    required this.id,
    required this.title,
    required this.from,
    required this.to,
    required this.status,
    this.driverId,
    this.driverName,
    this.ownerId,
    this.photos = const [],
    this.createdAt,
    this.description,
    this.weightKg,
    this.volumeM3,
    this.bodyType,
    this.loadingDate,
    this.loadingType,
    this.paymentType,
    this.lengthM,
    this.heightM,
    this.widthM,
    this.distanceKm,
    this.price,
  })  : assert(id.length > 0, 'Cargo id must not be empty'),
        assert(title.length > 0, 'Cargo title must not be empty'),
        assert(from.length > 0, 'Cargo origin must not be empty'),
        assert(to.length > 0, 'Cargo destination must not be empty'),
        assert(status.length > 0, 'Cargo status must not be empty'),
        assert(
          weightKg == null || weightKg > 0,
          'Cargo weight must be positive',
        );

  factory CargoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CargoModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      from: data['from'] as String? ?? '',
      to: data['to'] as String? ?? '',
      status: data['status'] as String? ?? 'Новый',
      driverId: data['driverId'] as String?,
      driverName: data['driverName'] as String?,
      ownerId: data['ownerId'] as String?,
      photos: List<String>.from(data['photos'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      description: data['description'] as String?,
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      volumeM3: (data['volumeM3'] as num?)?.toDouble(),
      bodyType: data['bodyType'] as String?,
      loadingDate: (data['loadingDate'] as Timestamp?)?.toDate(),
      loadingType: data['loadingType'] as String?,
      paymentType: data['paymentType'] as String?,
      lengthM: (data['lengthM'] as num?)?.toDouble(),
      heightM: (data['heightM'] as num?)?.toDouble(),
      widthM: (data['widthM'] as num?)?.toDouble(),
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      price: (data['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'from': from,
      'to': to,
      'status': status,
      if (driverId != null) 'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (ownerId != null) 'ownerId': ownerId,
      'photos': photos,
      'createdAt': FieldValue.serverTimestamp(),
      if (description != null) 'description': description,
      if (weightKg != null) 'weightKg': weightKg,
      if (volumeM3 != null) 'volumeM3': volumeM3,
      if (bodyType != null) 'bodyType': bodyType,
      if (loadingDate != null) 'loadingDate': Timestamp.fromDate(loadingDate!),
      if (loadingType != null) 'loadingType': loadingType,
      if (paymentType != null) 'paymentType': paymentType,
      if (lengthM != null) 'lengthM': lengthM,
      if (heightM != null) 'heightM': heightM,
      if (widthM != null) 'widthM': widthM,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (price != null) 'price': price,
    };
  }

  CargoModel copyWith({
    String? title,
    String? from,
    String? to,
    String? status,
    String? driverId,
    String? driverName,
    String? ownerId,
    List<String>? photos,
    String? description,
    double? weightKg,
    double? volumeM3,
    String? bodyType,
    DateTime? loadingDate,
    String? loadingType,
    String? paymentType,
    double? lengthM,
    double? heightM,
    double? widthM,
    double? distanceKm,
    double? price,
  }) {
    return CargoModel(
      id: id,
      title: title ?? this.title,
      from: from ?? this.from,
      to: to ?? this.to,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      ownerId: ownerId ?? this.ownerId,
      photos: photos ?? this.photos,
      createdAt: createdAt,
      description: description ?? this.description,
      weightKg: weightKg ?? this.weightKg,
      volumeM3: volumeM3 ?? this.volumeM3,
      bodyType: bodyType ?? this.bodyType,
      loadingDate: loadingDate ?? this.loadingDate,
      loadingType: loadingType ?? this.loadingType,
      paymentType: paymentType ?? this.paymentType,
      lengthM: lengthM ?? this.lengthM,
      heightM: heightM ?? this.heightM,
      widthM: widthM ?? this.widthM,
      distanceKm: distanceKm ?? this.distanceKm,
      price: price ?? this.price,
    );
  }

  factory CargoModel.fromMap(Map<String, dynamic> map) {
    return CargoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      from: map['from'] as String,
      to: map['to'] as String,
      status: map['status'] as String,
      driverId: map['driverId'] as String?,
      driverName: map['driverName'] as String?,
      ownerId: map['ownerId'] as String?,
      photos: List<String>.from(map['photos'] as List? ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      description: map['description'] as String?,
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      volumeM3: (map['volumeM3'] as num?)?.toDouble(),
      bodyType: map['bodyType'] as String?,
      loadingDate: map['loadingDate'] != null
          ? DateTime.parse(map['loadingDate'] as String)
          : null,
      loadingType: map['loadingType'] as String?,
      paymentType: map['paymentType'] as String?,
      lengthM: (map['lengthM'] as num?)?.toDouble(),
      heightM: (map['heightM'] as num?)?.toDouble(),
      widthM: (map['widthM'] as num?)?.toDouble(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      price: (map['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'from': from,
      'to': to,
      'status': status,
      if (driverId != null) 'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (ownerId != null) 'ownerId': ownerId,
      'photos': photos,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (description != null) 'description': description,
      if (weightKg != null) 'weightKg': weightKg,
      if (volumeM3 != null) 'volumeM3': volumeM3,
      if (bodyType != null) 'bodyType': bodyType,
      if (loadingDate != null) 'loadingDate': loadingDate!.toIso8601String(),
      if (loadingType != null) 'loadingType': loadingType,
      if (paymentType != null) 'paymentType': paymentType,
      if (lengthM != null) 'lengthM': lengthM,
      if (heightM != null) 'heightM': heightM,
      if (widthM != null) 'widthM': widthM,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (price != null) 'price': price,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CargoModel &&
        other.id == id &&
        other.title == title &&
        other.from == from &&
        other.to == to &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        from.hashCode ^
        to.hashCode ^
        status.hashCode;
  }

  @override
  String toString() {
    return 'CargoModel(id: $id, title: $title, from: $from, to: $to, status: $status)';
  }
}
