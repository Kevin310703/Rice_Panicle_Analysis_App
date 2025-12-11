import 'package:rice_panicle_analysis_app/features/notifications/models/notification.dart';
import 'package:rice_panicle_analysis_app/services/notification_supabase_service.dart';

class NotificationRepository {
  Future<List<NotificationItem>> fetchNotifications({
    required String userId,
  }) {
    return NotificationSupabaseService.fetchNotifications(userId: userId);
  }

  Future<void> markAllAsRead(String userId) {
    return NotificationSupabaseService.markAllAsRead(userId);
  }

  Future<void> pushNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
  }) {
    return NotificationSupabaseService.createNotification(
      userId: userId,
      type: type,
      title: title,
      message: message,
    );
  }
}
