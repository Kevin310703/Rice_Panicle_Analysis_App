import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FileGrid extends StatelessWidget {
  final List<String> files;
  final String type;

  const FileGrid({super.key, required this.files, required this.type});

  String _normalizeDriveUrl(String url) {
    // match cả uc?export=view&id=... / uc?export=download&id=... / file/d/<id>/view...
    final idFromQuery = RegExp(r'[?&]id=([^&]+)').firstMatch(url)?.group(1);
    final idFromPath = RegExp(r'/d/([^/]+)').firstMatch(url)?.group(1);
    final fileId = idFromQuery ?? idFromPath;
    if (url.contains('drive.google.com') && fileId != null) {
      // thumbnail trả về image/jpeg: dùng tốt cho Image.network
      return 'https://drive.google.com/thumbnail?id=$fileId&sz=w1000';
    }
    return url; // không phải link Drive thì giữ nguyên
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${type == 'image' ? 'image' : 'file'} availabel',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

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
            print(_normalizeDriveUrl(file));
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
            child: type == 'image'
                // ? (kIsWeb
                //       ? _driveImageViaBackend(file)
                //       : Image.network(
                //           _normalizeDriveUrl(file),
                //           fit: BoxFit.cover,
                //           errorBuilder: (context, error, stackTrace) {
                //             return Center(
                //               child: Text(
                //                 'Error loading image $error',
                //                 style: TextStyle(
                //                   color: isDark ? Colors.white : Colors.black,
                //                 ),
                //               ),
                //             );
                //           },
                //           loadingBuilder: (context, child, loadingProgress) {
                //             if (loadingProgress == null) return child;
                //             return Center(
                //               child: CircularProgressIndicator(
                //                 value:
                //                     loadingProgress.expectedTotalBytes != null
                //                     ? loadingProgress.cumulativeBytesLoaded /
                //                           loadingProgress.expectedTotalBytes!
                //                     : null,
                //               ),
                //             );
                //           },
                //         ))
                ? Image.network(
                    _normalizeDriveUrl(file),
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
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;

                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
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

  // THÊM helper: tách fileId từ URL Drive
  String _extractDriveId(String url) {
    final q = RegExp(r'[?&]id=([^&]+)').firstMatch(url)?.group(1);
    final p = RegExp(r'/d/([^/]+)').firstMatch(url)?.group(1);
    return q ?? p ?? url;
  }

  // THÊM widget: tải ảnh qua backend (tránh CORS)
  Widget _driveImageViaBackend(String driveUrl) {
    final id = _extractDriveId(driveUrl);
    final uri = Uri.parse(
      'https://vietkien-upload-image-to-google-driver-api.hf.space/image/$id',
    );
    return FutureBuilder<Uint8List>(
      future: http.readBytes(
        uri,
        headers: {
          'Authorization': 'Bearer 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',
        },
      ),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return const Center(child: Text('Error loading image'));
        }
        return Image.memory(snap.data!, fit: BoxFit.cover);
      },
    );
  }
}
