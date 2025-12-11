import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ModernImageCard extends StatelessWidget {
  final String imageUrl;
  final String bottomLabel;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isDark;
  final bool isAnalyzed;
  final bool hasAnnotatedImage;
  final bool isProcessing;
  final VoidCallback? onDelete;

  const ModernImageCard({
    super.key,
    required this.imageUrl,
    required this.bottomLabel,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    required this.isDark,
    this.isAnalyzed = false,
    this.hasAnnotatedImage = false,
    this.isProcessing = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedScale(
          scale: isSelected ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF4CAF50).withOpacity(0.35)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: isSelected ? 14 : 8,
                  spreadRadius: isSelected ? 1 : 0,
                  offset: Offset(0, isSelected ? 8 : 2),
                ),
              ],
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
            ),
            child: Stack(
              children: [
                // Image
                ClipRRect(borderRadius: radius, child: _buildImage(isDark)),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.55, 1.0],
                    ),
                  ),
                ),

                if (isProcessing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: radius,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Grain count badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bottomLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Check badge
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  top: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isSelected ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Green overlay when selected
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: isSelected ? 0.08 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: radius,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    if (imageUrl.isEmpty) {
      return _errorPlaceholder(isDark);
    }

    if (_isNetworkImage(imageUrl)) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _errorPlaceholder(isDark),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _errorPlaceholder(isDark),
      );
    }

    if (kIsWeb) {
      return _errorPlaceholder(isDark);
    }

    final normalizedPath = _normalizeLocalPath(imageUrl);
    final file = File(normalizedPath);
    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _errorPlaceholder(isDark),
    );
  }

  Widget _errorPlaceholder(bool isDark) {
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      child: const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  bool _isNetworkImage(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  String _normalizeLocalPath(String value) {
    if (value.startsWith('file://')) {
      return Uri.parse(value).toFilePath();
    }
    return value;
  }
}
