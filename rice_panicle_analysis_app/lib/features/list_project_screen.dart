import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/screens/create_project_screen.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/screens/project_details_screen.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class ListProjectScreen extends StatefulWidget {
  const ListProjectScreen({super.key});

  @override
  State<ListProjectScreen> createState() => _ListProjectScreenState();
}

class _ListProjectScreenState extends State<ListProjectScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isGridView = false;
  final List<Project> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _openCreateProject() async {
    final result = await Get.to(() => const CreateProjectScreen());
    if (result == true) {
      final controller = Get.find<ProjectController>();
      await controller.loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: true,
              pinned: true,
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              flexibleSpace: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xFF66BB6A),
                          Color(0xFF81C784),
                        ],
                      ),
                    ),
                  ),
                  const IgnorePointer(
                    child: CustomPaint(painter: _CirclePatternPainter()),
                  ),
                  FlexibleSpaceBar(
                    background: Container(
                      padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'My Projects',
                              style: AppTextStyle.withColor(
                                AppTextStyle.h2,
                                Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GetBuilder<ProjectController>(
                              builder: (controller) {
                                final count = controller.allProjects.length;
                                final text = count == 1
                                    ? 'project'
                                    : 'projects';

                                return Text(
                                  '$count $text',
                                  style: AppTextStyle.withColor(
                                    AppTextStyle.h3,
                                    isDark
                                        ? Colors.grey[400]!
                                        : const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[800]!.withOpacity(0.5)
                          : Colors.grey[200]!,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: isDark ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[800]!.withOpacity(0.5)
                          : Colors.grey[200]!,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: isDark ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                  onPressed: () => _showFilterBottomSheet(context, isDark),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Search Bar
            SliverToBoxAdapter(child: _buildSearchBar(context, isDark)),

            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController!,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: isDark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelStyle: AppTextStyle.bodyMedium,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController!,
          children: [
            _buildProjectsList(context, null, isDark),
            _buildProjectsList(context, ProjectStatus.active, isDark),
            _buildProjectsList(context, ProjectStatus.completed, isDark),
            _buildProjectsList(context, ProjectStatus.cancelled, isDark),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateProject,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Project',
          style: AppTextStyle.withColor(
            AppTextStyle.buttonMedium,
            Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _handleSearchChanged,
          onSubmitted: _handleSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search projects...',
            hintStyle: AppTextStyle.withColor(
              AppTextStyle.bodyMedium,
              isDark ? Colors.grey[400]! : Colors.grey[600]!,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).primaryColor,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _searchDebounce?.cancel();
                      setState(() {
                        _searchQuery = '';
                        _searchResults.clear();
                        _isSearching = false;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsList(
    BuildContext context,
    ProjectStatus? status,
    bool isDark,
  ) {
    return GetBuilder<ProjectController>(
      builder: (projectController) {
        if (projectController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (projectController.hasError) {
          return _buildErrorState(context, projectController, isDark);
        }

        if (_searchQuery.trim().isNotEmpty && _isSearching) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasQuery = _searchQuery.trim().isNotEmpty;
        List<Project> baseProjects = hasQuery
            ? List<Project>.from(_searchResults)
            : projectController.allProjects;

        // Filter by status
        if (status != null) {
          baseProjects = baseProjects.where((p) => p.status == status).toList();
        }

        final projects = baseProjects;

        if (projects.isEmpty) {
          return _buildEmptyState(context, status, isDark);
        }

        return RefreshIndicator(
          onRefresh: () => projectController.refreshProjects(),
          child: _isGridView
              ? _buildGridView(projects, isDark)
              : _buildListView(projects, isDark),
        );
      },
    );
  }

  Widget _buildListView(List<Project> projects, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return _buildProjectCard(context, projects[index], isDark);
      },
    );
  }

  Widget _buildGridView(List<Project> projects, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return _buildProjectGridCard(context, projects[index], isDark);
      },
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Get.to(() => ProjectDetailsScreen(project: project)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: _getStatusColor(project.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.projectName,
                          style: AppTextStyle.withColor(
                            AppTextStyle.h3,
                            Theme.of(context).textTheme.bodyLarge!.color!,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(project.createdAt),
                              style: AppTextStyle.withColor(
                                AppTextStyle.bodySmall,
                                isDark ? Colors.grey[400]! : Colors.grey[600]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(project.status).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(project.status),
                          color: _getStatusColor(project.status),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.statusString[0].toUpperCase()}${project.statusString.substring(1)}',
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            _getStatusColor(project.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                project.description,
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    Icons.image_outlined,
                    '${project.images.length} images',
                    Colors.blue,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    Icons.analytics_outlined,
                    '${project.analyses.length} analyses',
                    Colors.green,
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectGridCard(
    BuildContext context,
    Project project,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => Get.to(() => ProjectDetailsScreen(project: project)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getStatusColor(project.status).withOpacity(0.3),
                    _getStatusColor(project.status).withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.folder,
                  size: 48,
                  color: _getStatusColor(project.status),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.projectName,
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodyMedium,
                              Theme.of(context).textTheme.bodyLarge!.color!,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(project.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${project.statusString[0].toUpperCase()}${project.statusString.substring(1)}',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall,
                          _getStatusColor(project.status),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${project.images.length}',
                              style: AppTextStyle.withColor(
                                AppTextStyle.bodySmall,
                                isDark ? Colors.grey[400]! : Colors.grey[600]!,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${project.analyses.length}',
                              style: AppTextStyle.withColor(
                                AppTextStyle.bodySmall,
                                isDark ? Colors.grey[400]! : Colors.grey[600]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyle.withColor(AppTextStyle.bodySmall, color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ProjectStatus? status,
    bool isDark,
  ) {
    String message = 'No projects found';
    if (status != null) {
      message = 'No ${status.name} projects';
    }
    if (_searchQuery.isNotEmpty) {
      message = 'No projects match your search';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off
                    : Icons.folder_off_outlined,
                size: 80,
                color: Theme.of(context).primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTextStyle.withColor(
                AppTextStyle.h3,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try different keywords'
                  : 'Create a new project to get started',
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ProjectController controller,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTextStyle.withColor(
                AppTextStyle.h3,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => controller.refreshProjects(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Try Again',
                style: AppTextStyle.withColor(
                  AppTextStyle.buttonMedium,
                  Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, bool isDark) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Projects',
                  style: AppTextStyle.withColor(
                    AppTextStyle.h3,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Sort By',
              style: AppTextStyle.withColor(
                AppTextStyle.bodyLarge,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    'Newest',
                    'Oldest',
                    'Name (A-Z)',
                    'Name (Z-A)',
                    'Most Images',
                  ].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        Get.back();
                      },
                      backgroundColor: Theme.of(context).cardColor,
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.2),
                      labelStyle: AppTextStyle.withColor(
                        AppTextStyle.bodyMedium,
                        isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodyLarge!.color!,
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply',
                  style: AppTextStyle.withColor(
                    AppTextStyle.buttonMedium,
                    Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearchChanged(String value) {
    final query = value.trim();
    setState(() {
      _searchQuery = value;
      if (query.isNotEmpty) {
        _searchResults.clear();
      }
    });
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
    setState(() {
      _isSearching = true;
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final controller = Get.find<ProjectController>();
      final results = await controller.searchProjects(query);
      if (!mounted || query != _searchQuery.trim()) return;
      setState(() {
        _searchResults
          ..clear()
          ..addAll(results);
      });
    } catch (_) {
      if (!mounted || query != _searchQuery.trim()) return;
      setState(() => _searchResults.clear());
    } finally {
      if (mounted && query == _searchQuery.trim()) {
        setState(() => _isSearching = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return Colors.green;
      case ProjectStatus.active:
        return Colors.blue;
      case ProjectStatus.inProgress:
        return Colors.orange;
      case ProjectStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return Icons.check_circle;
      case ProjectStatus.active:
        return Icons.play_circle_filled;
      case ProjectStatus.inProgress:
        return Icons.pending;
      case ProjectStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}

class _CirclePatternPainter extends CustomPainter {
  const _CirclePatternPainter({this.opacity = 0.12});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final ring = Paint()
      ..color = Colors.white.withOpacity(opacity + 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());

    void circle(double x, double y, double r) {
      final c = Offset(size.width * x, size.height * y);
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r + 8, ring);
    }

    circle(0.18, 0.30, 60);
    circle(0.82, 0.58, 80);
    circle(0.48, 0.80, 40);
    circle(0.90, 0.22, 50);
    circle(0.10, 0.85, 30);
    circle(0.34, 0.60, 24);

    final dot = Paint()
      ..color = Colors.white.withOpacity(opacity + 0.05)
      ..style = PaintingStyle.fill;
    for (double t = 0; t <= 1.0; t += 0.08) {
      final p = Offset(size.width * t, size.height * (0.18 + 0.5 * t));
      canvas.drawCircle(p, 2.2, dot);
    }

    canvas.restore();

    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, 0.2),
        radius: 1.2,
        colors: [
          Colors.white.withOpacity(0.00),
          Colors.white.withOpacity(0.06),
        ],
        stops: const [0.75, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
