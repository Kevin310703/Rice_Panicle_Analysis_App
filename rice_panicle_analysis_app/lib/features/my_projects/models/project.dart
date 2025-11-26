import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_log.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/hill.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/image_panicle.dart';

enum ProjectStatus { active, inProgress, completed, cancelled }

class Project {
  final String id;
  final String projectName;
  final String genotypeName;
  final DateTime? plantingDate;
  final DateTime? harvestDate;
  final String? notes;
  final String description;
  final ProjectStatus status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isBookmark;
  final List<String> images;
  final List<String> analyses;
  final List<Hill> hills;
  final List<ImagePanicle> panicleImages;
  final List<AnalysisResult> aiResults;
  final List<AnalysisLog> analysisLogs;

  const Project({
    required this.id,
    required this.projectName,
    required this.genotypeName,
    required this.description,
    required this.status,
    this.createdBy,
    this.plantingDate,
    this.harvestDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.isBookmark = false,
    this.images = const [],
    this.analyses = const [],
    this.hills = const [],
    this.panicleImages = const [],
    this.aiResults = const [],
    this.analysisLogs = const [],
  });

  String get statusString => status.name;

  factory Project.fromSupabase(Map<String, dynamic> data) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    List<dynamic> _asList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value;
      return [value];
    }

    final hillsData = _asList(data['hills']);
    final parsedHills = hillsData
        .whereType<Map<String, dynamic>>()
        .map(Hill.fromMap)
        .toList();

    final List<ImagePanicle> parsedImages = [];
    final List<AnalysisResult> parsedResults = [];

    for (final hill in hillsData.whereType<Map<String, dynamic>>()) {
      final imageData = _asList(hill['image_panicles']);
      for (final img in imageData.whereType<Map<String, dynamic>>()) {
        final panicle = ImagePanicle.fromMap(img);
        parsedImages.add(panicle);

        final results = _asList(img['ai_results']);
        parsedResults.addAll(
          results.whereType<Map<String, dynamic>>().map(
                AnalysisResult.fromMap,
              ),
        );
      }
    }

    final logData = _asList(data['analysis_log']);
    final logs = logData
        .whereType<Map<String, dynamic>>()
        .map(AnalysisLog.fromMap)
        .toList();

    final images = parsedImages.map((e) => e.imagePath).toList();
    final analyses = logs
        .map((log) => log.filePath ?? '${log.analysisType} #${log.id}')
        .toList();

    return Project(
      id: data['id'].toString(),
      projectName: data['project_name'] as String? ?? '',
      genotypeName: data['genotype_name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: _statusFromString(data['status'] as String?),
      createdBy: data['created_by']?.toString(),
      plantingDate: _parseDate(data['planting_date']),
      harvestDate: _parseDate(data['harvest_date']),
      notes: data['notes'] as String?,
      createdAt: _parseDate(data['created_at']),
      updatedAt: _parseDate(data['updated_at']),
      isBookmark: data['flag'] as bool? ?? false,
      images: images,
      analyses: analyses,
      hills: parsedHills,
      panicleImages: parsedImages,
      aiResults: parsedResults,
      analysisLogs: logs,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'project_name': projectName,
      'genotype_name': genotypeName,
      'description': description,
      'status': status.name,
      'created_by': createdBy,
      'planting_date': plantingDate?.toIso8601String(),
      'harvest_date': harvestDate?.toIso8601String(),
      'notes': notes,
      'flag': isBookmark,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  static ProjectStatus _statusFromString(String? value) {
    if (value == null) return ProjectStatus.active;
    return ProjectStatus.values.firstWhere(
      (element) => element.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ProjectStatus.active,
    );
  }

  Project copyWith({
    String? projectName,
    String? genotypeName,
    String? description,
    ProjectStatus? status,
    String? createdBy,
    DateTime? plantingDate,
    DateTime? harvestDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBookmark,
    List<String>? images,
    List<String>? analyses,
    List<Hill>? hills,
    List<ImagePanicle>? panicleImages,
    List<AnalysisResult>? aiResults,
    List<AnalysisLog>? analysisLogs,
  }) {
    return Project(
      id: id,
      projectName: projectName ?? this.projectName,
      genotypeName: genotypeName ?? this.genotypeName,
      description: description ?? this.description,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBookmark: isBookmark ?? this.isBookmark,
      images: images ?? this.images,
      analyses: analyses ?? this.analyses,
      hills: hills ?? this.hills,
      panicleImages: panicleImages ?? this.panicleImages,
      aiResults: aiResults ?? this.aiResults,
      analysisLogs: analysisLogs ?? this.analysisLogs,
    );
  }

  static List<Project> projects = [
    Project(
      id: '123',
      projectName: 'Rice Variety A - Spring 2024',
      genotypeName: 'Variety A',
      description: 'A project about rice in Vietnam',
      status: ProjectStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isBookmark: true,
      images: ['image1.jpg', 'image2.jpg', 'image3.jpg', 'image4.jpg', 'image5.jpg'],
      analyses: ['analysis1.json', 'analysis2.json'],
    ),
    Project(
      id: '456',
      projectName: 'Hybrid Rice Study',
      genotypeName: 'Hybrid HX-12',
      description: 'A project about rice in China',
      status: ProjectStatus.active,
      createdAt: DateTime(2024, 03, 10),
      isBookmark: false,
      images: ['image6.jpg', 'image7.jpg', 'image8.jpg'],
      analyses: ['analysis3.json', 'analysis4.json', 'analysis5.json'],
    ),
    Project(
      id: '789',
      projectName: 'Drought Resistance Test',
      genotypeName: 'DRT-5',
      description: 'A project about rice in India',
      status: ProjectStatus.cancelled,
      createdAt: DateTime(2024, 03, 01),
      isBookmark: true,
      images: ['image9.jpg', 'image10.jpg', 'image11.jpg', 'image12.jpg'],
      analyses: ['analysis6.json'],
    ),
    Project(
      id: '101',
      projectName: 'Nitrogen Uptake Analysis',
      genotypeName: 'NUA-3',
      description: 'Monitoring nitrogen absorption efficiency using drone imagery.',
      status: ProjectStatus.inProgress,
      createdAt: DateTime(2024, 05, 22),
      isBookmark: false,
      images: ['image13.jpg', 'image14.jpg'],
      analyses: ['analysis7.json'],
    ),
  ];
}
