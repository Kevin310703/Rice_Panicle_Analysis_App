import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rice_panicle_analysis_app/controllers/auth_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/image_panicle.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/helper/project_helper.dart';
import 'package:rice_panicle_analysis_app/services/local_panicle_storage_service.dart';
import 'package:rice_panicle_analysis_app/services/panicle_ai_service.dart';
import 'package:rice_panicle_analysis_app/services/panicle_analysis_result_service.dart';
import 'package:rice_panicle_analysis_app/services/project_supabase_service.dart';

class ProjectController extends GetxController {
  final RxList<Project> _allProjects = <Project>[].obs;
  final RxList<Project> _filteredProjects = <Project>[].obs;
  final Rx<Project?> _project = Rx<Project?>(null);

  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _selectedCategory = 'All'.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isAnalyzing = false.obs;
  final RxString _processingImageId = ''.obs;
  Worker? _authUserWorker;
  Worker? _profileWorker;

  String? _activeHillId;
  List<ImagePanicle> _currentHillImages = const [];
  final LocalPanicleStorageService _localStorage =
      LocalPanicleStorageService.instance;
  final PanicleAnalysisResultService _analysisResultService =
      PanicleAnalysisResultService.instance;

  // Getters
  List<Project> get allProjects => _allProjects;
  List<Project> get filteredProjects => _filteredProjects;
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  String get selectedCategory => _selectedCategory.value;
  String get searchQuery => _searchQuery.value;
  bool get isAnalyzing => _isAnalyzing.value;
  String get processingImageId => _processingImageId.value;

  String? get projectName => _project.value?.projectName;
  String? get projectDescription => _project.value?.description;

  void setActiveProject(Project project) {
    _project.value = project;
  }

  @override
  void onInit() {
    super.onInit();
    _selectedCategory.value = 'All';
    _setupAuthListeners();
    loadProjects();
  }

  @override
  void onClose() {
    _authUserWorker?.dispose();
    _profileWorker?.dispose();
    super.onClose();
  }

  final selectedImages = <int>{}.obs;

  void _setupAuthListeners() {
    if (!Get.isRegistered<AuthController>()) return;
    final authController = Get.find<AuthController>();
    _profileWorker?.dispose();
    _profileWorker = ever(
      authController.profileChanges,
      (profile) {
        if (profile?.id != null) {
          if (!_isLoading.value) {
            loadProjects();
          }
        } else if (!authController.isLoggedIn) {
          _allProjects.value = [];
          _filteredProjects.value = [];
        }
      },
    );
    _authUserWorker?.dispose();
    _authUserWorker = ever(
      authController.userChanges,
      (user) {
        if (user == null) {
          _allProjects.value = [];
          _filteredProjects.value = [];
        }
      },
    );
  }

  void toggleImageSelection(int i) {
    if (selectedImages.contains(i)) {
      selectedImages.remove(i);
    } else {
      selectedImages.add(i);
    }
    selectedImages.refresh(); // QUAN TRỌNG với RxSet
  }

