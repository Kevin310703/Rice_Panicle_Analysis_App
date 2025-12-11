import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/auth_controller.dart';
import 'package:rice_panicle_analysis_app/controllers/navigation_controller.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
import 'package:rice_panicle_analysis_app/controllers/theme_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/screens/create_project_screen.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/screens/project_details_screen.dart';
import 'package:rice_panicle_analysis_app/features/notifications/views/notifications_screen.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _relativeTimeTimer;

  @override
  void initState() {
    super.initState();
    _relativeTimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _relativeTimeTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          final controller = Get.find<ProjectController>();
          await controller.refreshProjects();
        },
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            _buildSliverAppBar(context, isDark),

            // Search Bar
            SliverToBoxAdapter(child: _buildSearchBar(context, isDark)),

            // Recent Projects Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Projects',
                      style: AppTextStyle.withColor(
                        AppTextStyle.h3,
                        Theme.of(context).textTheme.bodyLarge!.color!,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final navController =
                            Get.find<NavigationController>();
                        navController.changeIndex(1);
                      },
                      child: Text(
                        'View All',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodyMedium,
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Projects List
            _buildRecentProjects(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A), Color(0xFF81C784)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Phần greeting
              GetX<AuthController>(
                builder: (authController) {
                  final hour = DateTime.now().hour;
                  String greeting = 'Good morning,';
                  if (hour >= 12 && hour < 17) {
                    greeting = 'Good afternoon,';
                  } else if (hour >= 17) {
                    greeting = 'Good evening,';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // Giới hạn chiều cao của Column
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).cardColor,
                            child: ClipOval(
                              child: Image(
                                image:
                                    authController.userProfileImageUrl !=
                                            null &&
                                        authController.userProfileImageUrl!
                                            .startsWith('http')
                                    ? NetworkImage(
                                        authController.userProfileImageUrl!,
                                      )
                                    : AssetImage(
                                            authController
                                                    .userProfileImageUrl ??
                                                'assets/images/avatar.png',
                                          )
                                          as ImageProvider,
                                fit: BoxFit.contain,
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: AppTextStyle.withColor(
                                  AppTextStyle.bodyMedium,
                                  Colors.white,
                                ),
                              ),
                              // const SizedBox(height: 1),
                              Text(
                                authController.userName ?? 'User',
                                style: AppTextStyle.withColor(
                                  AppTextStyle.h3,
                                  Theme.of(context).textTheme.bodyLarge!.color!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              // Phần icon buttons
              Row(
                children: [
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
                        Icons.notifications_outlined,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    onPressed: () => Get.to(() => NotificationsScreen()),
                  ),
                  GetBuilder<ThemeController>(
                    builder: (controller) => IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[200]!,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      onPressed: () => controller.toggleTheme(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
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
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
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
                      setState(() {
                        _searchQuery = '';
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

  Widget _buildRecentProjects(BuildContext context, bool isDark) {
    return GetBuilder<ProjectController>(
      builder: (projectController) {
        if (projectController.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (projectController.hasError) {
          return SliverFillRemaining(
            child: _buildErrorState(context, projectController, isDark),
          );
        }

        var projects = projectController.allProjects;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          projects = projects.where((project) {
            return project.projectName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                project.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
        }

        // Take only recent 5 projects
        final recentProjects = projects.take(5).toList();

        if (recentProjects.isEmpty) {
          final emptyWidget = _searchQuery.trim().isNotEmpty
              ? _buildSearchEmptyState(context, isDark)
              : _buildEmptyState(context, isDark);
          return SliverFillRemaining(child: emptyWidget);
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return _buildProjectCard(context, recentProjects[index], isDark);
          }, childCount: recentProjects.length),
        );
      },
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.4),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.projectName,
                      style: AppTextStyle.withColor(
                        AppTextStyle.h3,
                        Theme.of(context).textTheme.bodyLarge!.color!,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 8),
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
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(project.createdAt),
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodySmall,
                      isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    ),
                  ),
                  const Spacer(),
                  _buildInfoChip(
                    context,
                    Icons.image_outlined,
                    '${project.images.length}',
                    isDark,
                  ),
                  // const SizedBox(width: 8),
                  // _buildInfoChip(
                  //   context,
                  //   Icons.analytics_outlined,
                  //   '${project.analyses.length}',
                  //   isDark,
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? Colors.grey[400]! : Colors.grey[600]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
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
                Icons.folder_off_outlined,
                size: 80,
                color: Theme.of(context).primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Projects Yet',
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first project to start analyzing rice panicles',
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openCreateProject(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Create Project',
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

  Widget _buildSearchEmptyState(BuildContext context, bool isDark) {
    final query = _searchQuery.trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              query.isEmpty
                  ? 'No matching projects'
                  : 'No results for "$query"',
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                Theme.of(context).textTheme.bodyLarge!.color!,
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
              'Oops! Something went wrong',
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';

    // Normalize to UTC to avoid negative differences with Supabase timestamps.
    final createdUtc = date.toUtc();
    final nowUtc = DateTime.now().toUtc();
    Duration difference = nowUtc.difference(createdUtc);
    if (difference.isNegative) difference = Duration.zero;

    if (difference.inDays == 0) {
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final localDate = createdUtc.toLocal();
      return '${localDate.day}/${localDate.month}/${localDate.year}';
    }
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

Future<void> _openCreateProject() async {
  final result = await Get.to(() => const CreateProjectScreen());
  if (result == true) {
    final projectController = Get.find<ProjectController>();
    await projectController.loadProjects();
  }
}
