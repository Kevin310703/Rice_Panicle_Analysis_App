import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rice_panicle_analysis_app/features/notifications/models/notification.dart';

class NotificationSupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _table = 'notification';

  static Future<List<NotificationItem>> fetchNotifications({
    required String userId,
    bool unreadOnly = false,
  }) async {
    var query = _client
        .from(_table)
        .select()
        .eq('userId', userId);

    if (unreadOnly) {
      query = query.eq('isRead', false);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map(NotificationItem.fromMap).toList();
  }

  static Future<void> markAllAsRead(String userId) async {
    await _client
        .from(_table)
        .update({'isRead': true})
        .eq('userId', userId)
        .eq('isRead', false);
  }

  static Future<void> markAsRead(String notificationId) async {
    await _client
        .from(_table)
        .update({'isRead': true})
        .eq('id', notificationId);
  }

  static Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
  }) async {
    await _client.from(_table).insert({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
    });
  }
}
