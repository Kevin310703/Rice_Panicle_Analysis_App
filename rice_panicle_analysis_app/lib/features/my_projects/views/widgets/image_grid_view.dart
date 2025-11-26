import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/hill.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/image_panicle.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/image_card.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/empty_states.dart';

class ImageGridView extends StatelessWidget {
  final Hill hill;
  final List<ImagePanicle> hillImages;
  final int regionIndex;
  final bool isDark;
  final Function(int) onImageTap;
  final ProjectController projectController;
  final Map<String, AnalysisResult> analysisByImage;

  const ImageGridView({
    super.key,
    required this.hill,
    required this.hillImages,
    required this.regionIndex,
    required this.isDark,
    required this.onImageTap,
    required this.projectController,
    required this.analysisByImage,
  });

  AnalysisResult? _resultFor(ImagePanicle image) {
    return analysisByImage[image.id];
  }

  String _infoLabelFor(ImagePanicle image) {
    final result = _resultFor(image);
    if (result == null) return 'Chưa phân tích';
    final grains = result.grains;
    return 'Grain $grains';
  }

  bool _hasAnnotatedImage(ImagePanicle image) {
    final result = _resultFor(image);
    if (result == null) return false;
    final local = result.localBoundingImagePath;
    final remote = result.boundingImageUrl;
    return (local != null && local.isNotEmpty) ||
        (remote != null && remote.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = hillImages.length;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hill.hillLabel.isNotEmpty
                          ? hill.hillLabel
                          : 'Hill ${regionIndex + 1}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Images ($imageCount)',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Obx(
                  () => projectController.selectedImages.isNotEmpty
                      ? TextButton.icon(
                          onPressed: () =>
                              projectController.selectedImages.clear(),
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Deselect all'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),

          // Progress bar
          Obx(() {
            final total = imageCount == 0 ? 1 : imageCount;
            final progress = projectController.selectedImages.length / total;
            return Column(
              children: [
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.7 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                if (projectController.selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${projectController.selectedImages.length}/${imageCount == 0 ? 0 : imageCount} images selected',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(height: 16),

          // Grid or empty state
          if (hillImages.isEmpty)
            EmptyImagesCard(isDark: isDark)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: hillImages.length,
              itemBuilder: (context, index) {
                final image = hillImages[index];
                final infoLabel = _infoLabelFor(image);
                final result = _resultFor(image);

                return Obx(() {
                  final isSelected = projectController.selectedImages.contains(
                    index,
                  );
                  final isProcessing =
                      projectController.processingImageId == image.id &&
                      projectController.isAnalyzing;
                  return ModernImageCard(
                    imageUrl: image.imagePath,
                    bottomLabel: infoLabel,
                    isSelected: isSelected,
                    onTap: () => onImageTap(index),
                    onLongPress: () {
                      HapticFeedback.selectionClick();
                      projectController.toggleImageSelection(index);
                    },
                    isDark: isDark,
                    isAnalyzed: result != null,
                    hasAnnotatedImage: _hasAnnotatedImage(image),
                    isProcessing: isProcessing,
                  );
                });
              },
            ),
        ],
      ),
    );
  }
}
