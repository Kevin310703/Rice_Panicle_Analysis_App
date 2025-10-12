import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/services/project_firestore_service.dart';

class ProjectController extends GetxController {
  final RxList<Project> _allProjects = <Project>[].obs;
  final RxList<Project> _filteredProjects = <Project>[].obs;
  final Rx<Project?> _project = Rx<Project?>(null);
  final Rx<Map<String, dynamic>?> _projectDocument = Rx<Map<String, dynamic>?>(
    null,
  );

  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _selectedCategory = 'All'.obs;
  final RxString _searchQuery = ''.obs;

  // Getters
  List<Project> get allProjects => _allProjects;
  List<Project> get filteredProjects => _filteredProjects;
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  String get selectedCategory => _selectedCategory.value;
  String get searchQuery => _searchQuery.value;

  String? get projectName => _project.value?.projectName;
  String? get projectDescription => _project.value?.description;
  Map<String, dynamic>? get userDocument => _projectDocument.value;

  @override
  void onInit() {
    super.onInit();
    _selectedCategory.value = 'All';
    loadProjects();
  }

  // Load all projects from Firestore
  Future<void> loadProjects() async {
    _isLoading.value = true;
    _hasError.value = false;

    try {
      final projects = await ProjectFirestoreService.getAllProjects();

      // Set projects from Firestore
      _allProjects.value = projects;
      _filteredProjects.value = projects;

      // Load other project lists
    } catch (e) {
      _hasError.value = false;
      _errorMessage.value = 'Failed to load projects. Please try again.';
      print('Error loading projects. $e');

      // Clear projects on error
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

  // Search project in Firestore
  Future<List<Project>> searchProjectsInFirestore(String searchTerm) async {
    try {
      return await ProjectFirestoreService.searchProjects(searchTerm);
    } catch (e) {
      print('Error searching projects: $e');
      return [];
    }
  }

  // Get project by ID
  Future<Project?> getProjectById(String projectId) async {
    try {
      return await ProjectFirestoreService.getProjectById(projectId);
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
  Future<void> createProject(Project project) async {
    _isLoading.value = true;
    try {
      await ProjectFirestoreService.createProject(project);
      await loadProjects(); // Refresh the project list
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = 'Failed to create project. Please try again.';
      print('Error creating project: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Delete a project
  Future<void> deleteProject(String projectId) async {
    _isLoading.value = true;
    try {
      await ProjectFirestoreService.deleteProject(projectId);
      await loadProjects(); // Refresh the project list
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = 'Failed to delete project. Please try again.';
      print('Error deleting project: $e');
    } finally {
      _isLoading.value = false;
    }
  }
}
