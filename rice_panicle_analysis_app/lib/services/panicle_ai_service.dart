import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ultralytics_yolo/yolo.dart';

class PanicleModelConfig {
  const PanicleModelConfig({
    this.modelAssetPath = 'assets/models/base_float16.tflite',
    this.labelsAssetPath = 'assets/models/labels.txt',
    this.inputWidth = 1600,
    this.inputHeight = 1600,
    this.inputChannels = 3,
    this.scoreThreshold = 0.25,
    this.iouThreshold = 0.45,
    this.useGpu = false,
    this.maxDetections = 400,
    this.classLabels = const ['Grain', 'Primary branch'],
  });

  final String modelAssetPath;
  final String labelsAssetPath;
  final int inputWidth;
  final int inputHeight;
  final int inputChannels;
  final double scoreThreshold;
  final double iouThreshold;
  final bool useGpu;
  final int maxDetections;
  final List<String> classLabels;

  Map<String, Object?> toJson() {
    return {
      'modelAssetPath': modelAssetPath,
      'labelsAssetPath': labelsAssetPath,
      'inputWidth': inputWidth,
      'inputHeight': inputHeight,
      'inputChannels': inputChannels,
      'scoreThreshold': scoreThreshold,
      'iouThreshold': iouThreshold,
      'useGpu': useGpu,
      'maxDetections': maxDetections,
      'classLabels': classLabels,
    };
  }

  factory PanicleModelConfig.fromJson(Map<String, dynamic> json) {
    return PanicleModelConfig(
      modelAssetPath:
          json['modelAssetPath'] as String? ?? 'assets/models/best.tflite',
      labelsAssetPath:
          json['labelsAssetPath'] as String? ?? 'assets/models/labels.txt',
      inputWidth: json['inputWidth'] as int? ?? 640,
      inputHeight: json['inputHeight'] as int? ?? 640,
      inputChannels: json['inputChannels'] as int? ?? 3,
      scoreThreshold: (json['scoreThreshold'] as num?)?.toDouble() ?? 0.25,
      iouThreshold: (json['iouThreshold'] as num?)?.toDouble() ?? 0.7,
      useGpu: json['useGpu'] as bool? ?? true,
      maxDetections: json['maxDetections'] as int? ?? 400,
      classLabels: List<String>.from(
        (json['classLabels'] as List<dynamic>? ??
                const ['Grain', 'Primary branch'])
            .map((dynamic value) => value.toString()),
      ),
    );
  }
}

/// Represents a single detection returned by the model.
class PanicleDetection {
  const PanicleDetection({
    required this.boundingBox,
    required this.confidence,
    required this.classIndex,
    required this.label,
  });

  final Rect boundingBox;
  final double confidence;
  final int classIndex;
  final String label;
}

/// Aggregated inference results for a single image.
class PanicleInferenceResult {
  PanicleInferenceResult({
    required this.detections,
    required this.originalSize,
    required this.classLabels,
    this.source,
    this.processingTimeMs,
  });

  final List<PanicleDetection> detections;
  final Size originalSize;
  final List<String> classLabels;
  final String? source;
  final double? processingTimeMs;

  int get totalDetections => detections.length;

  Map<String, int> get countsByLabel {
    final map = <String, int>{};
    for (final detection in detections) {
      map[detection.label] = (map[detection.label] ?? 0) + 1;
    }
    return map;
  }

  int countForLabel(String label) => countsByLabel[label] ?? 0;

  double ratioForLabel(String label) {
    if (totalDetections == 0) return 0;
    return (countForLabel(label) / totalDetections) * 100;
  }
}

/// Facade for running Ultralytics YOLO inference over panicle images.
class PanicleAiService {
  PanicleAiService._({PanicleModelConfig? config, http.Client? client})
    : _config = config ?? const PanicleModelConfig(),
      _client = client ?? http.Client();

  static final PanicleAiService instance = PanicleAiService._();

  final PanicleModelConfig _config;
  final http.Client _client;
  static const int _transportMaxDimension = 1600;
  static const int _transportJpegQuality = 85;
  static const int _transportMaxBytes = 4 * 1024 * 1024;

  YOLO? _yolo;
  Future<YOLO>? _pendingLoad;
  List<String>? _labels;
  String? _resolvedModelPath;

  Future<void> warmUp() async {
    await _ensureYolo();
  }

  void dispose() {
    final yolo = _yolo;
    _yolo = null;
    _pendingLoad = null;
    _resolvedModelPath = null;
    if (yolo != null) {
      unawaited(yolo.dispose());
    }
    _client.close();
  }

  Future<PanicleInferenceResult> analyzeRemoteImage(String path) async {
    debugPrint('Panicle AI: downloading $path');
    final bytes = await _downloadBytes(path);
    final optimized = await _optimizeImageForInference(bytes);
    debugPrint('Panicle AI: running inference for $path');
    return analyzeBytes(
      optimized,
      source: path,
      optimizeForTransport: false,
    );
  }

  Future<Uint8List> loadImageBytes(String path) => _downloadBytes(path);

