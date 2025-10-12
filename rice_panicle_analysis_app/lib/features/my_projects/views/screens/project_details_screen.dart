import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/widgets/file_grid.dart';
import 'package:rice_panicle_analysis_app/features/widgets/info_project_bottom_sheet.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late Project _project; // Sao chép project để có thể thay đổi

  @override
  void initState() {
    super.initState();
    _project = widget.project; // Khởi tạo với project ban đầu
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          title: Text(
            'Details',
            style: AppTextStyle.withColor(
              AppTextStyle.h3,
              isDark ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.share,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => _shareProject(
                context,
                _project.id,
                _project.projectName,
                _project.description,
              ),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSummarySection(context)),
            SliverToBoxAdapter(
              child: TabBar(
                tabs: const [
                  Tab(text: 'Images'),
                  Tab(text: 'Results'),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: isDark
                    ? Colors.grey[400]!
                    : Colors.grey[600]!,
                indicatorColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                children: [_buildImagesTab(context), _buildResultsTab(context)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        InfoProjectBottomSheet.show(
          context,
          _project,
        ); // Hiển thị bottom sheet khi nhấn
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[200],
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _project.projectName,
                  style: AppTextStyle.withColor(
                    AppTextStyle.h2,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated: ${_project.createdAt.toString().split(' ')[0]}',
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodyMedium,
                    isDark ? Colors.grey[400]! : Colors.grey[600]!,
                  ),
                ),
              ],
            ),
            Chip(
              label: Text(
                '${_project.statusString[0].toUpperCase()}${_project.statusString.substring(1).toLowerCase()}',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  Colors.white,
                ),
              ),
              backgroundColor: _getStatusColor(_project.status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Expanded(
          child: FileGrid(
            files: _project.images,
            type: 'image',
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _takePhoto(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Take Photo',
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodyMedium,
                    Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ..._project.analyses.map(
            (analysis) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  analysis,
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodyLarge,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyLarge,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProject(
    BuildContext context,
    String projectNumber,
    String projectName,
    String description,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      print('RenderBox is null, sharing may not position correctly');
      return;
    }
    final String projectLink = 'https://yourapp.com/project/$projectNumber';
    final String subject = 'Project Details: $projectName';
    final String shareMessage =
        '$description\n\nView now at $projectLink\nProject Number: $projectNumber';

    try {
      await Share.share(
        shareMessage,
        subject: subject,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      );
      debugPrint('Thank you for sharing!');
    } catch (e) {
      print('Error sharing project: $e');
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          // Tạo một bản sao mới của Project với ảnh mới
          final updatedImages = List<String>.from(_project.images)
            ..add(photo.path);
          _project = _project.copyWith(images: updatedImages);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No photo was taken.')));
      }
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera permission denied. Please enable it in settings.',
          ),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Color _getStatusColor(ProjectStatus status) {
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
}

// Thêm phương thức copyWith vào Project
extension ProjectExtension on Project {
  Project copyWith({
    String? projectNumber,
    String? projectName,
    String? description,
    ProjectStatus? status,
    DateTime? createdAt,
    bool? isBookmark,
    List<String>? images,
    List<String>? analyses,
  }) {
    return Project(
      id: projectNumber ?? this.id,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isBookmark: isBookmark ?? this.isBookmark,
      images: images ?? this.images,
      analyses: analyses ?? this.analyses,
    );
  }
}
