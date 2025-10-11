import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Bookmark',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Summary section
          SliverToBoxAdapter(child: _buildSummarySection(context)),

          // Bookmark items
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final bookmarkProjects = Project.projects
                      .where((project) => project.isBookmark)
                      .toList();
                  if (index >= bookmarkProjects.length) return null;
                  return _buildBookmarkItem(context, bookmarkProjects[index]);
                },
                childCount: Project.projects
                    .where((project) => project.isBookmark)
                    .length, // Đặt itemCount dựa trên số lượng dự án bookmark
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookmarkCount = Project.projects
        .where((project) => project.isBookmark)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[150],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$bookmarkCount Items',
                style: AppTextStyle.withColor(
                  AppTextStyle.h2,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'in your bookmark',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Add New Project',
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkItem(BuildContext context, Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Định nghĩa màu sắc cho từng trạng thái
    Color getStatusColor(ProjectStatus status) {
      switch (status) {
        case ProjectStatus.completed:
          return Colors.green;
        case ProjectStatus.active:
          return Colors.blue;
        case ProjectStatus.cancelled:
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Group name project with Status chip
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.projectName,
                      style: AppTextStyle.withColor(
                        AppTextStyle.h3,
                        Theme.of(context).textTheme.bodyLarge!.color!,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    '${project.statusString[0].toUpperCase()}${project.statusString.substring(1).toLowerCase()}',
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodySmall,
                      Colors.white,
                    ),
                  ),
                  backgroundColor: getStatusColor(project.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project.createdAt.toString(),
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyLarge,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
                Text(
                  '${project.images.length} images',
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodySmall,
                    isDark ? Colors.grey[400]! : Colors.grey[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    ),
                    Text(
                      '${project.analyses.length} analyses',
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
    );
  }
}
