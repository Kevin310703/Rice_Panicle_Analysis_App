import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/notifications/models/notification.dart';

class NotificationUtils {
  static IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.project:
        return Icons.folder_open;
      case NotificationType.analysis:
        return Icons.analytics_outlined;
      case NotificationType.promo:
        return Icons.local_offer;
      case NotificationType.system:
      default:
        return Icons.notifications_active_outlined;
    }
  }

  static Color getIconBackgroundColor(
    BuildContext context,
    NotificationType type,
  ) {
    switch (type) {
      case NotificationType.project:
        return Theme.of(context).primaryColor.withOpacity(0.15);
      case NotificationType.analysis:
        return Colors.orange.withOpacity(0.15);
      case NotificationType.promo:
        return Colors.green.withOpacity(0.15);
      case NotificationType.system:
      default:
        return Colors.blueGrey.withOpacity(0.15);
    }
  }

  static Color getIconColor(BuildContext context, NotificationType type) {
    switch (type) {
      case NotificationType.project:
        return Theme.of(context).primaryColor;
      case NotificationType.analysis:
        return Colors.deepOrange;
      case NotificationType.promo:
        return Colors.green;
      case NotificationType.system:
      default:
        return Colors.blueGrey;
    }
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }
}
