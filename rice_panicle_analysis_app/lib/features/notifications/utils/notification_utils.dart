import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/notifications/models/notification_type.dart';

class NotificationUtils {
  static IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.project:
        return Icons.work_outline;
      case NotificationType.promo:
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  static Color getIconBackgroundColor(BuildContext context, NotificationType type) {
    switch (type) {
      case NotificationType.project:
        return Theme.of(context).primaryColor.withOpacity(0.1);
      case NotificationType.promo:
        return Colors.green[100]!;
      default:
        return Colors.grey;
    }
  }

  static Color getIconColor(BuildContext context, NotificationType type) {
    switch (type) {
      case NotificationType.project:
        return Theme.of(context).primaryColor;
      case NotificationType.promo:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}