  Future<PanicleInferenceResult> analyzeBytes(
    Uint8List imageBytes, {
    String? source,
    bool optimizeForTransport = true,
  }) async {
    if (imageBytes.isEmpty) {
      throw ArgumentError('Empty image data received for analysis.');
    }

    final optimized = optimizeForTransport
        ? await _optimizeImageForInference(imageBytes)
        : imageBytes;
    final decoded = img.decodeImage(optimized);
    if (decoded == null) {
      throw ArgumentError('Unable to decode image bytes for analysis.');
    }

    final model = await _ensureYolo();
    final stopwatch = Stopwatch()..start();
    final rawResult = await model.predict(
      optimized,
      confidenceThreshold: _config.scoreThreshold,
      iouThreshold: _config.iouThreshold,
      numItemsThreshold: _config.maxDetections,
    );
    stopwatch.stop();
    final yoloResults = _resultsFromPredict(rawResult);
    final labels = await _ensureLabels();
    final rawDetections = _buildDetectionsFromResults(
      yoloResults,
      labels: labels,
      originalWidth: decoded.width,
      originalHeight: decoded.height,
    );
    final detections = _limitDetections(
      rawDetections,
      _config.maxDetections,
    );

    if (source != null) {
      final processingMs = rawResult['processingTimeMs'];
      final stats = processingMs == null ? '' : ' (${processingMs}ms)';
      debugPrint(
        'Panicle AI: ${detections.length} detections for $source$stats',
      );
    }

    double? processingMsDouble;
    final rawProcessing = rawResult['processingTimeMs'];
    if (rawProcessing is num) {
      processingMsDouble = rawProcessing.toDouble();
    } else if (rawProcessing is String) {
      processingMsDouble = double.tryParse(rawProcessing);
    } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      processingMsDouble = stopwatch.elapsedMicroseconds / 1000;
    } else {
      processingMsDouble = stopwatch.elapsedMicroseconds / 1000;
    }

