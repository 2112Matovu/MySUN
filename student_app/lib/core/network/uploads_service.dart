import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mysun_app/core/network/api_client.dart';
import 'package:mysun_app/core/network/api_exception.dart';

/// Backs every publishing form's "Add Image" button — picks a photo (camera
/// or gallery) and uploads it to `POST /uploads` (`backend/app/api/v1/uploads.py`),
/// which stores it in Supabase Storage and returns a public URL. That URL is
/// exactly what `image_url`/`image_urls` fields already expect, so nothing
/// downstream (models, Http*Repository) needs to change.
class UploadsService {
  UploadsService(this._dio);
  final Dio _dio;
  final _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
  }

  Future<String> upload(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? 'image/jpeg';
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
          contentType: MediaType.parse(mimeType),
        ),
      });
      final res = await _dio.post('/uploads', data: formData);
      return res.data['url'] as String;
    } on DioException catch (e) {
      throw ApiException(mapDioError(e).message);
    }
  }
}

final uploadsServiceProvider = Provider<UploadsService>(
  (ref) => UploadsService(ref.watch(dioProvider)),
);
