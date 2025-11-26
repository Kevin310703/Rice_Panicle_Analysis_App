import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show
        BackgroundIsolateBinaryMessenger,
        RootIsolateToken,
        rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Immutable configuration used by [PanicleAiService].
class PanicleModelConfig {
  const PanicleModelConfig({
    this.modelAssetPath = 'assets/models/GrainNuber.onnx',
    this.inputWidth = 640,
    this.inputHeight = 640,
    this.inputChannels = 3,
    this.scoreThreshold = 0.25,
    this.iouThreshold = 0.45,
    this.classLabels = const ['Grain', 'Primary branch'],
  });

  final String modelAssetPath;
  final int inputWidth;
  final int inputHeight;
  final int inputChannels;
  final double scoreThreshold;
  final double iouThreshold;
  final List<String> classLabels;

  Map<String, Object?> toJson() {
    return {
      'modelAssetPath': modelAssetPath,
      'inputWidth': inputWidth,
      'inputHeight': inputHeight,
      'inputChannels': inputChannels,
      'scoreThreshold': scoreThreshold,
      'iouThreshold': iouThreshold,
      'classLabels': classLabels,
    };
  }

  factory PanicleModelConfig.fromJson(Map<String, dynamic> json) {
    return PanicleModelConfig(
      modelAssetPath:
          json['modelAssetPath'] as String? ?? 'assets/models/GrainNuber.onnx',
      inputWidth: json['inputWidth'] as int? ?? 640,
      inputHeight: json['inputHeight'] as int? ?? 640,
      inputChannels: json['inputChannels'] as int? ?? 3,
      scoreThreshold: (json['scoreThreshold'] as num?)?.toDouble() ?? 0.25,
      iouThreshold: (json['iouThreshold'] as num?)?.toDouble() ?? 0.45,
      classLabels: List<String>.from(
        (json['classLabels'] as List<dynamic>? ??
                const ['Grain', 'Primary branch'])
            .map((dynamic value) => value.toString()),
      ),
    );
  }
}

/// Represents a single detection returned by the ONNX model.
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
  });

  final List<PanicleDetection> detections;
  final Size originalSize;
  final List<String> classLabels;
  final String? source;

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

/// Facade that keeps UI work on the main isolate while delegating heavy model
/// execution to a dedicated native-backed isolate.
class PanicleAiService {
  PanicleAiService._({
    PanicleModelConfig? config,
    http.Client? client,
  })  : _config = config ?? const PanicleModelConfig(),
        _client = client ?? http.Client();

  static final PanicleAiService instance = PanicleAiService._();

  final PanicleModelConfig _config;
  final http.Client _client;

  RootIsolateToken? _rootIsolateToken;
  _PanicleIsolateClient? _worker;
  Future<_PanicleIsolateClient>? _workerLoader;

  /// Warm-up the runtime so the first inference is faster.
  Future<void> warmUp() async {
    final worker = await _ensureWorker();
    await worker.warmUp();
  }

  /// Releases the underlying native resources.
  void dispose() {
    final worker = _worker;
    _worker = null;
    _workerLoader = null;
    if (worker != null) {
      unawaited(worker.dispose());
    }
    _client.close();
  }

  /// Runs inference on an image accessible via network or local asset path.
  Future<PanicleInferenceResult> analyzeRemoteImage(String path) async {
    final bytes = await _downloadBytes(path);
    return analyzeBytes(bytes, source: path);
  }

  /// Loads raw bytes for an image regardless of its source.
  Future<Uint8List> loadImageBytes(String path) {
    return _downloadBytes(path);
  }

  /// Runs inference against raw image bytes.
  Future<PanicleInferenceResult> analyzeBytes(
    Uint8List imageBytes, {
    String? source,
  }) async {
    final worker = await _ensureWorker();
    final payload = await worker.runInference(imageBytes, source: source);
    return _deserializeResult(payload);
  }

  Future<_PanicleIsolateClient> _ensureWorker() async {
    final cached = _worker;
    if (cached != null) return cached;
    final loader = _workerLoader ??= _createWorker();
    final worker = await loader;
    _worker = worker;
    _workerLoader = null;
    return worker;
  }

