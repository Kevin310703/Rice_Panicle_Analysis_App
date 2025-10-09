import 'package:rice_panicle_analysis_app/features/notifications/models/notification_type.dart';

class NotificationRepository {
  List<NotificationItem> getNotifications() {
    return [
      NotificationItem(
        title: 'New Project Assigned',
        message: 'You have been assigned a new project: Rice Yield Analysis.',
        time: '2 hours ago',
        type: NotificationType.project,
        isRead: true,
      ),
      NotificationItem(
        title: 'Special Promotion',
        message: 'Get 20% off on premium features. Limited time offer!',
        time: '1 day ago',
        type: NotificationType.promo,
        isRead: true,
      ),
      NotificationItem(
        title: 'Project Deadline Reminder',
        message: 'Reminder: The deadline for the Rice Yield Analysis project is tomorrow.',
        time: '3 days ago',
        type: NotificationType.project,
        isRead: false,
      ),
      NotificationItem(
        title: 'New Feature Released',
        message: 'Check out the new image enhancement feature in the app!',
        time: '5 days ago',
        type: NotificationType.promo,
        isRead: false,
      ),
    ];
  }
}