  Future<void> startAnalysis() async {
    if (_isAnalyzing.value) return;
    if (selectedImages.isEmpty) {
      Get.snackbar('Analysis', 'Please select images to analyze.');
      return;
    }
    if (_currentHillImages.isEmpty) {
      Get.snackbar('Analysis', 'No images available in this region.');
      return;
    }
    final project = _project.value;
    if (project == null) {
      Get.snackbar('Analysis', 'Project context not found.');
      return;
    }

    _isAnalyzing.value = true;
    try {
      final hillLabel = _activeHillId == null ? '' : ' at hill $_activeHillId';
      final processingMessage =
          'Processing ${selectedImages.length} images$hillLabel...';
      Get.snackbar('Analysis', processingMessage);
      final analyzer = PanicleAiService.instance;
      final indexes = selectedImages.toList()..sort();
      final results = <PanicleInferenceResult>[];

      for (final index in indexes) {
        if (index < 0 || index >= _currentHillImages.length) continue;
        final panicle = _currentHillImages[index];
        if (panicle.imagePath.isEmpty) continue;
        try {
          _processingImageId.value = panicle.id;
          final inference = await analyzer.analyzeRemoteImage(
            panicle.imagePath,
          );
          await _analysisResultService.persistResult(
            project: project,
            panicle: panicle,
            inference: inference,
          );
          results.add(inference);
        } catch (err, stack) {
          debugPrint('Error analyzing image ${panicle.id}: $err\n$stack');
        }
      }

      if (results.isEmpty) {
        Get.snackbar('Analysis', 'Unable to analyze the selected images.');
        return;
      }

      selectedImages.clear();
      final summary = _buildSummary(results);
      final ratio = summary.filledRatio.toStringAsFixed(1);
      Get.snackbar(
        'Analysis complete',
        'Filled: ${summary.grain} | Branch: ${summary.primaryBranch}\nTotal: ${summary.total} (filled ratio $ratio%)',
      );
      await loadProjects();
      final refreshed = await getProjectById(project.id);
      if (refreshed != null) {
        _project.value = refreshed;
      }
    } catch (e, stack) {
      debugPrint('Error analyzing images: $e\n$stack');
      Get.snackbar(
        'Analysis failed',
        'An error occurred while analyzing images. Please try again.',
      );
    } finally {
      _processingImageId.value = '';
      _isAnalyzing.value = false;
    }
  }

  void setActiveHillContext({
    required String hillId,
    required List<ImagePanicle> images,
  }) {
    _activeHillId = hillId;
    _currentHillImages = List<ImagePanicle>.from(images);
  }

  // Load all projects from Supabase
  Future<void> loadProjects() async {
    _isLoading.value = true;
    _hasError.value = false;
    _errorMessage.value = '';

    try {
      final authController = Get.find<AuthController>();
      await authController.profileReady;
      final profile = authController.userProfile;
      if (profile == null || profile.id == null) {
        _allProjects.value = [];
        _filteredProjects.value = [];
        return;
      }
      final projects = await ProjectSupabaseService.getAllProjects(
        createdBy: profile.id!,
      );
      final enrichedProjects = await _enrichProjects(projects);
      _allProjects.value = enrichedProjects;
      _filteredProjects.value = enrichedProjects;
    } catch (e, stack) {
      _hasError.value = true;
      _errorMessage.value = 'Failed to load projects. Please try again.';
      debugPrint('Error loading projects: $e\n$stack');

      _allProjects.value = [];
      _filteredProjects.value = [];
    } finally {
      _isLoading.value = false;
    }
  }

  // Filter projects by category
  void filterByCategory(String category) {
    _selectedCategory.value = category;
    _applyFilters();
    update(); // Notify GetBuilder widgets
  }

  // Reset filters
  void resetFilters() {
    _selectedCategory.value = 'All';
    _searchQuery.value = '';
    _filteredProjects.value = _allProjects;
    update();
  }

  // Clear search
  void clearSearch() {
    _selectedCategory.value = '';
    _applyFilters();
    update();
  }

  // Apply filters and search
  void _applyFilters() {
    List<Project> filtered = List.from(_allProjects);

    // // Apply category
    // if (_selectedCategory.value != 'All' && _selectedCategory.value.isNotEmpty) {
    //   final selectedCat = _selectedCategory.value.toLowerCase();
    //   filtered = filtered.where((project) {
    //     final projectCat = project.c
    //   })
    // }

    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered
          .where(
            (project) =>
                project.projectName.toLowerCase().contains(query) ||
                project.description.toLowerCase().contains(query),
          )
          .toList();
    }