  Future<_PanicleIsolateClient> _createWorker() async {
    _rootIsolateToken ??= RootIsolateToken.instance;
    final token = _rootIsolateToken;
    if (token == null) {
      throw StateError(
        'Root isolate token is not available. Ensure Flutter bindings are '
        'initialized before using PanicleAiService.',
      );
    }
    final worker = _PanicleIsolateClient(
      config: _config,
      rootIsolateToken: token,
    );
    await worker.initialize();
    return worker;
  }

  PanicleInferenceResult _deserializeResult(Map<String, dynamic> payload) {
    final detectionsRaw =
        payload['detections'] as List<dynamic>? ?? const <dynamic>[];
    final detections = detectionsRaw
        .map((dynamic raw) => _deserializeDetection(raw))
        .toList(growable: false);
    final width = (payload['originalWidth'] as num?)?.toDouble() ?? 0;
    final height = (payload['originalHeight'] as num?)?.toDouble() ?? 0;
    final classLabels = List<String>.from(
      (payload['classLabels'] as List<dynamic>? ?? _config.classLabels)
          .map((dynamic value) => value.toString()),
    );

    return PanicleInferenceResult(
      detections: detections,
      originalSize: Size(width, height),
      classLabels: classLabels,
      source: payload['source'] as String?,
    );
  }

  PanicleDetection _deserializeDetection(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
    final rect = Map<String, dynamic>.from(
      map['boundingBox'] as Map<dynamic, dynamic>,
    );
    return PanicleDetection(
      boundingBox: Rect.fromLTRB(
        (rect['left'] as num).toDouble(),
        (rect['top'] as num).toDouble(),
        (rect['right'] as num).toDouble(),
        (rect['bottom'] as num).toDouble(),
      ),
      confidence: (map['confidence'] as num).toDouble(),
      classIndex: map['classIndex'] as int? ?? 0,
      label: map['label'] as String? ?? 'unknown',
    );
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
      throw Exception('File not found at $path');
    }
    return file.readAsBytes();
  }
}

class _PanicleIsolateClient {
  _PanicleIsolateClient({
    required this.config,
    required this.rootIsolateToken,
  });

  final PanicleModelConfig config;
  final RootIsolateToken rootIsolateToken;

  ReceivePort? _receivePort;
  StreamSubscription<dynamic>? _subscription;
  SendPort? _sendPort;
  Isolate? _isolate;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  int _requestId = 0;

  Future<void> initialize() async {
    if (_sendPort != null) return;
    final receivePort = ReceivePort();
    _receivePort = receivePort;
    final ready = Completer<SendPort>();

    _subscription = receivePort.listen((dynamic message) {
      if (message is SendPort && !ready.isCompleted) {
        ready.complete(message);
        return;
      }
      _handleMessage(message);
    });

    _isolate = await Isolate.spawn<List<dynamic>>(
      _panicleWorkerEntry,
      <dynamic>[
        receivePort.sendPort,
        config.toJson(),
        rootIsolateToken,
      ],
      debugName: 'PanicleAiWorker',
    );

    _sendPort = await ready.future;
  }

  Future<void> warmUp() async {
    await _sendRequest('warmUp');
  }

  Future<Map<String, dynamic>> runInference(
    Uint8List bytes, {
    String? source,
  }) async {
    final response = await _sendRequest(
      'analyze',
      payload: <String, Object?>{
        'bytes': TransferableTypedData.fromList([bytes]),
        if (source != null) 'source': source,
      },
    );
    return Map<String, dynamic>.from(
      response['result'] as Map<dynamic, dynamic>,
    );
  }

  Future<Map<String, dynamic>> _sendRequest(
    String action, {
    Map<String, Object?>? payload,
  }) {
    final sendPort = _sendPort;
    if (sendPort == null) {
      throw StateError('Panicle AI worker is not initialized.');
    }
    final id = ++_requestId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    final message = <String, Object?>{
      'id': id,
      'action': action,
      if (payload != null) ...payload,
    };

    sendPort.send(message);
    return completer.future;
  }

