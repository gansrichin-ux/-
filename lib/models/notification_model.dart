import 'package:flutter/material.dart';

enum NotificationType {
  system,
  cargo,
  client,
  driver,
  delivery,
  payment,
  alert,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;
  final String? relatedId;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.readAt,
    this.isRead = false,
    this.relatedId,
    this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt'] as String) : null,
      isRead: map['isRead'] as bool? ?? false,
      relatedId: map['relatedId'] as String?,
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isRead': isRead,
      'relatedId': relatedId,
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    DateTime? readAt,
    bool? isRead,
    String? relatedId,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
    );
  }

  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return createdAt.toString().substring(0, 10);
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.system:
        return const Color(0xFF6366F1);
      case NotificationType.cargo:
        return const Color(0xFF3B82F6);
      case NotificationType.client:
        return const Color(0xFF22C55E);
      case NotificationType.driver:
        return const Color(0xFFF59E0B);
      case NotificationType.delivery:
        return const Color(0xFF10B981);
      case NotificationType.payment:
        return const Color(0xFF8B5CF6);
      case NotificationType.alert:
        return const Color(0xFFEF4444);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.cargo:
        return Icons.local_shipping;
      case NotificationType.client:
        return Icons.person;
      case NotificationType.driver:
        return Icons.drive_eta;
      case NotificationType.delivery:
        return Icons.check_circle;
      case NotificationType.payment:
        return Icons.attach_money;
      case NotificationType.alert:
        return Icons.warning;
    }
  }
}
