import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/hill.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/image_panicle.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/screens/edit_project_screen.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/screens/image_preview_screen.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/screens/project_statistics_screen.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/helper/project_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/project_details_app_bar.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/project_details_stats.dart';

// Import components
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/empty_states.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/region_selector.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/image_grid_view.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/bottom_action_bar.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/options_menu.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/project_info_sheet.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/create_hill_dialog.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Project _project;
  late ProjectController _projectController;

  final ScrollController _regionScrollCtrl = ScrollController();
  late final PageController _pageController;
  Worker? _activeProjectWorker;
  Worker? _selectionWorker;

  TabController? _tabController;
  int _currentRegion = 0;
  bool _isSelectionMode = false;
  bool _hasSelection = false;

  static const int _kMaxFileSizeMB = 10;
  static const Set<String> _kImageExt = {'jpg', 'jpeg', 'png'};

  List<Hill> get _hills => _project.hills;
  Hill? get _selectedHill {
    if (_hills.isEmpty) return null;
    if (_currentRegion < 0 || _currentRegion >= _hills.length) {
      return _hills.first;
    }
    return _hills[_currentRegion];
  }

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _tabController = TabController(length: 3, vsync: this);
    _tabController?.addListener(() {
      setState(() => _currentRegion = _tabController?.index ?? 0);
    });
    _projectController = Get.find<ProjectController>();
    _projectController.setActiveProject(_project);
    _hasSelection = _projectController.selectedImages.isNotEmpty;
    _activeProjectWorker = ever<Project?>(_projectController.projectChanges, (
      updated,
    ) {
      if (!mounted || updated == null) return;
      setState(() => _project = updated);
    });
    _selectionWorker = ever<Set<int>>(_projectController.selectedImages, (
      selection,
    ) {
      if (!mounted) return;
      final hasSelection = selection.isNotEmpty;
      if (_hasSelection != hasSelection) {
        setState(() => _hasSelection = hasSelection);
      }
    });
    _pageController = PageController(initialPage: _currentRegion);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hills.isNotEmpty) {
        _setActiveHillContext(_currentRegion);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _regionScrollCtrl.dispose();
    _tabController?.dispose();
    _activeProjectWorker?.dispose();
    _selectionWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          ProjectDetailsAppBar(
            project: _project,
            onBack: () => Navigator.pop(context),
            onToggleBookmark: _toggleBookmark,
            onShowOptions: () => _showOptionsMenu(context),
            onShowStatistics: _openStatistics,
            isSelectionMode: _isSelectionMode,
            hasSelection: _hasSelection,
            onToggleSelectionMode: _toggleSelectionMode,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                ProjectDetailsStats(project: _project, isDark: isDark),
                _buildRegionSelector(isDark),
                _buildRegionPages(isDark),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final selectedCount = _projectController.selectedImages.length;
        final hasSelection = selectedCount > 0;
        final isAnalyzing = _projectController.isAnalyzing;
        if (!hasSelection && !isAnalyzing) {
          return const SizedBox();
        }
        if (_isSelectionMode && hasSelection) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'delete_selected_fab',
                onPressed: selectedCount == 0
                    ? null
                    : () => _confirmDeleteSelectedImages(selectedCount),
                backgroundColor: Colors.red,
                label: Text(
                  'Delete ($selectedCount)',
                  style: const TextStyle(color: Colors.white),
                ),
                icon: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              const SizedBox(height: 12),
              _buildAnalysisFAB(
                selectedCount,
                isAnalyzing,
                heroTag: 'analyze_selected_fab',
              ),
            ],
          );
        }
        return _buildAnalysisFAB(
          selectedCount,
          isAnalyzing,
          heroTag: 'analyze_selected_fab',
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomActionBar(
        onTakePhoto: () => _takePhoto(context),
        onUploadPhoto: () => _pickImageFromGallery(context),
        isDark: isDark,
      ),
    );
  }

  // ==================== REGION SELECTOR ====================
  Widget _buildRegionSelector(bool isDark) {
    return RegionSelector(
      hills: _hills,
      currentRegion: _currentRegion,
      onRegionSelected: _onRegionSelected,
      onAddRegion: _showCreateRegionDialog,
      isDark: isDark,
      scrollController: _regionScrollCtrl,
      onRenameHill: _promptRenameHill,
      onDeleteHill: _confirmDeleteHill,
    );
  }

  Future<void> _onRegionSelected(int index) async {
    setState(() => _currentRegion = index);
    _clearSelection();
    _setActiveHillContext(index);
    _tabController?.animateTo(index);
    await _centerRegion(index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _centerRegion(int index) async {
    if (!_regionScrollCtrl.hasClients) return;
    const double cardWidth = 140;
    const double spacing = 12;
    const double leading = 16;
    final screenW = MediaQuery.of(context).size.width;

    final target =
        leading + index * (cardWidth + spacing) - (screenW - cardWidth) / 2;

    final maxScroll = _regionScrollCtrl.position.maxScrollExtent;
    final minScroll = _regionScrollCtrl.position.minScrollExtent;

    final clamped = target.clamp(minScroll, maxScroll);
    await _regionScrollCtrl.animateTo(
      clamped.toDouble(),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _toggleSelectionMode() {
    if (_isSelectionMode) {
      _clearSelection();
    } else {
      setState(() => _isSelectionMode = true);
    }
  }

  void _enterSelectionMode() {
    if (!_isSelectionMode) {
      setState(() => _isSelectionMode = true);
    }
  }

  void _clearSelection({bool exitMode = true}) {
    _projectController.selectedImages.clear();
    if (exitMode && _isSelectionMode) {
      setState(() => _isSelectionMode = false);
    }
  }

  // ==================== REGION PAGES ====================
  Widget _buildRegionPages(bool isDark) {
    final hillCount = _hills.length;
    if (hillCount == 0) {
      return EmptyHillState(
        isDark: isDark,
        onCreateHill: _showCreateRegionDialog,
      );
    }
    return SizedBox(
      height: 920,
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentRegion = index);
          _clearSelection();
          _setActiveHillContext(index);
          _tabController?.animateTo(index);
          _centerRegion(index);
        },
        itemCount: hillCount,
        itemBuilder: (context, regionIndex) {
          return _buildRegionGrid(isDark, regionIndex);
        },
      ),
    );
  }

  Widget _buildRegionGrid(bool isDark, int regionIndex) {
    if (regionIndex < 0 || regionIndex >= _hills.length) {
      return const SizedBox.shrink();
    }
    final hill = _hills[regionIndex];
    final hillImages = _imagesForHill(hill.id);
    final resultMap = _latestResultsByImage();
    final previewUrls = hillImages.map((img) => img.imagePath).toList();
    final annotatedPreviews = _annotatedPathsFor(hillImages, resultMap);
    final resultList = _resultsFor(hillImages, resultMap);

    return ImageGridView(
      hill: hill,
      hillImages: hillImages,
      regionIndex: regionIndex,
      isDark: isDark,
      projectController: _projectController,
      analysisByImage: resultMap,
      selectionMode: _isSelectionMode,
      onEnterSelectionMode: _enterSelectionMode,
      onImagesChanged: _refreshProject,
      onImageTap: (index) {
        Get.to(
          () => ImagePreviewScreen(
            projectId: _project.id,
            imageIds: hillImages.map((img) => img.id).toList(),
            imageUrls: previewUrls,
            annotatedImageUrls: annotatedPreviews,
            analysisResults: resultList,
            initialIndex: index,
            onAnalyzeOne: (idx) async {
              await _analyzeImagesFromPreview(
                hill: hill,
                hillImages: hillImages,
                indexes: [idx],
              );
            },
            onAnalyzeAll: () async {
              await _analyzeImagesFromPreview(
                hill: hill,
                hillImages: hillImages,
                indexes: List<int>.generate(hillImages.length, (i) => i),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _analyzeImagesFromPreview({
    required Hill hill,
    required List<ImagePanicle> hillImages,
    required List<int> indexes,
  }) async {
    if (indexes.isEmpty || hillImages.isEmpty) return;
    final valid = indexes
        .where((index) => index >= 0 && index < hillImages.length)
        .toSet();
    if (valid.isEmpty) return;

    _projectController.setActiveHillContext(
      hillId: hill.id,
      images: hillImages,
    );

    _clearSelection();
    for (final index in valid) {
      _projectController.selectedImages.add(index);
    }
    _projectController.selectedImages.refresh();

    await _projectController.startAnalysis();
    await _refreshProject();
  }

  // ==================== CREATE HILL DIALOG ====================
  Future<void> _showCreateRegionDialog() async {
    final result = await CreateHillDialog.show(context);
    if (result != null && result.label.isNotEmpty) {
      await _handleCreateHill(result);
    }
  }

  Future<void> _handleCreateHill(HillDialogResult data) async {
    final cleanedNote = data.note.trim().isEmpty ? null : data.note.trim();
    final result = await _projectController.createHill(
      projectId: _project.id,
      hillLabel: data.label,
      notes: cleanedNote,
    );

    if (!mounted) return;

    if (result.success) {
      await _refreshProject();
      final newIndex = _hills.isEmpty ? 0 : _hills.length - 1;
      setState(() => _currentRegion = newIndex);
      _clearSelection();

      await Future.delayed(const Duration(milliseconds: 100));

      final animations = <Future<void>>[_centerRegion(newIndex)];
      if (_pageController.hasClients) {
        animations.add(
          _pageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          ),
        );
      }
      await Future.wait(animations);
      _showSnack('Hill created successfully.');
    } else if (result.message.isNotEmpty) {
      _showSnack(result.message);
    }
  }

  // ==================== ANALYSIS FAB ====================
  Widget _buildAnalysisFAB(
    int selectedCount,
    bool isAnalyzing, {
    String heroTag = 'analysis_fab',
  }) {
    final processed = _projectController.analysisProcessedCount;
    final total = _projectController.analysisTotalCount;
    final progressLabel = total > 0
        ? 'Dang ph?n t?ch $processed/$total'
        : 'Dang ph?n t?ch...';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: heroTag,
          onPressed: isAnalyzing
              ? null
              : () => _projectController.startAnalysis(),
          backgroundColor: const Color(0xFF4CAF50),
          elevation: 8,
          icon: const Icon(Icons.science_rounded, color: Colors.white),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAnalyzing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              if (isAnalyzing) const SizedBox(width: 8),
              Text(
                isAnalyzing ? progressLabel : 'Analyze ($selectedCount)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (isAnalyzing) const SizedBox(height: 8),
        if (isAnalyzing)
          TextButton.icon(
            onPressed: () => _projectController.cancelAnalysis(),
            icon: const Icon(Icons.close_rounded, color: Colors.red),
            label: const Text(
              'H?y ph?n t?ch',
              style: TextStyle(color: Colors.red),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDeleteSelectedImages(int count) async {
    final hill = _selectedHill;
    if (hill == null || count == 0) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text('Delete $count image${count == 1 ? '' : 's'}'),
          ],
        ),
        content: const Text(
          'Selected images and their analysis results will be permanently removed. This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final hillImages = _imagesForHill(hill.id);
    final targets = _projectController.selectedImages
        .where((index) => index >= 0 && index < hillImages.length)
        .map((index) => hillImages[index])
        .toList();
    if (targets.isEmpty) {
      _clearSelection();
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      for (final image in targets) {
        await _projectController.deleteProjectImage(
          projectId: _project.id,
          image: image,
        );
      }
    } finally {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }

    _clearSelection();
    await _refreshProject();
    _showSnack(
      '${targets.length} image${targets.length == 1 ? '' : 's'} deleted.',
    );
  }

  // ==================== OPTIONS MENU ====================
  void _showOptionsMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    OptionsMenu.show(
      context: context,
      isDark: isDark,
      onProjectInfo: () => _showProjectInfo(context),
      onShare: () => _shareProject(context),
      onEdit: () async {
        final result = await Get.to(() => EditProjectScreen(project: _project));
        if (result == true) {
          await _refreshProject();
        }
      },
      onDelete: () => _showDeleteConfirmation(context),
    );
  }

  void _showProjectInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ProjectInfoSheet.show(context: context, project: _project, isDark: isDark);
  }

  // ==================== IMAGE PICKER & UPLOAD ====================
  List<ImagePanicle> _imagesForHill(String hillId) {
    return _project.panicleImages.where((img) => img.hillId == hillId).toList();
  }

  Map<String, AnalysisResult> _latestResultsByImage() {
    final map = <String, AnalysisResult>{};
    for (final result in _project.aiResults) {
      final existing = map[result.imageId];
      if (existing == null ||
          (existing.processedAt.isBefore(result.processedAt))) {
        map[result.imageId] = result;
      }
    }
    return map;
  }

  List<String?> _annotatedPathsFor(
    List<ImagePanicle> images,
    Map<String, AnalysisResult> resultMap,
  ) {
    return images.map((image) {
      final result = resultMap[image.id];
      if (result == null) return null;
      final local = result.localBoundingImagePath;
      if (local != null && local.isNotEmpty) return local;
      final remote = result.boundingImageUrl;
      if (remote != null && remote.isNotEmpty) return remote;
      return null;
    }).toList();
  }

  List<AnalysisResult?> _resultsFor(
    List<ImagePanicle> images,
    Map<String, AnalysisResult> resultMap,
  ) {
    return images.map((image) => resultMap[image.id]).toList();
  }

  void _setActiveHillContext(int regionIndex) {
    if (regionIndex < 0 || regionIndex >= _hills.length) return;
    final hill = _hills[regionIndex];
    final hillImages = _imagesForHill(hill.id);
    _projectController.setActiveHillContext(
      hillId: hill.id,
      images: hillImages,
    );
  }

  Future<void> _takePhoto(BuildContext context) async {
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showSnack('Camera permission denied');
        return;
      }
    }

    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      await _uploadManyAndRefresh([photo], 'image', _kImageExt);
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    if (!kIsWeb) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        _showSnack('Access to photo library was denied');
        return;
      }
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      await _uploadManyAndRefresh(images, 'image', _kImageExt);
    }
  }

  Future<void> _uploadManyAndRefresh(
    List<XFile> files,
    String _type,
    Set<String> allowedExtensions,
  ) async {
    final accepted = <XFile>[];
    for (final f in files) {
      final ext = _extOf(f.name);
      if (allowedExtensions.contains(ext) && await _isWithinSize(f)) {
        accepted.add(f);
      }
    }

    if (accepted.isEmpty) return;

    final hill = _selectedHill;
    if (hill == null) {
      _showSnack('Please select a hill first to upload photos.');
      return;
    }

    final payloads = <ProjectImageUploadPayload>[];
    for (final f in accepted) {
      final bytes = await f.readAsBytes();
      payloads.add(
        ProjectImageUploadPayload(
          bytes: bytes,
          extension: _extOf(f.name),
          fileName: f.name,
        ),
      );
    }

    if (payloads.isEmpty) return;

    var dialogShown = false;
    void showLoading() {
      if (dialogShown) return;
      dialogShown = true;
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
    }

    void hideLoading() {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
      dialogShown = false;
    }

    try {
      showLoading();
      final result = await _projectController.uploadImagesToHill(
        projectId: _project.id,
        hillId: hill.id,
        files: payloads,
      );
      if (result.success) {
        _clearSelection();
        await _refreshProject();
        _showSnack(
          'Successfully uploaded ${payloads.length} photo${payloads.length == 1 ? '' : 's'}.',
        );
      } else {
        _showSnack(
          result.message.isNotEmpty
              ? result.message
              : 'Failed to upload photos. Please try again.',
        );
      }
    } catch (e) {
      _showSnack('An error occurred while uploading photos. Please try again.');
    } finally {
      hideLoading();
    }
  }

  // ==================== UTILS ====================
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF4CAF50),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _extOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  Future<bool> _isWithinSize(XFile f) async {
    final bytes = await f.length();
    return bytes <= _kMaxFileSizeMB * 1024 * 1024;
  }

  Future<void> _refreshProject() async {
    final controller = Get.find<ProjectController>();
    final updated = await controller.getProjectById(_project.id);
    if (updated != null) {
      setState(() {
        _project = updated;
        if (_currentRegion >= _hills.length) {
          _currentRegion = _hills.isEmpty ? 0 : _hills.length - 1;
        }
      });
      _projectController.setActiveProject(_project);
      _setActiveHillContext(_currentRegion);
    }
  }

  Future<void> _promptRenameHill(Hill hill) async {
    final dialogResult = await CreateHillDialog.show(
      context,
      title: 'Rename hill',
      description: 'Update the name or note for this hill.',
      confirmLabel: 'Rename hill',
      initialLabel: hill.hillLabel,
      initialNote: hill.notes ?? '',
    );
    if (dialogResult == null) return;
    final newName = dialogResult.label.trim();
    final newNote = dialogResult.note.trim();
    if (newName.isEmpty) {
      _showSnack('Hill name cannot be empty.');
      return;
    }
    if (newName == hill.hillLabel && newNote == (hill.notes ?? '')) return;

    final result = await _projectController.renameHill(
      projectId: _project.id,
      hillId: hill.id,
      hillLabel: newName,
      notes: newNote.isEmpty ? null : newNote,
    );

    if (result.success) {
      await _refreshProject();
      final index = _hills.indexWhere((element) => element.id == hill.id);
      if (index >= 0) {
        setState(() => _currentRegion = index);
        _setActiveHillContext(index);
      }
      _showSnack('Hill renamed successfully.');
    } else if (result.message.isNotEmpty) {
      _showSnack(result.message);
    }
  }

  Future<void> _confirmDeleteHill(Hill hill) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete hill'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${hill.hillLabel}"? '
          'All images and results for this hill will also be removed. '
          'This action cannot be undone.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _projectController.deleteHill(
      projectId: _project.id,
      hillId: hill.id,
    );

    if (result.success) {
      _clearSelection();
      await _refreshProject();
      if (_hills.isNotEmpty) {
        final nextIndex = _currentRegion.clamp(0, _hills.length - 1).toInt();
        setState(() => _currentRegion = nextIndex);
        _setActiveHillContext(nextIndex);
      } else {
        setState(() => _currentRegion = 0);
      }
      _showSnack('Hill deleted successfully.');
    } else if (result.message.isNotEmpty) {
      _showSnack(result.message);
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete project'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this project? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final controller = Get.find<ProjectController>();
              await controller.deleteProject(_project.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProject(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final projectLink = 'https://yourapp.com/project/${_project.id}';
    final shareMessage =
        '''
${_project.projectName}

${_project.description}

View project: $projectLink
Status: ${_project.statusString}
Photos: ${_project.images.length}
Analyses: ${_project.analyzedImageCount}
''';

    try {
      await Share.share(
        shareMessage,
        subject: 'Project: ${_project.projectName}',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (e) {
      _showSnack('Failed to share project');
    }
  }

  void _openStatistics() {
    Get.to(
      () => ProjectStatisticsScreen(
        project: _project,
        seasonTitle: _project.projectName,
      ),
    );
  }

  void _toggleBookmark() {
    setState(() {
      _project = _project.copyWith(isBookmark: !_project.isBookmark);
    });
    _showSnack(
      _project.isBookmark ? 'Added to favorites' : 'Removed from favorites',
    );
  }
}