  void _handleMessage(dynamic message) {
    if (message is! Map) return;
    final id = message['id'];
    if (id is! int) return;
    final completer = _pending.remove(id);
    if (completer == null) return;

    final status = message['status'] as String? ?? 'ok';
    if (status == 'ok') {
      completer.complete(Map<String, dynamic>.from(message));
    } else {
      final error =
          message['error']?.toString() ?? 'Panicle AI worker encountered an error.';
      final stack = message['stack']?.toString();
      completer.completeError(
        StateError(error),
        stack == null ? null : StackTrace.fromString(stack),
      );
    }
  }

  Future<void> dispose() async {
    try {
      await _sendRequest('dispose');
    } catch (_) {
      // Worker may already be shut down.
    }
    _sendPort = null;
    await _subscription?.cancel();
    _subscription = null;
    _receivePort?.close();
    _receivePort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Panicle AI worker disposed before finishing pending jobs.'),
        );
      }
    }
    _pending.clear();
  }
}

Future<void> _panicleWorkerEntry(List<dynamic> args) async {
  final SendPort replyPort = args[0] as SendPort;
  final Map<String, dynamic> configMap =
      Map<String, dynamic>.from(args[1] as Map<dynamic, dynamic>);
  final RootIsolateToken rootToken = args[2] as RootIsolateToken;
  final receivePort = ReceivePort();
  replyPort.send(receivePort.sendPort);

  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

  final runtime = _PanicleWorkerRuntime(
    config: PanicleModelConfig.fromJson(configMap),
  );

  await for (final dynamic raw in receivePort) {
    if (raw is! Map) continue;
    final String? action = raw['action'] as String?;
    final int? id = raw['id'] as int?;
    if (action == null) continue;
    try {
      switch (action) {
        case 'warmUp':
          await runtime.warmUp();
          replyPort.send({'id': id, 'status': 'ok'});
          break;
        case 'analyze':
          final transferable =
              raw['bytes'] as TransferableTypedData?;
          if (transferable == null) {
            throw ArgumentError('Image bytes are required for analysis.');
          }
          final bytes = transferable.materialize().asUint8List();
          final source = raw['source'] as String?;
          final result = await runtime.analyze(bytes, source: source);
          replyPort.send({'id': id, 'status': 'ok', 'result': result});
          break;
        case 'dispose':
          await runtime.dispose();
          replyPort.send({'id': id, 'status': 'ok'});
          receivePort.close();
          return;
        default:
          throw UnsupportedError('Unknown worker action: $action');
      }
    } catch (err, stack) {
      replyPort.send({
        'id': id,
        'status': 'error',
        'error': err.toString(),
        'stack': stack.toString(),
      });
    }
  }
}

class _PanicleWorkerRuntime {
  _PanicleWorkerRuntime({required PanicleModelConfig config})
      : _config = config,
        _runtime = OnnxRuntime(),
        _modelInputWidth = config.inputWidth,
        _modelInputHeight = config.inputHeight;

  final PanicleModelConfig _config;
  final OnnxRuntime _runtime;
  OrtSession? _session;
  Future<OrtSession>? _sessionLoader;
  int _modelInputWidth;
  int _modelInputHeight;
  bool _shapeResolved = false;

  Future<void> warmUp() async {
    await _ensureSession();
  }

