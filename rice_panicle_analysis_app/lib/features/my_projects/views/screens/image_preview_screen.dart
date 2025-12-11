import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({
    super.key,
    required this.projectId,
    required this.imageIds,
    required this.imageUrls,
    this.annotatedImageUrls = const [],
    this.analysisResults = const [],
    this.initialIndex = 0,
    this.onAnalyzeOne,
    this.onAnalyzeAll,
  }) : assert(
         imageUrls.length == imageIds.length,
         'imageIds length must match imageUrls length',
       );

  final String projectId;
  final List<String> imageIds;
  final List<String> imageUrls;
  final List<String?> annotatedImageUrls;
  final List<AnalysisResult?> analysisResults;
  final int initialIndex;
  final Future<void> Function(int index)? onAnalyzeOne;
  final Future<void> Function()? onAnalyzeAll;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late final PageController _controller;
  late int _current;
  bool _showAnnotated = false;
  late final ProjectController _projectController;
  late List<String?> _annotatedImages;
  late List<AnalysisResult?> _analysisResults;
  bool _isActionInProgress = false;
  bool _isZoomLocked = false;

  @override
  void initState() {
    super.initState();
    _projectController = Get.find<ProjectController>();
    _current = widget.imageUrls.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _controller = PageController(initialPage: _current);
    _syncLocalDataFromWidget();
  }

  @override
  void didUpdateWidget(covariant ImagePreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final annotatedChanged = !listEquals(
      oldWidget.annotatedImageUrls,
      widget.annotatedImageUrls,
    );
    final resultChanged = !listEquals(
      oldWidget.analysisResults,
      widget.analysisResults,
    );
    if (annotatedChanged || resultChanged) {
      _syncLocalDataFromWidget();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncLocalDataFromWidget() {
    final length = widget.imageUrls.length;
    _annotatedImages = List<String?>.filled(length, null, growable: true);
    for (var i = 0; i < length && i < widget.annotatedImageUrls.length; i++) {
      _annotatedImages[i] = widget.annotatedImageUrls[i];
    }
    _analysisResults = List<AnalysisResult?>.filled(
      length,
      null,
      growable: true,
    );
    for (var i = 0; i < length && i < widget.analysisResults.length; i++) {
      _analysisResults[i] = widget.analysisResults[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAnnotated = _hasAnnotatedImages;
    final currentResult = _resultForIndex(_current);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          'Analyze image',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (hasAnnotated)
            IconButton(
              onPressed: () => setState(() => _showAnnotated = !_showAnnotated),
              icon: Icon(
                _showAnnotated ? Icons.layers_clear : Icons.layers,
                color: Colors.white,
              ),
              tooltip: _showAnnotated
                  ? 'Showing analyzed image'
                  : 'Showing original image',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PageView.builder(
                    controller: _controller,
                    physics: _isZoomLocked
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (_, i) {
                      final source = _imageForIndex(i);
                      return Container(
                        color: isDark ? Colors.black : const Color.fromARGB(221, 255, 255, 255),
                        alignment: Alignment.center,
                        child: _ZoomableImage(
                          imageToken: _zoomTokenFor(i, source),
                          onZoomChanged: _handleZoomInteractionChanged,
                          child: SizedBox.expand(
                            child: _buildImage(source, BoxFit.contain, isDark),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.withOpacity(0.12)
                      : const Color(0xFFE9F6EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _statusTextFor(currentResult),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.green[200]
                            : const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (currentResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Grain: ${currentResult.grains} | Primary branch: ${currentResult.primaryBranch} | ${_processingTimeLabel(currentResult)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.green[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (hasAnnotated)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _showAnnotated
                              ? 'Showing analyzed image'
                              : 'Showing original image',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.green[900],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                final controllerBusy = _projectController.isAnalyzing;
                final actionBusy = controllerBusy || _isActionInProgress;
                final canAnalyzeOne =
                    !actionBusy && widget.onAnalyzeOne != null;
                final canAnalyzeAll =
                    !actionBusy &&
                    widget.onAnalyzeAll != null &&
                    widget.imageUrls.isNotEmpty;
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canAnalyzeOne ? _handleAnalyzeOne : null,
                        icon: actionBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.psychology_alt_rounded,
                                size: 18,
                              ),
                        label: Text(
                          actionBusy ? 'Analyzing...' : 'Analyze this image',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canAnalyzeAll ? _handleAnalyzeAll : null,
                        icon: const Icon(Icons.auto_graph_rounded, size: 18),
                        label: const Text('Analyze all images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2E7D32),
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = i == _current;
                  return GestureDetector(
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF4CAF50)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              selected ? 0.15 : 0.06,
                            ),
                            blurRadius: selected ? 8 : 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImage(
                          _imageForIndex(i, preferAnnotated: false),
                          BoxFit.cover,
                          isDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAnalyzeOne() async {
    final callback = widget.onAnalyzeOne;
    if (callback == null) return;
    await _runAnalysisAction(() => callback(_current));
  }

  Future<void> _handleAnalyzeAll() async {
    final callback = widget.onAnalyzeAll;
    if (callback == null || widget.imageUrls.isEmpty) return;
    await _runAnalysisAction(callback);
  }

  Future<void> _runAnalysisAction(Future<void> Function() action) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    try {
      await action();
      await _refreshDataFromController();
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      } else {
        _isActionInProgress = false;
      }
    }
  }

  Future<void> _refreshDataFromController() async {
    final project = await _ensureProjectData();
    if (project == null) return;
    final resultMap = _latestResultsByImage(project);
    final updatedResults = <AnalysisResult?>[];
    final updatedAnnotated = <String?>[];
    for (var i = 0; i < widget.imageIds.length; i++) {
      final imageId = widget.imageIds[i];
      final result = resultMap[imageId];
      updatedResults.add(result);
      updatedAnnotated.add(_annotatedPathFor(result));
    }
    if (!mounted) return;
    setState(() {
      _analysisResults = updatedResults;
      _annotatedImages = updatedAnnotated;
    });
  }

  Future<Project?> _ensureProjectData() async {
    final active = _projectController.activeProject;
    if (active != null && active.id == widget.projectId) {
      return active;
    }
    final refreshed = await _projectController.getProjectById(widget.projectId);
    if (refreshed != null) {
      _projectController.setActiveProject(refreshed);
    }
    return refreshed;
  }

  Map<String, AnalysisResult> _latestResultsByImage(Project project) {
    final map = <String, AnalysisResult>{};
    for (final result in project.aiResults) {
      final existing = map[result.imageId];
      if (existing == null ||
          existing.processedAt.isBefore(result.processedAt)) {
        map[result.imageId] = result;
      }
    }
    return map;
  }

  String? _annotatedPathFor(AnalysisResult? result) {
    if (result == null) return null;
    final local = result.localBoundingImagePath;
    if (local != null && local.isNotEmpty) return local;
    final remote = result.boundingImageUrl;
    if (remote != null && remote.isNotEmpty) return remote;
    return null;
  }

  Widget _buildImage(String source, BoxFit fit, bool isDark) {
    if (source.isEmpty) {
      return _errorPlaceholder(isDark, size: fit == BoxFit.cover ? 20 : 48);
    }

    if (_isNetworkSource(source)) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            _errorPlaceholder(isDark, size: fit == BoxFit.cover ? 20 : 48),
      );
    }

    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            _errorPlaceholder(isDark, size: fit == BoxFit.cover ? 20 : 48),
      );
    }

    if (kIsWeb) {
      return _errorPlaceholder(isDark, size: fit == BoxFit.cover ? 20 : 48);
    }

    final normalized = _normalizeLocalPath(source);
    final file = File(normalized);
    return Image.file(
      file,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          _errorPlaceholder(isDark, size: fit == BoxFit.cover ? 20 : 48),
    );
  }

  Widget _errorPlaceholder(bool isDark, {double size = 40}) {
    return Container(
      color: isDark ? Colors.grey[850] : Colors.grey[200],
      child: Center(
        child: Icon(Icons.broken_image, size: size, color: Colors.grey),
      ),
    );
  }

  bool _isNetworkSource(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  String _normalizeLocalPath(String value) {
    if (value.startsWith('file://')) {
      return Uri.parse(value).toFilePath();
    }
    return value;
  }

  bool get _hasAnnotatedImages {
    return _annotatedImages.any((value) => value != null && value.isNotEmpty);
  }

  String _imageForIndex(int index, {bool? preferAnnotated}) {
    final wantsAnnotated =
        preferAnnotated ?? (_showAnnotated && _hasAnnotatedImages);
    if (wantsAnnotated &&
        index < _annotatedImages.length &&
        _annotatedImages[index] != null &&
        _annotatedImages[index]!.isNotEmpty) {
      return _annotatedImages[index]!;
    }
    if (index < widget.imageUrls.length) {
      return widget.imageUrls[index];
    }
    return '';
  }

  AnalysisResult? _resultForIndex(int index) {
    if (index < _analysisResults.length) {
      return _analysisResults[index];
    }
    return null;
  }

  String _statusTextFor(AnalysisResult? result) {
    if (result == null) {
      return 'Not analyzed yet';
    }
    final date = result.processedAt;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day;
    final month = date.month;
    final year = date.year;

    return 'Analyzed at $hour:$minute on $day/$month/$year';
  }

  String _processingTimeLabel(AnalysisResult result) {
    final ms = result.processingTimeMs ?? 0;
    if (ms <= 0) return 'Processing: N/A';
    if (ms >= 1000) {
      final seconds = (ms / 1000).toStringAsFixed(2);
      return 'Processing: ${seconds}s';
    }
    return 'Processing: ${ms.toStringAsFixed(0)} ms';
  }

  void _handleZoomInteractionChanged(bool isZoomed) {
    if (_isZoomLocked == isZoomed) return;
    setState(() => _isZoomLocked = isZoomed);
  }

  String _zoomTokenFor(int index, String source) {
    final mode = _showAnnotated ? 'annotated' : 'original';
    return '$mode-$index-${source.hashCode}';
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({
    required this.child,
    required this.imageToken,
    this.onZoomChanged,
  });

  final Widget child;
  final String imageToken;
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  late final TransformationController _controller;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _controller.addListener(_handleTransformChanged);
  }

  @override
  void didUpdateWidget(covariant _ZoomableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageToken != widget.imageToken) {
      _controller.value = Matrix4.identity();
    }
  }

  void _handleTransformChanged() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.02;
    if (zoomed == _isZoomed) return;
    setState(() => _isZoomed = zoomed);
    widget.onZoomChanged?.call(zoomed);
  }

  void _handleDoubleTap() {
    _controller.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransformChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 6,
        panEnabled: _isZoomed,
        boundaryMargin:
            _isZoomed ? const EdgeInsets.all(64) : EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
        child: widget.child,
      ),
    );
  }
}
