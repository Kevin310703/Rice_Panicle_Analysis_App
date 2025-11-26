class AnalysisLog {
  final String id;
  final String projectId;
  final String analysisType;
  final String? filePath;
  final DateTime generatedAt;

  const AnalysisLog({
    required this.id,
    required this.projectId,
    required this.analysisType,
    required this.generatedAt,
    this.filePath,
  });

  factory AnalysisLog.fromMap(Map<String, dynamic> data) {
    DateTime _parse(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    }

    return AnalysisLog(
      id: data['id']?.toString() ?? '',
      projectId: data['project_id']?.toString() ?? '',
      analysisType: data['analysis_type'] as String? ?? 'unknown',
      filePath: data['file_path'] as String?,
      generatedAt: _parse(data['generated_at']),
    );
  }
}