  Future<Map<String, dynamic>> analyze(
    Uint8List bytes, {
    String? source,
  }) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw ArgumentError('Khong the doc du lieu anh de phan tich.');
    }

    final session = await _ensureSession();
    final targetWidth = _modelInputWidth;
    final targetHeight = _modelInputHeight;
    final resized = img.copyResize(
      decoded,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );

    OrtValue? inputTensor;
    Map<String, OrtValue>? outputs;

    try {
      inputTensor = await _buildInputTensor(
        resized,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      outputs = await _runInference(session, inputTensor);
      final firstOutput =
          outputs.values.isEmpty ? null : outputs.values.first;
      if (firstOutput == null) {
        throw StateError('Khong nhan duoc du lieu dau ra tu mo hinh.');
      }

      final detections = await _parseDetections(
        firstOutput,
        originalWidth: decoded.width,
        originalHeight: decoded.height,
        processedWidth: targetWidth,
        processedHeight: targetHeight,
      );

      return _serializeResult(
        detections: detections,
        originalWidth: decoded.width,
        originalHeight: decoded.height,
        source: source,
      );
    } finally {
      if (inputTensor != null) {
        await inputTensor.dispose();
      }
      if (outputs != null) {
        for (final value in outputs.values) {
          await value.dispose();
        }
      }
    }
  }

  Future<void> dispose() async {
    final session = _session;
    _session = null;
    if (session != null) {
      await session.close();
    }
  }

  Future<OrtSession> _ensureSession() async {
    if (_session != null) {
      if (!_shapeResolved) {
        await _initializeModelShape(_session!);
      }
      return _session!;
    }
    _sessionLoader ??= _createSession();
    return _sessionLoader!;
  }

  Future<OrtSession> _createSession() async {
    try {
      final options = OrtSessionOptions(
        intraOpNumThreads: 1,
        interOpNumThreads: 1,
      );
      final session = await _runtime.createSessionFromAsset(
        _config.modelAssetPath,
        options: options,
      );
      await _initializeModelShape(session);
      _session = session;
      return session;
    } catch (err, stack) {
      debugPrint('Failed to initialize ONNX session: $err\n$stack');
      rethrow;
    } finally {
      _sessionLoader = null;
    }
  }

  Future<Map<String, OrtValue>> _runInference(
    OrtSession session,
    OrtValue input,
  ) {
    final inputs = <String, OrtValue>{
      session.inputNames.first: input,
    };
    return session.run(inputs);
  }

  Future<void> _initializeModelShape(OrtSession session) async {
    if (_shapeResolved) return;
    try {
      final info = await session.getInputInfo();
      if (info.isEmpty) return;
      final shape = info.first['shape'];
      if (shape is List && shape.length >= 4) {
        final dims = shape.map((dynamic value) {
          if (value is num) return value.toInt();
          return null;
        }).toList();
        if (dims.contains(null)) return;
        int? height;
        int? width;
        if (dims[1] == _config.inputChannels) {
          height = dims[2];
          width = dims[3];
        } else {
          height = dims[1];
          width = dims[2];
        }
        if (height != null && height > 0) {
          _modelInputHeight = height;
        }
        if (width != null && width > 0) {
          _modelInputWidth = width;
        }
        _shapeResolved = true;
      }
    } catch (err, stack) {
      debugPrint('Failed to read model input shape: $err\n$stack');
    }
  }

  Future<OrtValue> _buildInputTensor(
    img.Image image, {
    required int targetWidth,
    required int targetHeight,
  }) {
    final floats = _imageToFloat32(image);
    final shape = [
      1,
      _config.inputChannels,
      targetHeight,
      targetWidth,
    ];
    return OrtValue.fromList(floats, shape);
  }

  Float32List _imageToFloat32(img.Image image) {
    final bytes = image.getBytes(order: img.ChannelOrder.rgb);
    final planeSize = image.width * image.height;
    final data = Float32List(planeSize * _config.inputChannels);

    for (var i = 0; i < planeSize; i++) {
      final r = bytes[i * 3];
      final g = bytes[i * 3 + 1];
      final b = bytes[i * 3 + 2];
      data[i] = r / 255.0;
      data[planeSize + i] = g / 255.0;
      data[planeSize * 2 + i] = b / 255.0;
    }

    return data;
  }

  Future<List<PanicleDetection>> _parseDetections(
    OrtValue output, {
    required int originalWidth,
    required int originalHeight,
    required int processedWidth,
    required int processedHeight,
  }) async {
    final value = await output.asList();
    final rows = _transposeOutput(value);
    final detections = <PanicleDetection>[];
    final xFactor = originalWidth / processedWidth;
    final yFactor = originalHeight / processedHeight;

    for (final row in rows) {
      if (row.length < 6) continue;
      final classesScores = row
          .sublist(4)
          .map((e) => (e as num).toDouble())
          .toList(growable: false);
      if (classesScores.isEmpty) continue;

      final maxScore = classesScores.reduce(math.max);
      if (maxScore < _config.scoreThreshold) continue;
      final classId = classesScores.indexOf(maxScore);

      final cx = (row[0] as num).toDouble();
      final cy = (row[1] as num).toDouble();
      final w = (row[2] as num).toDouble();
      final h = (row[3] as num).toDouble();

      final left = (cx - w / 2) * xFactor;
      final top = (cy - h / 2) * yFactor;
      final width = w * xFactor;
      final height = h * yFactor;

      detections.add(
        PanicleDetection(
          boundingBox: Rect.fromLTWH(
            left.clamp(0, originalWidth.toDouble()),
            top.clamp(0, originalHeight.toDouble()),
            width,
            height,
          ),
          confidence: maxScore,
          classIndex: classId,
          label: _labelFor(classId),
        ),
      );
    }

    return _applyNonMaxSuppression(detections);
  }

  List<List<double>> _transposeOutput(List<dynamic> value) {
    List<dynamic> tensor = value;
    while (tensor.length == 1 && tensor.first is List) {
      tensor = tensor.first as List<dynamic>;
    }
    if (tensor.isEmpty || tensor.first is! List) {
      return const [];
    }
    final channels = tensor.length;
    final anchors = (tensor.first as List).length;
    final rows = List<List<double>>.generate(
      anchors,
      (anchor) => List<double>.filled(channels, 0),
      growable: false,
    );
    for (var c = 0; c < channels; c++) {
      final column = tensor[c] as List;
      for (var anchor = 0; anchor < anchors; anchor++) {
        rows[anchor][c] = (column[anchor] as num).toDouble();
      }
    }
    return rows;
  }

  List<PanicleDetection> _applyNonMaxSuppression(
    List<PanicleDetection> detections,
  ) {
    if (detections.length < 2) return detections;

    final sorted = List<PanicleDetection>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final kept = <PanicleDetection>[];

    for (final detection in sorted) {
      var shouldSelect = true;
      for (final existing in kept) {
        if (detection.classIndex == existing.classIndex) {
          final overlap = _iou(detection.boundingBox, existing.boundingBox);
          if (overlap > _config.iouThreshold) {
            shouldSelect = false;
            break;
          }
        }
      }
      if (shouldSelect) {
        kept.add(detection);
      }
    }
    return kept;
  }

  double _iou(Rect a, Rect b) {
    final x1 = math.max(a.left, b.left);
    final y1 = math.max(a.top, b.top);
    final x2 = math.min(a.right, b.right);
    final y2 = math.min(a.bottom, b.bottom);
    if (x2 <= x1 || y2 <= y1) {
      return 0;
    }
    final intersection = (x2 - x1) * (y2 - y1);
    final union = a.width * a.height + b.width * b.height - intersection;
    if (union <= 0) return 0;
    return intersection / union;
  }

  String _labelFor(int classIndex) {
    if (classIndex >= 0 && classIndex < _config.classLabels.length) {
      return _config.classLabels[classIndex];
    }
    return 'class_$classIndex';
  }

  Map<String, dynamic> _serializeResult({
    required List<PanicleDetection> detections,
    required int originalWidth,
    required int originalHeight,
    String? source,
  }) {
    return {
      'source': source,
      'originalWidth': originalWidth.toDouble(),
      'originalHeight': originalHeight.toDouble(),
      'classLabels': _config.classLabels,
      'detections': detections
          .map((detection) => {
                'boundingBox': {
                  'left': detection.boundingBox.left,
                  'top': detection.boundingBox.top,
                  'right': detection.boundingBox.right,
                  'bottom': detection.boundingBox.bottom,
                },
                'confidence': detection.confidence,
                'classIndex': detection.classIndex,
                'label': detection.label,
              })
          .toList(growable: false),
    };
  }
}