    return PanicleInferenceResult(
      detections: detections,
      originalSize: Size(decoded.width.toDouble(), decoded.height.toDouble()),
      classLabels: labels,
      source: source,
      processingTimeMs: processingMsDouble,
    );
  }

  Future<YOLO> _ensureYolo() {
    final cached = _yolo;
    if (cached != null) {
      return Future<YOLO>.value(cached);
    }
    final pending = _pendingLoad;
    if (pending != null) {
      return pending;
    }
    final loader = _createAndLoadYolo();
    _pendingLoad = loader;
    return loader;
  }

  Future<YOLO> _createAndLoadYolo() async {
    try {
      final modelPath = await _resolveModelPath(_config.modelAssetPath);
      final instance = YOLO(
        modelPath: modelPath,
        task: YOLOTask.detect,
        useGpu: _config.useGpu,
      );
      await instance.loadModel();
      instance.setNumItemsThreshold(_config.maxDetections);
      _yolo = instance;
      return instance;
    } finally {
      _pendingLoad = null;
    }
  }

  Future<String> _resolveModelPath(String configuredPath) async {
    if (_resolvedModelPath != null) return _resolvedModelPath!;
    if (configuredPath.startsWith('/') || configuredPath.startsWith('file://')) {
      _resolvedModelPath = configuredPath;
      return configuredPath;
    }
    if (!configuredPath.startsWith('assets/')) {
      _resolvedModelPath = configuredPath;
      return configuredPath;
    }
    final bytes = await rootBundle.load(configuredPath);
    final directory = await getApplicationSupportDirectory();
    final folder = Directory(p.join(directory.path, 'panicle_ai_models'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final file = File(p.join(folder.path, p.basename(configuredPath)));
    await file.writeAsBytes(
      bytes.buffer.asUint8List(),
      flush: true,
    );
    _resolvedModelPath = file.path;
    return file.path;
  }

  List<YOLOResult> _resultsFromPredict(Map<String, dynamic> raw) {
    final detections = raw['detections'];
    if (detections is List) {
      final results = <YOLOResult>[];
      for (final item in detections) {
        if (item is Map) {
          results.add(YOLOResult.fromMap(item));
        }
      }
      return results;
    }
    return const [];
  }

  List<PanicleDetection> _buildDetectionsFromResults(
    List<YOLOResult> results, {
    required List<String> labels,
    required int originalWidth,
    required int originalHeight,
  }) {
    final widthLimit = math.max(1, originalWidth).toDouble();
    final heightLimit = math.max(1, originalHeight).toDouble();
    final detections = <PanicleDetection>[];

    for (final result in results) {
      final score = result.confidence;
      if (score < _config.scoreThreshold) continue;

      final rect = result.boundingBox;
      final left = rect.left.clamp(0, widthLimit).toDouble();
      final top = rect.top.clamp(0, heightLimit).toDouble();
      final right = rect.right.clamp(0, widthLimit).toDouble();
      final bottom = rect.bottom.clamp(0, heightLimit).toDouble();
      final width = math.max(0.0, right - left);
      final height = math.max(0.0, bottom - top);
      if (width <= 0 || height <= 0) {
        continue;
      }

      int classIndex = result.classIndex;
      final className = result.className.trim();
      int? derivedIndex;
      if (className.isNotEmpty) {
        final parsed = int.tryParse(className);
        if (parsed != null) {
          derivedIndex = parsed;
        } else {
          final matchIndex = labels.indexWhere(
            (entry) => entry.toLowerCase() == className.toLowerCase(),
          );
          if (matchIndex >= 0) {
            derivedIndex = matchIndex;
          }
        }
      }
      if (classIndex < 0 ||
          classIndex >= labels.length ||
          (classIndex == 0 && derivedIndex != null && derivedIndex != 0)) {
        if (derivedIndex != null) {
          classIndex = derivedIndex.clamp(0, labels.length - 1);
        }
      }

      final label = _labelFor(classIndex, labels);

      detections.add(
        PanicleDetection(
          boundingBox: Rect.fromLTWH(left, top, width, height),
          confidence: score,
          classIndex: classIndex,
          label: label,
        ),
      );
    }

    return detections;
  }

  List<PanicleDetection> _limitDetections(
    List<PanicleDetection> detections,
    int maxDetections,
  ) {
    if (maxDetections <= 0 || detections.length <= maxDetections) {
      return detections;
    }
    final sorted = List<PanicleDetection>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return sorted.take(maxDetections).toList();
  }

  Future<List<String>> _ensureLabels() async {
    final cached = _labels;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    try {
      final raw = await rootBundle.loadString(_config.labelsAssetPath);
      final parsed = raw
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) {
        _labels = parsed;
        return parsed;
      }
    } catch (error) {
      debugPrint('Panicle AI: unable to load labels (${error.toString()})');
    }
    _labels = _config.classLabels;
    return _labels!;
  }

  Future<Uint8List> _downloadBytes(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final response = await _client.get(Uri.parse(path));
      if (response.statusCode >= 400) {
        throw Exception(
          'Failed to download image at $path (HTTP ${response.statusCode}).',
        );
      }
      return response.bodyBytes;
    }

    if (path.startsWith('file://')) {
      final filePath = Uri.parse(path).toFilePath();
      return _readLocalFile(filePath);
    }

    if (path.startsWith('/')) {
      return _readLocalFile(path);
    }

    final localFile = File(path);
    if (await localFile.exists()) {
      return localFile.readAsBytes();
    }

    final asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  Future<Uint8List> _readLocalFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found at $path.');
    }
    return file.readAsBytes();
  }

  Future<Uint8List> _optimizeImageForInference(Uint8List rawBytes) async {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return rawBytes;

    final maxDim = math.max(decoded.width, decoded.height);
    final needsResize = maxDim > _transportMaxDimension;
    final needsCompress = rawBytes.lengthInBytes > _transportMaxBytes;
    if (!needsResize && !needsCompress) {
      return rawBytes;
    }

    img.Image working = decoded;
    if (needsResize) {
      final scale = _transportMaxDimension / maxDim;
      final targetWidth = (decoded.width * scale).round().clamp(
        1,
        decoded.width,
      );
      final targetHeight = (decoded.height * scale).round().clamp(
        1,
        decoded.height,
      );
      working = img.copyResize(
        decoded,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    final encoded = img.encodeJpg(working, quality: _transportJpegQuality);
    final optimized = Uint8List.fromList(encoded);
    return optimized.lengthInBytes < rawBytes.lengthInBytes
        ? optimized
        : rawBytes;
  }

  // List<PanicleDetection> _applyNonMaxSuppression(
  //   List<PanicleDetection> detections,
  // ) {
  //   if (detections.length < 2) return detections;

  //   final sorted = List<PanicleDetection>.from(detections)
  //     ..sort((a, b) => b.confidence.compareTo(a.confidence));
  //   final kept = <PanicleDetection>[];

  //   for (final detection in sorted) {
  //     var shouldSelect = true;
  //     for (final existing in kept) {
  //       if (detection.classIndex == existing.classIndex) {
  //         final overlap = _iou(detection.boundingBox, existing.boundingBox);
  //         if (overlap > _config.iouThreshold) {
  //           shouldSelect = false;
  //           break;
  //         }
  //       }
  //     }
  //     if (shouldSelect) {
  //       kept.add(detection);
  //     }
  //   }
  //   return kept;
  // }

  // double _iou(Rect a, Rect b) {
  //   final x1 = math.max(a.left, b.left);
  //   final y1 = math.max(a.top, b.top);
  //   final x2 = math.min(a.right, b.right);
  //   final y2 = math.min(a.bottom, b.bottom);
  //   if (x2 <= x1 || y2 <= y1) {
  //     return 0;
  //   }
  //   final intersection = (x2 - x1) * (y2 - y1);
  //   final union = a.width * a.height + b.width * b.height - intersection;
  //   if (union <= 0) return 0;
  //   return intersection / union;
  // }

  String _labelFor(int classIndex, List<String> labels) {
    if (classIndex >= 0 && classIndex < labels.length) {
      return labels[classIndex];
    }
    return 'class_$classIndex';
  }
}
