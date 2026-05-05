import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _notificationsEnabledKey = 'notifications_enabled';

  Future<void> saveToken(String uid) async {
    // Fully async - don't block main thread
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool(_notificationsEnabledKey) ?? true;
      if (!notificationsEnabled) {
        await clearToken(uid);
        return;
      }

      // Get token without requesting permissions (if already have)
      final token = await _messaging.getToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      if (token != null) {
        // Update token in background without waiting
        _firestore
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token})
            .timeout(const Duration(seconds: 3))
            .catchError((e) => debugPrint('FCM token update failed: $e'));
      }
    } catch (e) {
      debugPrint('NotificationService Error: $e');
    }
  }

  Future<void> clearToken(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()})
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('FCM token clear failed: $e');
    }
  }

  /// Create a new notification
  Future<String> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        relatedId: relatedId,
        data: data,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      debugPrint('Notification created: ${notification.id}');
      return notification.id;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  /// Get all notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': DateTime.now().toIso8601String()});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadNotifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    try {
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  /// Create system notification
  Future<String> createSystemNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.system,
      data: data,
    );
  }

  /// Create cargo notification
  Future<String> createCargoNotification({
    required String userId,
    required String title,
    required String body,
    required String cargoId,
    Map<String, dynamic>? data,
  }) async {
    return await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.cargo,
      relatedId: cargoId,
      data: data,
    );
  }

  /// Create client notification
  Future<String> createClientNotification({
    required String userId,
    required String title,
    required String body,
    required String clientId,
    Map<String, dynamic>? data,
  }) async {
    return await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.client,
      relatedId: clientId,
      data: data,
    );
  }

  /// Create driver notification
  Future<String> createDriverNotification({
    required String userId,
    required String title,
    required String body,
    required String driverId,
    Map<String, dynamic>? data,
  }) async {
    return await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.driver,
      relatedId: driverId,
      data: data,
    );
  }

  /// Create delivery notification
  Future<String> createDeliveryNotification({
    required String userId,
    required String title,
    required String body,
    required String deliveryId,
    Map<String, dynamic>? data,
  }) async {
    return await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.delivery,
      relatedId: deliveryId,
      data: data,
    );
  }

  /// Create alert notification
  Future<String> createAlertNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.alert,
      data: data,
    );
  }
}
