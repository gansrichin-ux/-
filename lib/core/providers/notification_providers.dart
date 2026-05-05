import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../../models/notification_model.dart';
import 'auth_providers.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Provider for all notifications
final allNotificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) return [];

  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.getUserNotifications(user.uid);
});

/// Provider for unread notifications count
final unreadCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) return 0;

  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.getUnreadCount(user.uid);
});

/// Provider for notifications by type
final notificationsByTypeProvider =
    FutureProvider.family<List<NotificationModel>, NotificationType>(
        (ref, type) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) return [];

  final allNotifications = await ref.watch(allNotificationsProvider.future);
  return allNotifications
      .where((notification) => notification.type == type)
      .toList();
});

/// Provider for unread notifications
final unreadNotificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) return [];

  final allNotifications = await ref.watch(allNotificationsProvider.future);
  return allNotifications
      .where((notification) => !notification.isRead)
      .toList();
});

/// Provider for recent notifications (last 24 hours)
final recentNotificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) return [];

  final allNotifications = await ref.watch(allNotificationsProvider.future);
  final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));

  return allNotifications
      .where(
          (notification) => notification.createdAt.isAfter(twentyFourHoursAgo))
      .toList();
});

/// Provider for notification statistics
final notificationStatsProvider = Provider<Map<String, int>>((ref) {
  final allNotificationsAsync = ref.watch(allNotificationsProvider);

  return allNotificationsAsync.when(
    data: (notifications) {
      final stats = <String, int>{};

      // Count by type
      for (final type in NotificationType.values) {
        stats[type.name] = notifications.where((n) => n.type == type).length;
      }

      // Count by read status
      stats['total'] = notifications.length;
      stats['unread'] = notifications.where((n) => !n.isRead).length;
      stats['read'] = notifications.where((n) => n.isRead).length;

      return stats;
    },
    loading: () => {},
    error: (error, stackTrace) => {},
  );
});

/// Provider for notifications grouped by date
final notificationsByDateProvider =
    FutureProvider<Map<String, List<NotificationModel>>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) return {};

  final allNotifications = await ref.watch(allNotificationsProvider.future);
  final groupedNotifications = <String, List<NotificationModel>>{};

  for (final notification in allNotifications) {
    final dateKey = _formatDate(notification.createdAt);

    if (!groupedNotifications.containsKey(dateKey)) {
      groupedNotifications[dateKey] = [];
    }

    groupedNotifications[dateKey]!.add(notification);
  }

  return groupedNotifications;
});

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final notificationDate = DateTime(date.year, date.month, date.day);

  if (notificationDate == today) {
    return 'Today';
  } else if (notificationDate == yesterday) {
    return 'Yesterday';
  } else if (notificationDate
      .isAfter(today.subtract(const Duration(days: 7)))) {
    return 'This Week';
  } else if (notificationDate
      .isAfter(today.subtract(const Duration(days: 30)))) {
    return 'This Month';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Actions for notifications
class NotificationActions {
  final Ref ref;

  NotificationActions(this.ref);

  Future<void> markAsRead(String notificationId) async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;

    if (user == null) return;

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.markAsRead(user.uid, notificationId);

    // Invalidate relevant providers
    ref.invalidate(allNotificationsProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> markAllAsRead() async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;

    if (user == null) return;

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.markAllAsRead(user.uid);

    // Invalidate relevant providers
    ref.invalidate(allNotificationsProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> deleteNotification(String notificationId) async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;

    if (user == null) return;

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.deleteNotification(user.uid, notificationId);

    // Invalidate relevant providers
    ref.invalidate(allNotificationsProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> clearAllNotifications() async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;

    if (user == null) return;

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.clearAllNotifications(user.uid);

    // Invalidate relevant providers
    ref.invalidate(allNotificationsProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;

    if (user == null) return;

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.createNotification(
      userId: user.uid,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      data: data,
    );

    // Invalidate relevant providers
    ref.invalidate(allNotificationsProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(unreadNotificationsProvider);
  }
}

/// Provider for notification actions
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});
