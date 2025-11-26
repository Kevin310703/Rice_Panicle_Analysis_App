class Hill {
  final String id;
  final String projectId;
  final String hillLabel;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool flag;

  const Hill({
    required this.id,
    required this.projectId,
    required this.hillLabel,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.flag = false,
  });

  factory Hill.fromMap(Map<String, dynamic> data) {
    DateTime _parse(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    }

    return Hill(
      id: data['id']?.toString() ?? '',
      projectId: data['project_id']?.toString() ?? '',
      hillLabel: data['hill_label'] as String? ?? 'Unknown hill',
      notes: data['notes'] as String?,
      createdAt: _parse(data['created_at']),
      updatedAt: data['updated_at'] != null ? _parse(data['updated_at']) : null,
      flag: data['flag'] as bool? ?? false,
    );
  }
}
