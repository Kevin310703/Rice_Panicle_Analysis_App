class AnalysisResult {
  final String id;
  final String imageId;
  final int grains;
  final int primaryBranch;
  final int totalSpikelets;
  final double filledRatio;
  final double confidence;
  final String modelVersion;
  final DateTime processedAt;
  final String? boundingImageUrl;
  final String? localBoundingImagePath;
  final bool isSynced;
  final double? processingTimeMs;

  const AnalysisResult({
    required this.id,
    required this.imageId,
    required this.grains,
    required this.primaryBranch,
    required this.totalSpikelets,
    required this.filledRatio,
    required this.confidence,
    required this.modelVersion,
    required this.processedAt,
    this.boundingImageUrl,
    this.localBoundingImagePath,
    this.isSynced = true,
    this.processingTimeMs,
  });

  factory AnalysisResult.fromMap(Map<String, dynamic> data) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    }

    final rawProcessing = data['processing_time_ms'];
    return AnalysisResult(
      id: data['id']?.toString() ?? '',
      imageId: data['image_id']?.toString() ?? '',
      grains: data['grains'] as int? ?? 0,
      primaryBranch: data['primary_branch'] as int? ?? 0,
      totalSpikelets: data['total_spikelets'] as int? ?? 0,
      filledRatio: toDouble(data['filled_ratio']),
      confidence: toDouble(data['confidence']),
      modelVersion: data['model_version'] as String? ?? 'unknown',
      processedAt: parseDate(data['processed_at']),
      boundingImageUrl: data['bounding_image_url'] as String? ??
          data['bounding_image_path'] as String?,
      localBoundingImagePath: data['local_bounding_image_path'] as String?,
      isSynced: data['is_synced'] as bool? ?? true,
      processingTimeMs: rawProcessing == null ? null : toDouble(rawProcessing),
    );
  }

  factory AnalysisResult.fromLocalMap(Map<String, dynamic> data) {
    return AnalysisResult.fromMap(data);
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'image_id': imageId,
      'grains': grains,
      'primary_branch': primaryBranch,
      'total_spikelets': totalSpikelets,
      'filled_ratio': filledRatio,
      'confidence': confidence,
      'model_version': modelVersion,
      'processed_at': processedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalMap({
    required String projectId,
    required String hillId,
  }) {
    return {
      'id': id,
      'project_id': projectId,
      'hill_id': hillId,
      'image_id': imageId,
      'grains': grains,
      'primary_branch': primaryBranch,
      'total_spikelets': totalSpikelets,
      'filled_ratio': filledRatio,
      'confidence': confidence,
      'model_version': modelVersion,
      'processed_at': processedAt.toIso8601String(),
      'bounding_image_url': boundingImageUrl,
      'local_bounding_image_path': localBoundingImagePath,
      'is_synced': isSynced,
      'processing_time_ms': processingTimeMs,
    };
  }

  AnalysisResult copyWith({
    String? id,
    String? imageId,
    int? grains,
    int? primaryBranch,
    int? totalSpikelets,
    double? filledRatio,
    double? confidence,
    String? modelVersion,
    DateTime? processedAt,
    String? boundingImageUrl,
    String? localBoundingImagePath,
    bool? isSynced,
    double? processingTimeMs,
  }) {
    return AnalysisResult(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      grains: grains ?? this.grains,
      primaryBranch: primaryBranch ?? this.primaryBranch,
      totalSpikelets: totalSpikelets ?? this.totalSpikelets,
      filledRatio: filledRatio ?? this.filledRatio,
      confidence: confidence ?? this.confidence,
      modelVersion: modelVersion ?? this.modelVersion,
      processedAt: processedAt ?? this.processedAt,
      boundingImageUrl: boundingImageUrl ?? this.boundingImageUrl,
      localBoundingImagePath:
          localBoundingImagePath ?? this.localBoundingImagePath,
      isSynced: isSynced ?? this.isSynced,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
    );
  }
}
