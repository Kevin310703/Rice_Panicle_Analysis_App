import 'package:flutter/material.dart';

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
            DataColumn(label: Text("Tên thư mục")),
            DataColumn(label: Text("Số ảnh")),
            DataColumn(label: Text("Đã phân tích")),
            DataColumn(label: Text("Tổng số hạt")),
            DataColumn(label: Text("TB/bông")),
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
  final double analyzedRate; // 0..1 (nếu muốn tô thêm lớp phân tích)
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
