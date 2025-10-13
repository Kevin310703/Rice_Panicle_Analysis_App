import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/widgets/file_grid.dart';
import 'package:rice_panicle_analysis_app/features/widgets/info_project_bottom_sheet.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late Project _project; // Sao chép project để có thể thay đổi
  static const int _kMaxFileSizeMB = 10;
  static const Set<String> _kImageExt = {'jpg', 'jpeg', 'png'};
  static const Set<String> _kResultExt = {'xlsx', 'xls', 'csv', 'zip'};

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
          child: FileGrid(files: _project.images, type: 'image'),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _showImagePickerBottomSheet(context, isDark),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_a_photo, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Add Images',
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

  void _showImagePickerBottomSheet(BuildContext context, bool isDark) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Images',
              style: AppTextStyle.withColor(
                AppTextStyle.h3,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              context,
              'Take Photo',
              Icons.camera_alt_rounded,
              () {
                // Implement take photo functionality
                _takePhoto(context);
              },
              isDark,
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              context,
              'Choose from Gallery',
              Icons.photo_library_outlined,
              () {
                // Implement take photo functionality
                _pickImageFromGallery(context);
              },
              isDark,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTab(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FileGrid(files: _project.analyses, type: 'file'),
        ),
      ],
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
    if (kIsWeb) {
      if (html.window.navigator.mediaDevices == null) {
        _showSnack('Camera not supported on this browser.');
        return;
      }
    } else {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showSnack('Camera permission denied. Please enable it in settings.');
        if (status.isPermanentlyDenied)
          await _openAppSettingsWithMessage(context);
        return;
      }
    }

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      // vẫn kiểm tra ext & size
      final ext = _extOf(photo.name);
      if (!_kImageExt.contains(ext)) {
        _showSnack('Unsupported image type .$ext (allowed: jpg, jpeg, png).');
        return;
      }
      if (!await _isWithinSize(photo)) {
        _showSnack('Image too large (> $_kMaxFileSizeMB MB).');
        return;
      }
      await _uploadManyAndRefresh([photo], 'image', _kImageExt);
      Get.back();
    } else {
      _showSnack('No photo was taken.');
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    if (!kIsWeb) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        _showSnack('Photos permission denied. Please enable it in settings.');
        if (status.isPermanentlyDenied)
          await _openAppSettingsWithMessage(context);
        return;
      }
    }

    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(); // multi

    if (images.isNotEmpty) {
      await _uploadManyAndRefresh(images, 'image', _kImageExt);
      Get.back();
    } else {
      _showSnack('No image was selected.');
    }
  }

  Future<void> _uploadImageAndRefresh(XFile image, String type) async {
    final projectController = ProjectController();
    final result = await projectController.uploadFileForProject(
      image,
      type,
      _project.id,
    );

    if (!mounted) return;

    if (result.success) {
      // Nếu service trả về Project đã update, lấy luôn
      if (result.project != null) {
        setState(() {
          _project = result.project!;
        });
      } else {
        // fallback: tự thêm URL nếu service chỉ trả URL (ít gặp)
        // nhưng theo code ở service bạn đã update Firestore và refetch project rồi.
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload image successfully!')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _pickAnalysesFromGalleryMulti(BuildContext context) async {
    if (!kIsWeb) {
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        _showSnack('Photos permission denied. Please enable it in settings.');
        if (status.isPermanentlyDenied)
          await _openAppSettingsWithMessage(context);
        return;
      }
    }

    final picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      await _uploadManyAndRefresh(files, 'analyses', _kResultExt);
    } else {
      _showSnack('No file was selected.');
    }
  }

  Future<void> _uploadManyAndRefresh(
    List<XFile> files,
    String type, // 'image' hoặc 'file'
    Set<String> allowedExtensions, // _kImageExt hoặc _kResultExt
  ) async {
    if (files.isEmpty) {
      _showSnack('No file selected.');
      return;
    }

    final rejectedExt = <String>[];
    final oversized = <String>[];
    final accepted = <XFile>[];

    for (final f in files) {
      final ext = _extOf(f.name);
      if (!allowedExtensions.contains(ext)) {
        rejectedExt.add('${f.name} (.$ext)');
        continue;
      }
      if (!await _isWithinSize(f)) {
        oversized.add('${f.name} (> $_kMaxFileSizeMB MB)');
        continue;
      }
      accepted.add(f);
    }

    if (rejectedExt.isNotEmpty) {
      _showSnack('Unsupported: ${rejectedExt.join(', ')}');
    }
    if (oversized.isNotEmpty) {
      _showSnack('Skipped oversized: ${oversized.join(', ')}');
    }
    if (accepted.isEmpty) return;

    final projectController = ProjectController();
    int ok = 0, fail = 0;

    for (final f in accepted) {
      final res = await projectController.uploadFileForProject(
        f,
        type, // 'image' => mảng images; 'file' => mảng analyses (tuỳ bạn map ở service)
        _project.id, // projectId
      );

      if (res.success) {
        ok++;
        if (res.project != null) {
          setState(() => _project = res.project!);
        }
      } else {
        fail++;
      }
    }

    if (ok > 0) _showSnack('Uploaded $ok file(s) successfully.');
    if (fail > 0) _showSnack('Failed to upload $fail file(s).');
  }

  Future<void> _openAppSettingsWithMessage(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Permission permanently denied. Please enable it in app settings.',
        ),
      ),
    );
    await openAppSettings();
  }

  String _extOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  Future<bool> _isWithinSize(XFile f) async {
    final bytes = await f.length();
    return bytes <= _kMaxFileSizeMB * 1024 * 1024;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
