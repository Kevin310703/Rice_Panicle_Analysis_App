import 'package:cloud_firestore/cloud_firestore.dart';

class AnalysisResult {
  final String id;
  final String imageName;
  final double panicleLengthMm;
  final double? grainLengthMm;
  final double? grainWidthMm;
  final double? aspectRatio;
  final double pixelsPerMm;
  final int numDetections;

  // URL file xuất ra từ backend
  final String skeletonImageUrl;
  final String detectionOverlayUrl;

  // sample crops/processed để hiển thị
  final List<String> cropSampleUrls;
  final List<String> processedSampleUrls;

  final DateTime createdAt;

  const AnalysisResult({
    required this.id,
    required this.imageName,
    required this.panicleLengthMm,
    required this.pixelsPerMm,
    required this.numDetections,
    required this.skeletonImageUrl,
    required this.detectionOverlayUrl,
    this.grainLengthMm,
    this.grainWidthMm,
    this.aspectRatio,
    this.cropSampleUrls = const [],
    this.processedSampleUrls = const [],
    required this.createdAt,
  });

  factory AnalysisResult.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'] as Timestamp?;
    return AnalysisResult(
      id: doc.id,
      imageName: d['image_name'] ?? '',
      panicleLengthMm: (d['panicle_length_mm'] ?? 0).toDouble(),
      grainLengthMm: (d['grain_length_mm'] as num?)?.toDouble(),
      grainWidthMm: (d['grain_width_mm'] as num?)?.toDouble(),
      aspectRatio: (d['aspect_ratio'] as num?)?.toDouble(),
      pixelsPerMm: (d['pixels_per_mm'] ?? 0).toDouble(),
      numDetections: (d['num_detections'] ?? 0) as int,
      skeletonImageUrl: d['skeleton_image_url'] ?? '',
      detectionOverlayUrl: d['detection_overlay_url'] ?? '',
      cropSampleUrls: List<String>.from(d['crops_sample_urls'] ?? const []),
      processedSampleUrls: List<String>.from(d['processed_sample_urls'] ?? const []),
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreForCreate() {
    return {
      'image_name': imageName,
      'panicle_length_mm': panicleLengthMm,
      'grain_length_mm': grainLengthMm,
      'grain_width_mm': grainWidthMm,
      'aspect_ratio': aspectRatio,
      'pixels_per_mm': pixelsPerMm,
      'num_detections': numDetections,
      'skeleton_image_url': skeletonImageUrl,
      'detection_overlay_url': detectionOverlayUrl,
      'crops_sample_urls': cropSampleUrls,
      'processed_sample_urls': processedSampleUrls,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}