    _filteredProjects.value = filtered;
    print('Total filtered projects: ${_filteredProjects.length}');
  }

  Future<List<Project>> searchProjects(String searchTerm) async {
    try {
      final authController = Get.find<AuthController>();
      final profile = authController.userProfile;
      if (profile == null || profile.id == null) {
        throw Exception('User context not found');
      }
      final projects = await ProjectSupabaseService.searchProjects(
        createdBy: profile.id!,
        searchTerm: searchTerm,
      );
      return await _enrichProjects(projects);
    } catch (e) {
      print('Error searching projects: $e');
      return [];
    }
  }

  // Get project by ID
  Future<Project?> getProjectById(String projectId) async {
    try {
      final authController = Get.find<AuthController>();
      final profile = authController.userProfile;
      if (profile == null || profile.id == null) return null;
      final project = await ProjectSupabaseService.getProjectById(
        projectId: projectId,
        createdBy: profile.id!,
      );
      if (project == null) return null;
      return await _enrichProject(project);
    } catch (e) {
      print('Error getting project by ID: $e');
      return null;
    }
  }

  // Refresh projects
  Future<void> refreshProjects() async {
    await loadProjects();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory.value = 'All';
    _searchQuery.value = '';
    _filteredProjects.value = _allProjects;
  }

  // Get projects for display
  List<Project> getDisplayProjects() {
    // If 'All' is selected, show all projects
    if (_selectedCategory.value == 'All') return _allProjects;

    // Otherwise, show filtered projects
    return _filteredProjects;
  }

  // Create a new project
  Future<ProjectResult> createProject(Project project) async {
    _isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final profile = authController.userProfile;

      if (profile == null || profile.id == null) {
        return ProjectResult(
          success: false,
          message: 'User context not found. Please sign in again.',
        );
      }

      final enrichedProject = project.copyWith(
        createdBy: profile.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await ProjectSupabaseService.createProject(
        enrichedProject,
      );
      await loadProjects();
      return result;
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = 'Failed to create project. Please try again.';
      print('Error creating project: $e');
      throw Exception('Failed to create project');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<ProjectResult> updateProject(Project project) async {
    _isLoading.value = true;
    try {
      final result = await ProjectSupabaseService.updateProject(project);
      await loadProjects();
      return result;
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = 'Failed to update project. Please try again.';
      print('Error updating project: $e');
      return ProjectResult(success: false, message: 'Failed to update project');
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete a project
  Future<ProjectResult> deleteProject(String projectId) async {
    _isLoading.value = true;
    try {
      final result = await ProjectSupabaseService.deleteProject(projectId);
      if (result.success) {
        await _localStorage.deleteProject(projectId);
        await _analysisResultService.deleteProject(projectId);
      }
      await loadProjects();
      return result;
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = 'Failed to delete project. Please try again.';
      print('Error deleting project: $e');
      throw Exception('Failed to delete project');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<ProjectResult> createHill({
    required String projectId,
    required String hillLabel,
    String? notes,
  }) async {
    _isLoading.value = true;
    try {
      final result = await ProjectSupabaseService.createHill(
        projectId: projectId,
        hillLabel: hillLabel,
        notes: notes,
      );
      await loadProjects();
      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<ProjectResult> uploadImagesToHill({
    required String projectId,
    required String hillId,
    required List<ProjectImageUploadPayload> files,
  }) async {
    _isLoading.value = true;
    try {
      await _localStorage.saveHillImages(
        projectId: projectId,
        hillId: hillId,
        files: files,
      );
      final updatedProject = await getProjectById(projectId);
      await loadProjects();
      return ProjectResult(
        success: true,
        project: updatedProject,
        message:
            'Đã lưu ${files.length} ảnh vào thiết bị để phân tích ngoại tuyến.',
      );
    } catch (e, stack) {
      debugPrint('Error saving local images: $e\n$stack');
      return ProjectResult(
        success: false,
        message:
            'Không thể lưu ảnh vào thiết bị. Vui lòng thử lại.',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Upload image and file
  Future<ProjectResult> updateProjectImages(
    String projectId,
    List<String> imageUrls,
  ) async {
    _isLoading.value = true;
    try {
      final result = await ProjectSupabaseService.updateProjectImages(
        projectId: projectId,
        newImageUrls: imageUrls,
      );

      await loadProjects();
      return result;
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value =
          'Failed to update project images. Please try again.';
      print('Error updating project images: $e');
      return ProjectResult(
        success: false,
        message: 'Error updating project images: $e',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<List<Project>> _enrichProjects(List<Project> projects) async {
    if (projects.isEmpty) return projects;
    final futures = projects.map(_enrichProject);
    return Future.wait(futures);
  }

  Future<Project> _enrichProject(Project project) async {
    final withBounding = _attachRemoteBoundingLogs(project);
    final withImages = await _attachLocalPanicles(withBounding);
    return _attachLocalAnalysisResults(withImages);
  }

  Future<Project> _attachLocalPanicles(Project project) async {
    final localImages = await _localStorage.getImagesForProject(project.id);
    if (localImages.isEmpty) return project;

    final mergedImages = List<ImagePanicle>.from(project.panicleImages);
    final seenIds = mergedImages.map((img) => img.id).toSet();
    for (final image in localImages) {
      if (seenIds.add(image.id)) {
        mergedImages.add(image);
      }
    }
    final mergedPaths = mergedImages.map((img) => img.imagePath).toList();
    return project.copyWith(panicleImages: mergedImages, images: mergedPaths);
  }

  Project _attachRemoteBoundingLogs(Project project) {
    if (project.analysisLogs.isEmpty || project.aiResults.isEmpty) {
      return project;
    }
    final map = <String, String>{};
    for (final log in project.analysisLogs) {
      if (!log.analysisType.startsWith('bbox_image:')) continue;
      final imageId = log.analysisType.replaceFirst('bbox_image:', '');
      final path = log.filePath;
      if (imageId.isEmpty || path == null || path.isEmpty) continue;
      map[imageId] = path;
    }
    if (map.isEmpty) return project;
    final enrichedResults = project.aiResults
        .map(
          (result) => map.containsKey(result.imageId)
              ? result.copyWith(
                  boundingImageUrl:
                      result.boundingImageUrl ?? map[result.imageId],
                )
              : result,
        )
        .toList();
    return project.copyWith(aiResults: enrichedResults);
  }

  Future<Project> _attachLocalAnalysisResults(Project project) async {
    final localResults = await _analysisResultService.getLocalResults(
      project.id,
    );
    if (localResults.isEmpty) return project;
    final mergedResults = List<AnalysisResult>.from(project.aiResults);

    for (final local in localResults) {
      final index = mergedResults.indexWhere(
        (res) =>
            res.imageId == local.imageId &&
            res.processedAt == local.processedAt,
      );
      if (index >= 0) {
        mergedResults[index] = _mergeAnalysisResult(
          mergedResults[index],
          local,
        );
      } else {
        mergedResults.add(local);
      }
    }

    return project.copyWith(aiResults: mergedResults);
  }

  AnalysisResult _mergeAnalysisResult(
    AnalysisResult base,
    AnalysisResult local,
  ) {
    return base.copyWith(
      boundingImageUrl: base.boundingImageUrl ?? local.boundingImageUrl,
      localBoundingImagePath:
          base.localBoundingImagePath ?? local.localBoundingImagePath,
      grains: base.grains == 0
          ? local.grains
          : base.grains,
      primaryBranch: base.primaryBranch == 0
          ? local.primaryBranch
          : base.primaryBranch,
      totalSpikelets: base.totalSpikelets == 0
          ? local.totalSpikelets
          : base.totalSpikelets,
      filledRatio: base.filledRatio == 0 ? local.filledRatio : base.filledRatio,
      confidence: base.confidence == 0 ? local.confidence : base.confidence,
      modelVersion: base.modelVersion == 'unknown'
          ? local.modelVersion
          : base.modelVersion,
    );
  }
}

class _AnalysisSummary {
  final int total;
  final int grain;
  final int primaryBranch;

  const _AnalysisSummary({
    required this.total,
    required this.grain,
    required this.primaryBranch,
  });

  double get filledRatio => total == 0 ? 0 : (grain / total) * 100;
}

_AnalysisSummary _buildSummary(List<PanicleInferenceResult> results) {
  var total = 0;
  var grain = 0;
  var primaryBranch = 0;

  for (final result in results) {
    total += result.totalDetections;
    final counts = result.countsByLabel;
    grain += counts['Grain'] ?? 0;
    primaryBranch += counts['Primary branch'] ?? 0;
  }

  return _AnalysisSummary(
    total: total,
    grain: grain,
    primaryBranch: primaryBranch,
  );
}
