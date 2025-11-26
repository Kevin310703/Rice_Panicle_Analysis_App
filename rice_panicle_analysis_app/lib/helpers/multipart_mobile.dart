import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

MediaType _guessMime(String name) {
  final ext = p.extension(name).toLowerCase();
  if (ext == '.png') return MediaType('image', 'png');
  if (ext == '.webp') return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}

Future<http.MultipartFile> buildMultipartFile(XFile x) async {
  return http.MultipartFile.fromPath(
    'files',            // ← khớp với field backend FastAPI: files: List[UploadFile]
    x.path,
    filename: x.name,
    contentType: _guessMime(x.name),
  );
}
