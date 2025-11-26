class ImagePanicle {
  final String id;
  final String hillId;
  final String imagePath;
  final DateTime capturedAt;
  final bool isAnalyzed;
  final bool flag;
  final List<int>? qualityScore;

  const ImagePanicle({
    required this.id,
    required this.hillId,
    required this.imagePath,
    required this.capturedAt,
    required this.isAnalyzed,
    required this.flag,
    this.qualityScore,
  });

  factory ImagePanicle.fromMap(Map<String, dynamic> data) {
    List<int>? _parseQuality(dynamic value) {
      if (value == null) return null;
      if (value is List<int>) return value;
      if (value is String) return value.codeUnits;
      if (value is List<dynamic>) return value.cast<int>();
      return null;
    }

    DateTime _parseDate(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    }

    return ImagePanicle(
      id: data['id']?.toString() ?? '',
      hillId: data['hill_id']?.toString() ?? '',
      imagePath: data['image_path'] as String? ?? '',
      capturedAt: _parseDate(data['captured_at']),
      isAnalyzed: data['is_analyzed'] as bool? ?? false,
      flag: data['flag'] as bool? ?? false,
      qualityScore: _parseQuality(data['quality_score']),
    );
  }
}
