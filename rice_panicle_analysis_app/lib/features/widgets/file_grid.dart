import 'package:flutter/material.dart';

class FileGrid extends StatelessWidget {
  final List<String> files;
  final String type;

  const FileGrid({super.key, required this.files, required this.type});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Tỷ lệ 4:3 cho mỗi ô
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return GestureDetector(
          onTap: () {
            // Thêm logic khi nhấn vào (ví dụ: xem chi tiết ảnh hoặc file)
            print('Tapped on $type: $file');
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
            child: type == 'image'
                ? Image.asset(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          'Error loading image',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      file.split('/').last, // Hiển thị tên file
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
