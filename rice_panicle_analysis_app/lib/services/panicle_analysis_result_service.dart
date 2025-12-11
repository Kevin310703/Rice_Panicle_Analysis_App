import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/image_panicle.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/notifications/models/notification.dart';
import 'package:rice_panicle_analysis_app/services/local_analysis_result_storage_service.dart';
import 'package:rice_panicle_analysis_app/services/notification_supabase_service.dart';
import 'package:rice_panicle_analysis_app/services/panicle_ai_service.dart';
import 'package:rice_panicle_analysis_app/services/project_supabase_service.dart';
import 'package:rice_panicle_analysis_app/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PanicleAnalysisResultService {
  PanicleAnalysisResultService._();

  static final PanicleAnalysisResultService instance =
      PanicleAnalysisResultService._();
  static const bool _remoteSyncEnabled = false;

  final PanicleAiService _aiService = PanicleAiService.instance;
  final LocalAnalysisResultStorageService _localStorage =
      LocalAnalysisResultStorageService.instance;

  Future<AnalysisResult> persistResult({
    required Project project,
    required ImagePanicle panicle,
    required PanicleInferenceResult inference,
  }) async {
    final metrics = _Metrics.fromInference(inference);
    final timestamp = DateTime.now();
    final imageBytes = await _aiService.loadImageBytes(panicle.imagePath);
    final overlayBytes = await _renderBoundingImage(imageBytes, inference);

    var result = AnalysisResult(
      id: 'local_${panicle.id}_${timestamp.microsecondsSinceEpoch}',
      imageId: panicle.id,
      grains: metrics.grain,
      primaryBranch: metrics.primaryBranch,
      totalSpikelets: metrics.total,
      filledRatio: metrics.ratio,
      confidence: metrics.averageConfidence,
      modelVersion: 'tflite-local',
      processedAt: timestamp,
      isSynced: false,
      processingTimeMs: inference.processingTimeMs,
    );

    final localPath = await _localStorage.saveBoundingImage(
      projectId: project.id,
      imageId: panicle.id,
      bytes: overlayBytes,
    );
    result = result.copyWith(localBoundingImagePath: localPath);

    await _localStorage.saveResult(
      projectId: project.id,
      hillId: panicle.hillId,
      result: result,
    );
    _logResult(result);

    if (_remoteSyncEnabled) {
      unawaited(
        _syncToSupabase(
          project: project,
          panicle: panicle,
          result: result,
          overlayBytes: overlayBytes,
        ),
      );
    } else {
      debugPrint('Remote sync disabled: results stored locally only.');
    }

    _notifyAnalysisCompleted(project);
    return result;
  }

  Future<void> deleteProject(String projectId) async {
    await _localStorage.deleteProject(projectId);
  }

  Future<void> deleteResultsForImage({
    required String projectId,
    required String imageId,
  }) async {
    await _localStorage.deleteResultsForImage(
      projectId: projectId,
      imageId: imageId,
    );
  }

  Future<List<AnalysisResult>> getLocalResults(String projectId) {
    return _localStorage.getResultsForProject(projectId);
  }

  Future<void> _syncToSupabase({
    required Project project,
    required ImagePanicle panicle,
    required AnalysisResult result,
    required Uint8List overlayBytes,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      debugPrint('Skip sync: no Supabase session.');
      return;
    }
    if (!await _hasNetworkConnectivity()) {
      debugPrint('Skip sync: offline mode.');
      return;
    }

    try {
      final remoteUrl =
          await ProjectSupabaseService.uploadAnalysisBoundingImage(
            projectId: project.id,
            imageId: panicle.id,
            bytes: overlayBytes,
          );

      final inserted = await ProjectSupabaseService.insertAnalysisResult(
        imageId: panicle.id,
        grains: result.grains,
        primaryBranch: result.primaryBranch,
        totalSpikelets: result.totalSpikelets,
        filledRatio: result.filledRatio,
        confidence: result.confidence,
        modelVersion: result.modelVersion,
        processedAt: result.processedAt,
      );

      if (remoteUrl != null) {
        await ProjectSupabaseService.createAnalysisLog(
          projectId: project.id,
          analysisType: 'bbox_image:${panicle.id}',
          filePath: remoteUrl,
        );
      }

      if (inserted != null) {
        final synced = inserted.copyWith(
          boundingImageUrl: remoteUrl ?? inserted.boundingImageUrl,
          localBoundingImagePath: result.localBoundingImagePath,
          isSynced: true,
        );
        await _localStorage.replaceResult(
          projectId: project.id,
          hillId: panicle.hillId,
          result: synced,
        );
      }
    } catch (err, stack) {
      debugPrint('Failed to sync analysis result: $err\n$stack');
    }
  }

  Future<bool> _hasNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('supabase.co').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _notifyAnalysisCompleted(Project project) {
    final userId = SupabaseAuthService.currentUser?.id;
    if (userId == null) return;
    unawaited(
      NotificationSupabaseService.createNotification(
        userId: userId,
        type: NotificationType.analysis,
        title: 'Analysis finished',
        message: 'AI finished processing images for ${project.projectName}.',
      ),
    );
  }

  Future<Uint8List> _renderBoundingImage(
    Uint8List bytes,
    PanicleInferenceResult inference,
  ) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Không thể render ảnh kết quả phân tích.');
    }

    final canvas = img.copyResize(
      decoded,
      width: decoded.width,
      height: decoded.height,
    );

    final detections = inference.detections;
    final inferenceWidth =
        inference.originalSize.width <= 0 ? decoded.width.toDouble() : inference.originalSize.width;
    final inferenceHeight =
        inference.originalSize.height <= 0 ? decoded.height.toDouble() : inference.originalSize.height;
    final scaleX = inferenceWidth == 0 ? 1.0 : decoded.width / inferenceWidth;
    final scaleY = inferenceHeight == 0 ? 1.0 : decoded.height / inferenceHeight;
    final palette = _labelPalette(detections);
    for (final detection in detections) {
      final rect = detection.boundingBox;
      final adjustedLeft = (rect.left * scaleX).clamp(0, decoded.width - 1);
      final adjustedTop = (rect.top * scaleY).clamp(0, decoded.height - 1);
      final adjustedRight = (rect.right * scaleX).clamp(0, decoded.width - 1);
      final adjustedBottom = (rect.bottom * scaleY).clamp(0, decoded.height - 1);
      final color = palette[detection.label] ?? img.ColorRgb8(76, 175, 80);
      img.drawRect(
        canvas,
        x1: adjustedLeft.round(),
        y1: adjustedTop.round(),
        x2: adjustedRight.round(),
        y2: adjustedBottom.round(),
        color: color,
        thickness: max(2, (canvas.width * 0.002).round()),
      );
      final labelText = detection.label;
      final textX = adjustedLeft.round().clamp(0, canvas.width - 1);
      final textY = max(0, adjustedTop.round() - 40);
      img.drawString(
        canvas,
        labelText,
        font: img.arial48,
        x: textX,
        y: textY,
        color: color,
      );
    }

    return Uint8List.fromList(img.encodePng(canvas));
  }

