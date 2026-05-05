import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

const String tenderStatusActive = 'active';
const String tenderStatusClosed = 'closed';
const String tenderStatusAwarded = 'awarded';

const String bidStatusPending = 'pending';
const String bidStatusAccepted = 'accepted';
const String bidStatusRejected = 'rejected';

class TenderModel {
  final String id;
  final String title;
  final String description;
  final String from;
  final String to;
  final double? weightKg;
  final double? volumeM3;
  final double startingPrice;
  final String currency;
  final String ownerId;
  final String ownerName;
  final DateTime deadlineAt;
  final String status;
  final String? winnerId;
  final String? winnerName;
  final double? winnerPrice;
  final DateTime createdAt;
  final int bidCount;

  const TenderModel({
    required this.id,
    required this.title,
    required this.description,
    required this.from,
    required this.to,
    required this.startingPrice,
    required this.currency,
    required this.ownerId,
    required this.ownerName,
    required this.deadlineAt,
    required this.createdAt,
    this.weightKg,
    this.volumeM3,
    this.status = tenderStatusActive,
    this.winnerId,
    this.winnerName,
    this.winnerPrice,
    this.bidCount = 0,
  });

  bool get isActive => status == tenderStatusActive;
  bool get isClosed => status == tenderStatusClosed;
  bool get isAwarded => status == tenderStatusAwarded;
  bool get isExpired => deadlineAt.isBefore(DateTime.now()) && isActive;

  factory TenderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TenderModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      from: data['from'] as String? ?? '',
      to: data['to'] as String? ?? '',
      startingPrice: (data['startingPrice'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? '₸',
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      deadlineAt: _readDate(data['deadlineAt']),
      createdAt: _readDate(data['createdAt']),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      volumeM3: (data['volumeM3'] as num?)?.toDouble(),
      status: data['status'] as String? ?? tenderStatusActive,
      winnerId: data['winnerId'] as String?,
      winnerName: data['winnerName'] as String?,
      winnerPrice: (data['winnerPrice'] as num?)?.toDouble(),
      bidCount: (data['bidCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'from': from,
        'to': to,
        'startingPrice': startingPrice,
        'currency': currency,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'deadlineAt': Timestamp.fromDate(deadlineAt),
        'createdAt': FieldValue.serverTimestamp(),
        if (weightKg != null) 'weightKg': weightKg,
        if (volumeM3 != null) 'volumeM3': volumeM3,
        'status': status,
        'bidCount': bidCount,
      };
}

class TenderBidModel {
  final String id;
  final String tenderId;
  final String bidderId;
  final String bidderName;
  final String bidderUsername;
  final double price;
  final String note;
  final DateTime createdAt;
  final String status;

  const TenderBidModel({
    required this.id,
    required this.tenderId,
    required this.bidderId,
    required this.bidderName,
    required this.bidderUsername,
    required this.price,
    required this.note,
    required this.createdAt,
    this.status = bidStatusPending,
  });

  bool get isPending => status == bidStatusPending;
  bool get isAccepted => status == bidStatusAccepted;
  bool get isRejected => status == bidStatusRejected;

  factory TenderBidModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TenderBidModel(
      id: doc.id,
      tenderId: data['tenderId'] as String? ?? '',
      bidderId: data['bidderId'] as String? ?? '',
      bidderName: data['bidderName'] as String? ?? '',
      bidderUsername: data['bidderUsername'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      note: data['note'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      status: data['status'] as String? ?? bidStatusPending,
    );
  }

  Map<String, dynamic> toMap() => {
        'tenderId': tenderId,
        'bidderId': bidderId,
        'bidderName': bidderName,
        'bidderUsername': bidderUsername,
        'price': price,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
      };
}
