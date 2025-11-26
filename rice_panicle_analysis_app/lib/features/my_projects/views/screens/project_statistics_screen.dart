import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/image_panicle.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';

class ProjectStatisticsScreen extends StatelessWidget {
  final Project project;
  final String seasonTitle;
  const ProjectStatisticsScreen({
    super.key,
    required this.project,
    this.seasonTitle = 'Dry Season 2024',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = _StatisticsData.fromProject(project);
    final regions = stats.regionRows;
    final maxSeeds = stats.maxSeeds;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF7F8FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            _buildAppBar(context, isDark),

            // Quick Stats Cards
            SliverToBoxAdapter(
              child: _buildQuickStats(
                isDark,
                stats.totalSeeds,
                stats.totalRegions,
                stats.avgSeeds,
                stats.analyzedRegions,
              ),
            ),

            // Chart: Tổng số hạt
            SliverToBoxAdapter(
              child: _buildSeedsChart(isDark, regions, maxSeeds),
            ),

            // Chart: Tỉ lệ phân tích
            SliverToBoxAdapter(
              child: _buildAnalysisProgressChart(isDark, regions),
            ),

            // Bảng chi tiết
            SliverToBoxAdapter(
              child: _buildDetailTable(isDark, stats.regionDetails),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Row(
          children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Project Statistics",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            seasonTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildQuickStats(
    bool isDark,
    int totalSeeds,
    int totalRegions,
    int avgSeeds,
    int analyzedCount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Overview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  isDark,
                  icon: Icons.grain_rounded,
                  label: "Total Grains",
                  value: totalSeeds.toString(),
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  isDark,
                  icon: Icons.folder_rounded,
                  label: totalRegions == 1 ? "Hill" : "Hills",
                  value: totalRegions.toString(),
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  isDark,
                  icon: Icons.show_chart_rounded,
                  label: "Avg per Hill",
                  value: avgSeeds.toString(),
                  color: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  isDark,
                  icon: Icons.task_alt_rounded,
                  label: "Analyzed",
                  value: "$analyzedCount/$totalRegions",
                  color: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedsChart(bool isDark, List<_RegionRow> regions, int maxSeeds) {
    return _SectionCard(
      title: "Grains per Hill",
      icon: Icons.bar_chart_rounded,
      iconColor: const Color(0xFF4CAF50),
      child: Column(
        children: regions.asMap().entries.map((entry) {
          final index = entry.key;
          final r = entry.value;
          final p = maxSeeds == 0 ? 0.0 : r.totalSeeds / maxSeeds;

          // MÃ u gradient cho má»—i bar
          final colors = [
            const Color(0xFF4CAF50),
            const Color(0xFF2196F3),
            const Color(0xFFFF9800),
            const Color(0xFF9C27B0),
            const Color(0xFFF44336),
          ];
          final barColor = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: barColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          r.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${r.totalSeeds} grains",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: barColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    // Progress bar vá»›i gradient
                    FractionallySizedBox(
                      widthFactor: p.clamp(0.0, 1.0),
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor, barColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Percentage text
                Text(
                  "${(p * 100).toStringAsFixed(0)}% of the hill with the most grains",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnalysisProgressChart(bool isDark, List<_RegionRow> regions) {
    return _SectionCard(
      title: "Analysis Progress",
      icon: Icons.pie_chart_rounded,
      iconColor: const Color(0xFF2196F3),
      child: Column(
        children: regions.map((r) {
          final percentage = (r.analyzedRate * 100).toInt();
          final color = r.analyzedRate >= 0.8
              ? const Color(0xFF4CAF50)
              : r.analyzedRate >= 0.5
              ? const Color(0xFFFF9800)
              : const Color(0xFFF44336);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                // Region name
                SizedBox(
                  width: 80,
                  child: Text(
                    r.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Progress bar
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: r.analyzedRate.clamp(0.0, 1.0),
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Percentage badge
                Container(
                  width: 50,
                  alignment: Alignment.centerRight,
                  child: Text(
                    "$percentage%",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailTable(bool isDark, List<_RegionDetail> rows) {
    return _SectionCard(
      title: "Detailed breakdown",
      icon: Icons.table_chart_rounded,
      iconColor: const Color(0xFF9C27B0),
      child: rows.isEmpty
          ? const _EmptyDataMessage(message: 'No detailed data available.')
          : _EnhancedRegionDataTable(isDark: isDark, rows: rows),
    );
  }
}

class _EnhancedRegionDataTable extends StatelessWidget {
  final bool isDark;
  final List<_RegionDetail> rows;

  const _EnhancedRegionDataTable({required this.isDark, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 44,
            headingRowColor: MaterialStateProperty.all(
              isDark
                  ? Colors.grey[800]?.withOpacity(0.5)
                  : const Color(0xFFF8F9FA),
            ),
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: [
              DataColumn(
                label: _TableHeader(
                  icon: Icons.folder_rounded,
                  text: "Hill",
                  isDark: isDark,
                ),
              ),
              DataColumn(
                label: _TableHeader(
                  icon: Icons.photo_library_rounded,
                  text: "Photos",
                  isDark: isDark,
                ),
              ),
              DataColumn(
                label: _TableHeader(
                  icon: Icons.check_circle_rounded,
                  text: "Processed",
                  isDark: isDark,
                ),
              ),
              DataColumn(
                label: _TableHeader(
                  icon: Icons.grain_rounded,
                  text: "Total Grains",
                  isDark: isDark,
                ),
              ),
              DataColumn(
                label: _TableHeader(
                  icon: Icons.show_chart_rounded,
                  text: "Avg per Panicle",
                  isDark: isDark,
                ),
              ),
            ],
            rows: rows.asMap().entries.map((entry) {
              final index = entry.key;
              final r = entry.value;
              final bgColor = index.isEven
                  ? (isDark ? Colors.grey[850] : Colors.white)
                  : (isDark
                        ? Colors.grey[850]?.withOpacity(0.5)
                        : Colors.grey[50]);

              return DataRow(
                color: MaterialStateProperty.all(bgColor),
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          r.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(_ValueChip(r.numImages.toString(), isDark: isDark)),
                  DataCell(_ValueChip(r.analyzed.toString(), isDark: isDark)),
                  DataCell(
                    _ValueChip(
                      r.totalSeeds.toString(),
                      isDark: isDark,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  DataCell(
                    _ValueChip(
                      r.avgPerPanicle.toString(),
                      isDark: isDark,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _TableHeader({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String value;
  final bool isDark;
  final Color? color;

  const _ValueChip(this.value, {required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? (isDark ? Colors.grey[700]! : Colors.grey[200]!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;

  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (iconColor ?? const Color(0xFF4CAF50)).withOpacity(
                        0.15,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyDataMessage extends StatelessWidget {
  final String message;
  const _EmptyDataMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsData {
  final int totalSeeds;
  final int totalRegions;
  final int avgSeeds;
  final int analyzedRegions;
  final List<_RegionRow> regionRows;
  final List<_RegionDetail> regionDetails;
  final int maxSeeds;

  const _StatisticsData({
    required this.totalSeeds,
    required this.totalRegions,
    required this.avgSeeds,
    required this.analyzedRegions,
    required this.regionRows,
    required this.regionDetails,
    required this.maxSeeds,
  });

  factory _StatisticsData.fromProject(Project project) {
    final hills = project.hills;
    final images = project.panicleImages;
    final results = project.aiResults;

    final hillNames = <String, String>{};
    for (var i = 0; i < hills.length; i++) {
      final hill = hills[i];
      final fallbackName = 'Hill ${i + 1}';
      hillNames[hill.id] = hill.hillLabel.isNotEmpty
          ? hill.hillLabel
          : fallbackName;
    }

    final groupedImages = <String, List<ImagePanicle>>{};
    for (final hill in hills) {
      groupedImages[hill.id] = [];
    }
    for (final image in images) {
      final key = image.hillId.isEmpty ? '__unassigned__' : image.hillId;
      groupedImages.putIfAbsent(key, () => []);
      groupedImages[key]!.add(image);
    }

    final resultsByImage = <String, List<AnalysisResult>>{};
    for (final res in results) {
      resultsByImage.putIfAbsent(res.imageId, () => []).add(res);
    }

    final regionRows = <_RegionRow>[];
    final regionDetails = <_RegionDetail>[];
    int totalSeeds = 0;
    int totalRegions = 0;
    int analyzedRegions = 0;
    int maxSeeds = 0;

    void addRegion(String key, String label, List<ImagePanicle> imgs) {
      final analyzedImages = <String>{};
      int seeds = 0;
      for (final image in imgs) {
        final resList = resultsByImage[image.id];
        if (resList == null || resList.isEmpty) continue;
        analyzedImages.add(image.id);
        for (final res in resList) {
          final spikes = res.totalSpikelets != 0
              ? res.totalSpikelets
              : (res.grains);
          seeds += spikes;
        }
      }

      final analyzedRate = imgs.isEmpty
          ? 0.0
          : analyzedImages.length / imgs.length;
      regionRows.add(
        _RegionRow(name: label, totalSeeds: seeds, analyzedRate: analyzedRate),
      );
      regionDetails.add(
        _RegionDetail(
          name: label,
          numImages: imgs.length,
          analyzed: analyzedImages.length,
          totalSeeds: seeds,
          avgPerPanicle: analyzedImages.isEmpty
              ? 0
              : (seeds / analyzedImages.length).round(),
        ),
      );
      totalSeeds += seeds;
      totalRegions += 1;
      if (analyzedRate >= 0.5) analyzedRegions += 1;
      if (seeds > maxSeeds) maxSeeds = seeds;
    }

    if (groupedImages.isEmpty) {
      addRegion('__all__', 'Project overview', const <ImagePanicle>[]);
    } else {
      groupedImages.forEach((key, imgs) {
        final label =
            hillNames[key] ??
            (key == '__unassigned__'
                ? 'Unassigned hill'
                : (key.isEmpty ? 'Unassigned hill' : 'Hill $key'));
        addRegion(key, label, imgs);
      });
    }

    final avgSeeds = totalRegions == 0
        ? 0
        : (totalSeeds / totalRegions).round();

    return _StatisticsData(
      totalSeeds: totalSeeds,
      totalRegions: totalRegions,
      avgSeeds: avgSeeds,
      analyzedRegions: analyzedRegions,
      regionRows: regionRows,
      regionDetails: regionDetails,
      maxSeeds: maxSeeds,
    );
  }
}

class _RegionDataTable extends StatelessWidget {
  final List<_RegionDetail> rows;
  const _RegionDataTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white : Colors.black87,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: isDark ? Colors.grey[900] : Colors.white,
        child: DataTable(
          headingRowColor: MaterialStateProperty.resolveWith(
            (states) => isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
          ),
          dataRowMinHeight: 40,
          dataRowMaxHeight: 44,
          columns: const [
            DataColumn(label: Text("Hill Name")),
            DataColumn(label: Text("Photos")),
            DataColumn(label: Text("Analyzed")),
            DataColumn(label: Text("Total Grains")),
            DataColumn(label: Text("Avg per Panicle")),
          ],
          rows: rows.map((r) {
            return DataRow(
              cells: [
                DataCell(Text(r.name, style: textStyle)),
                DataCell(Text("${r.numImages}", style: textStyle)),
                DataCell(Text("${r.analyzed}", style: textStyle)),
                DataCell(Text("${r.totalSeeds}", style: textStyle)),
                DataCell(Text("${r.avgPerPanicle}", style: textStyle)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RegionRow {
  final String name;
  final int totalSeeds;
  final double analyzedRate; // 0..1 (náº¿u muá»‘n tÃ´ thÃªm lá»›p phÃ¢n tÃ­ch)
  _RegionRow({
    required this.name,
    required this.totalSeeds,
    required this.analyzedRate,
  });
}

class _RegionDetail {
  final String name;
  final int numImages;
  final int analyzed;
  final int totalSeeds;
  final int avgPerPanicle;
  _RegionDetail({
    required this.name,
    required this.numImages,
    required this.analyzed,
    required this.totalSeeds,
    required this.avgPerPanicle,
  });
}