Map<String, img.Color> _labelPalette(List<PanicleDetection> detections) {
  final colors = <String, img.Color>{};
  final defaultColors = <String, img.Color>{
    'Grain': img.ColorRgb8(76, 175, 80),
    'Primary branch': img.ColorRgb8(255, 193, 7),
  };

  for (final detection in detections) {
    colors.putIfAbsent(detection.label, () {
      final preset = defaultColors[detection.label];
      if (preset != null) return preset;
        // Tạo seed cố định dựa trên label → màu luôn giống nhau cho cùng label
        final seed = detection.label.hashCode;

        final random = Random(seed);
        final r = random.nextInt(256);
        final g = random.nextInt(256);
        final b = random.nextInt(256);

        // Tránh màu quá tối hoặc quá sáng
        final brightness = (r * 0.299 + g * 0.587 + b * 0.114);
        if (brightness < 60 || brightness > 200) {
          // Nếu quá tối/sáng thì dùng màu mặc định đẹp
          return img.ColorRgb8(255, 193, 7); // vàng amber đẹp
        }

        return img.ColorRgb8(r, g, b);
      });
    }

    // Màu mặc định nếu không có detection nào
    colors.putIfAbsent('default', () => img.ColorRgb8(76, 175, 80));

    return colors;
  }
}

class _Metrics {
  final int grain;
  final int primaryBranch;
  final int total;
  final double ratio;
  final double averageConfidence;

  const _Metrics({
    required this.grain,
    required this.primaryBranch,
    required this.total,
    required this.ratio,
    required this.averageConfidence,
  });

  factory _Metrics.fromInference(PanicleInferenceResult result) {
    final counts = result.countsByLabel;
    final grain = counts['Grain'] ?? 0;
    final primaryBranch = counts['Primary branch'] ?? 0;
    final total = result.totalDetections;
    final double ratio = total == 0 ? 0 : grain / total;
    final double avgConfidence = result.detections.isEmpty
        ? 0
        : result.detections.map((d) => d.confidence).reduce((a, b) => a + b) /
              result.detections.length;
    return _Metrics(
      grain: grain,
      primaryBranch: primaryBranch,
      total: total,
      ratio: ratio,
      averageConfidence: avgConfidence,
    );
  }

}

void _logResult(AnalysisResult result) {
  debugPrint(
    'Analysis result -> id:${result.id} '
    'grains:${result.grains} primary:${result.primaryBranch} '
    'total:${result.totalSpikelets} ratio:${(result.filledRatio * 100).toStringAsFixed(1)}% '
    'confidence:${(result.confidence * 100).toStringAsFixed(1)}%',
  );
}
