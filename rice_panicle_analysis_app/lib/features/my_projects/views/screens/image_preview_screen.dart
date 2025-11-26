import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({
    super.key,
    required this.imageUrls,
    this.annotatedImageUrls = const [],
    this.analysisResults = const [],
    this.initialIndex = 0,
    this.onAnalyzeOne,
    this.onAnalyzeAll,
  });

  final List<String> imageUrls;
  final List<String?> annotatedImageUrls;
  final List<AnalysisResult?> analysisResults;
  final int initialIndex;
  final void Function(int index)? onAnalyzeOne;
  final VoidCallback? onAnalyzeAll;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late final PageController _controller;
  late int _current;
  bool _showAnnotated = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _controller = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          'Phân tích ảnh',
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
                  ? 'Hiển thị ảnh gốc'
                  : 'Hiển thị ảnh đã phân tích',
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
                    onPageChanged: (i) => setState(() => _current = i),
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (_, i) {
                      final source = _imageForIndex(i);
                      return Container(
                        color: isDark ? Colors.black : Colors.black87,
                        alignment: Alignment.center,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _buildImage(
                            source,
                            BoxFit.contain,
                            isDark,
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
                          'Grain: ${currentResult.grains} | Tổng: ${currentResult.totalSpikelets != 0 ? currentResult.totalSpikelets : currentResult.grains} | Độ tin cậy: ${(currentResult.confidence * 100).toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.green[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (hasAnnotated)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _showAnnotated
                              ? 'Đang hiển thị ảnh đã phân tích'
                              : 'Đang hiển thị ảnh gốc',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : Colors.green[900],
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
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onAnalyzeOne?.call(_current),
                      icon: const Icon(Icons.psychology_alt_rounded, size: 18),
                      label: const Text('Phân tích ảnh này'),
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
                      onPressed: widget.onAnalyzeAll,
                      icon: const Icon(Icons.auto_graph_rounded, size: 18),
                      label: const Text('Phân tích tất cả'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
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
        child: Icon(
          Icons.broken_image,
          size: size,
          color: Colors.grey,
        ),
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
    return widget.annotatedImageUrls.any(
      (value) => value != null && value.isNotEmpty,
    );
  }

  String _imageForIndex(int index, {bool? preferAnnotated}) {
    final wantsAnnotated =
        preferAnnotated ?? (_showAnnotated && _hasAnnotatedImages);
    if (wantsAnnotated &&
        index < widget.annotatedImageUrls.length &&
        widget.annotatedImageUrls[index] != null &&
        widget.annotatedImageUrls[index]!.isNotEmpty) {
      return widget.annotatedImageUrls[index]!;
    }
    return widget.imageUrls[index];
  }

  AnalysisResult? _resultForIndex(int index) {
    if (index < widget.analysisResults.length) {
      return widget.analysisResults[index];
    }
    return null;
  }

  String _statusTextFor(AnalysisResult? result) {
    if (result == null) {
      return 'Ảnh chưa được phân tích';
    }
    final date = result.processedAt;
    return 'Đã phân tích lúc ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ngày ${date.day}/${date.month}/${date.year}';
  }
}
