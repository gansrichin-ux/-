import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readWorkflowDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

class CargoApplicationModel {
  final String id;
  final String cargoId;
  final String cargoTitle;
  final String ownerId;
  final String applicantId;
  final String applicantName;
  final String applicantUsername;
  final String status;
  final String note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CargoApplicationModel({
    required this.id,
    required this.cargoId,
    required this.cargoTitle,
    required this.ownerId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantUsername,
    required this.status,
    required this.note,
    required this.createdAt,
    this.updatedAt,
  });

  factory CargoApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CargoApplicationModel(
      id: doc.id,
      cargoId: data['cargoId'] as String? ?? '',
      cargoTitle: data['cargoTitle'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      applicantId: data['applicantId'] as String? ?? '',
      applicantName: data['applicantName'] as String? ?? '',
      applicantUsername: data['applicantUsername'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      note: data['note'] as String? ?? '',
      createdAt: _readWorkflowDate(data['createdAt']),
      updatedAt: data['updatedAt'] == null
          ? null
          : _readWorkflowDate(data['updatedAt']),
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
}

class SiteNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const SiteNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.relatedId,
    this.isRead = false,
  });

  factory SiteNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SiteNotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'system',
      relatedId: data['relatedId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _readWorkflowDate(data['createdAt']),
    );
  }
}

class ActivityLogModel {
  final String id;
  final String title;
  final String body;
  final String actorId;
  final String actorName;
  final String? cargoId;
  final String type;
  final DateTime createdAt;

  const ActivityLogModel({
    required this.id,
    required this.title,
    required this.body,
    required this.actorId,
    required this.actorName,
    required this.type,
    required this.createdAt,
    this.cargoId,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityLogModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      cargoId: data['cargoId'] as String?,
      type: data['type'] as String? ?? 'system',
      createdAt: _readWorkflowDate(data['createdAt']),
    );
  }
}

class UserReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String targetId;
  final String targetName;
  final String reason;
  final String status;
  final DateTime createdAt;

  const UserReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetId,
    required this.targetName,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory UserReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserReportModel(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      targetName: data['targetName'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      createdAt: _readWorkflowDate(data['createdAt']),
    );
  }
}
