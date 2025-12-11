enum NotificationType { project, analysis, promo, system }

NotificationType notificationTypeFromString(String value) {
  return NotificationType.values.firstWhere(
    (element) => element.name == value,
    orElse: () => NotificationType.system,
  );
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> data) {
    return NotificationItem(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: notificationTypeFromString(data['type']?.toString() ?? ''),
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: data['isRead'] == true,
    );
  }
}
