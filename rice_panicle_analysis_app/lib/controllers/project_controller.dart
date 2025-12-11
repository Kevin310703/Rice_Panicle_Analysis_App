import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:rice_panicle_analysis_app/controllers/auth_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/image_panicle.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/helper/project_helper.dart';
import 'package:rice_panicle_analysis_app/features/notifications/models/notification.dart';
import 'package:rice_panicle_analysis_app/services/local_panicle_storage_service.dart';
import 'package:rice_panicle_analysis_app/services/notification_supabase_service.dart';
import 'package:rice_panicle_analysis_app/services/panicle_ai_service.dart';
import 'package:rice_panicle_analysis_app/services/panicle_analysis_result_service.dart';
import 'package:rice_panicle_analysis_app/services/project_supabase_service.dart';
import 'package:rice_panicle_analysis_app/services/supabase_auth_service.dart';

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
  final RxInt _analysisTotalCount = 0.obs;
  final RxInt _analysisProcessedCount = 0.obs;
  final RxBool _isCancelRequested = false.obs;
  Completer<void>? _analysisCancelToken;
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
  int get analysisTotalCount => _analysisTotalCount.value;
  int get analysisProcessedCount => _analysisProcessedCount.value;
  double get analysisProgress => _analysisTotalCount.value == 0
      ? 0
      : _analysisProcessedCount.value / _analysisTotalCount.value;
  Project? get activeProject => _project.value;
  Rx<Project?> get projectChanges => _project;
  bool get isCancelRequested => _isCancelRequested.value;

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
          update();
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
          update();
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
    await _syncActiveProjectState(silent: true);
    final currentProject = _project.value;
    if (currentProject == null) {
      Get.snackbar('Analysis', 'Project context not found.');
      return;
    }
    var project = currentProject;
    final previousStatus = project.status;
    project = await _updateProjectStatus(
          project,
          ProjectStatus.inProgress,
          silent: true,
        ) ??
        project;

    _analysisTotalCount.value = selectedImages.length;
    _analysisProcessedCount.value = 0;
    _isCancelRequested.value = false;
    _analysisCancelToken = Completer<void>();
    _isAnalyzing.value = true;

    var analysisSuccessful = false;

    try {
      final hillLabel = _activeHillId == null ? '' : ' at hill $_activeHillId';
      final processingMessage =
          'Processing ${selectedImages.length} images$hillLabel...';
      Get.snackbar('Analysis', processingMessage);
      final analyzer = PanicleAiService.instance;
        final queue = Queue<int>()
          ..addAll(selectedImages.toList()..sort());
        final results = <PanicleInferenceResult>[];
        var processed = 0;

        while (queue.isNotEmpty) {
          final index = queue.removeFirst();
          if (index < 0 || index >= _currentHillImages.length) continue;
          final panicle = _currentHillImages[index];
        if (panicle.imagePath.isEmpty) continue;
        if (_isCancelRequested.value) {
          debugPrint('Analysis canceled before processing image $index');
          break;
        }
        try {
          _processingImageId.value = panicle.id;
          debugPrint(
            'Analyzing image ${panicle.id} '
            '[${processed + 1}/${_analysisTotalCount.value}]',
          );
          project = _project.value ?? project;
          final inference = await _runCancelableInference(
            analyzer,
            panicle.imagePath,
          );
          if (inference == null) {
            throw const _AnalysisCanceledException();
          }
          await _analysisResultService.persistResult(
            project: project,
            panicle: panicle,
            inference: inference,
          );
          results.add(inference);
          debugPrint('Completed analysis for ${panicle.id}');
        } catch (err, stack) {
          debugPrint('Error analyzing image ${panicle.id}: $err\n$stack');
        } finally {
          processed += 1;
          if (_analysisTotalCount.value > 0) {
            _analysisProcessedCount.value = processed >
                    _analysisTotalCount.value
                ? _analysisTotalCount.value
                : processed;
          }
          await _syncActiveProjectState(silent: true);
          project = _project.value ?? project;
        }
      }

      if (_isCancelRequested.value) {
        throw const _AnalysisCanceledException();
      }

      if (results.isEmpty) {
        Get.snackbar('Analysis', 'Unable to analyze the selected images.');
        return;
      }
      analysisSuccessful = true;

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
    } on _AnalysisCanceledException {
      Get.snackbar(
        'Analysis canceled',
        'The current analysis has been canceled.',
      );
    } catch (e, stack) {
      debugPrint('Error analyzing images: $e\n$stack');
      Get.snackbar(
        'Analysis failed',
        'An error occurred while analyzing images. Please try again.',
      );
    } finally {
      _processingImageId.value = '';
      _isAnalyzing.value = false;
      _analysisTotalCount.value = 0;
      _analysisProcessedCount.value = 0;
      if (_analysisCancelToken != null &&
          !(_analysisCancelToken!.isCompleted)) {
        _analysisCancelToken!.complete();
      }
      _analysisCancelToken = null;
      _isCancelRequested.value = false;
      final latest = _project.value ?? project;
      if (analysisSuccessful) {
        await _updateProjectStatus(
          latest,
          ProjectStatus.completed,
          silent: true,
          force: true,
        );
      } else if (previousStatus != ProjectStatus.inProgress) {
        await _updateProjectStatus(
          latest,
          previousStatus,
          silent: true,
          force: true,
        );
      }
      await _syncActiveProjectState();
    }
  }

  void setActiveHillContext({
    required String hillId,
    required List<ImagePanicle> images,
  }) {
    _activeHillId = hillId;
    _currentHillImages = List<ImagePanicle>.from(images);
  }

  Future<void> syncActiveProject() async {
    await _syncActiveProjectState();
  }

  void cancelAnalysis() {
    if (_isAnalyzing.value && !_isCancelRequested.value) {
      _isCancelRequested.value = true;
      final token = _analysisCancelToken;
      if (token != null && !token.isCompleted) {
        token.complete();
      }
      Get.snackbar(
        'Canceling analysis',
        'Stopping after the current image...',
      );
    }
  }

  Future<void> _syncActiveProjectState({bool silent = false}) async {
    final current = _project.value;
    if (current == null) return;
    final refreshed = await getProjectById(current.id);
    if (refreshed != null) {
      _project.value = refreshed;
      _replaceProjectInCaches(refreshed);
      if (!silent) {
        update();
      }
    }
  }

  Future<Project?> _updateProjectStatus(
    Project project,
    ProjectStatus status, {
    bool silent = true,
    bool force = false,
  }) async {
    if (!force && project.status == status) return project;
    final updated = project.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    try {
      final result = await ProjectSupabaseService.updateProject(updated);
      if (result.success && result.project != null) {
        final refreshed = result.project!;
        _project.value = refreshed;
        _replaceProjectInCaches(refreshed);
        if (!silent) update();
        return refreshed;
      }
      if (!silent) {
        final message = result.message.isNotEmpty
            ? result.message
            : 'Failed to update project status.';
        Get.snackbar('Project', message);
      }
    } catch (e, stack) {
      debugPrint('Failed to update project status: $e\n$stack');
      if (!silent) {
        Get.snackbar(
          'Project',
          'Failed to update project status. Please try again.',
        );
      }
    }
    _project.value = updated;
    _replaceProjectInCaches(updated);
    if (!silent) update();
    return updated;
  }

  void _replaceProjectInCaches(Project updated) {
    final indexAll = _allProjects.indexWhere((p) => p.id == updated.id);
    if (indexAll >= 0) {
      _allProjects[indexAll] = updated;
      _allProjects.refresh();
    }
    final indexFiltered = _filteredProjects.indexWhere((p) => p.id == updated.id);
    if (indexFiltered >= 0) {
      _filteredProjects[indexFiltered] = updated;
      _filteredProjects.refresh();
    }
  }

  Future<PanicleInferenceResult?> _runCancelableInference(
    PanicleAiService analyzer,
    String imagePath,
  ) async {
    final inferenceFuture = analyzer.analyzeRemoteImage(imagePath);
    final cancelToken = _analysisCancelToken;
    if (cancelToken == null) {
      return inferenceFuture;
    }
    final winner = await Future.any<PanicleInferenceResult?>(
      <Future<PanicleInferenceResult?>>[
        inferenceFuture,
        cancelToken.future.then((_) => null),
      ],
    );
    if (winner == null) {
      _discardFuture(inferenceFuture);
      return null;
    }
    return winner;
  }

  void _discardFuture<T>(Future<T> future) {
    unawaited(future.then((_) {}, onError: (_, __) {}));
  }

  // Load all projects from Supabase
  Future<void> loadProjects() async {
    _isLoading.value = true;
    _hasError.value = false;
    _errorMessage.value = '';
    update();

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
      update();
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
    if (kDebugMode) {
      print('Total filtered projects: ${_filteredProjects.length}');
    }
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
      if (kDebugMode) {
        print('Error searching projects: $e');
      }
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
      if (result.success) {
        _pushProjectNotification(
          title: 'Project created',
          message: '${enrichedProject.projectName} has been created successfully.',
        );
      }
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
      if (result.success) {
        _pushProjectNotification(
          title: 'Project updated',
          message: '${project.projectName} was updated.',
        );
      }
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
          _pushProjectNotification(
            title: 'Project deleted',
            message: 'A project was removed from your workspace.',
          );
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

  Future<ProjectResult> renameHill({
    required String projectId,
    required String hillId,
    required String hillLabel,
    String? notes,
  }) async {
    _isLoading.value = true;
    try {
      final result = await ProjectSupabaseService.updateHill(
        projectId: projectId,
        hillId: hillId,
        hillLabel: hillLabel,
        notes: notes,
      );
      await loadProjects();
      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<ProjectResult> deleteHill({
    required String projectId,
    required String hillId,
  }) async {
    _isLoading.value = true;
    try {
      final result = await ProjectSupabaseService.deleteHill(
        projectId: projectId,
        hillId: hillId,
      );
      await loadProjects();
      return result;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<ProjectResult> deleteProjectImage({
    required String projectId,
    required ImagePanicle image,
  }) async {
    _isLoading.value = true;
    try {
      final isLocal = image.id.startsWith('local_') ||
          image.imagePath.startsWith('/') ||
          image.imagePath.startsWith('file://');

      if (isLocal) {
        await _localStorage.deleteImage(
          projectId: projectId,
          image: image,
        );
      } else {
        await ProjectSupabaseService.deleteImage(
          imageId: image.id,
          imagePath: image.imagePath,
        );
      }

      await _analysisResultService.deleteResultsForImage(
        projectId: projectId,
        imageId: image.id,
      );

      selectedImages.clear();
      final updatedProject = await getProjectById(projectId);
      await loadProjects();
      return ProjectResult(
        success: true,
        project: updatedProject,
        message: 'Image deleted successfully.',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting image: $e');
      }
      return ProjectResult(
        success: false,
        message: 'Failed to delete image. Please try again.',
      );
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

  void _pushProjectNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.project,
  }) {
    final userId = SupabaseAuthService.currentUser?.id;
    if (userId == null) return;
    unawaited(NotificationSupabaseService.createNotification(
      userId: userId,
      type: type,
      title: title,
      message: message,
    ));
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

class _AnalysisCanceledException implements Exception {
  const _AnalysisCanceledException();
}
