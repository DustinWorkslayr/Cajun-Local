import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:cajun_local/core/api/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http_parser/http_parser.dart';

part 'uploads_api.g.dart';

class UploadsApi {
  UploadsApi(this._client);
  final ApiClient _client;

  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String folder = 'general',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename, contentType: MediaType.parse(mimeType)),
      });

      final response = await _client.dio.post(
        '/storage/upload/image',
        data: formData,
        queryParameters: {'folder': folder},
      );

      return response.data['url'] as String;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Upload failed');
    }
  }

  Future<void> deleteFile(String key) async {
    try {
      await _client.dio.delete('/storage/upload', queryParameters: {'key': key});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Delete failed');
    }
  }
}

@riverpod
UploadsApi uploadsApi(UploadsApiRef ref) {
  return UploadsApi(ApiClient.instance);
}
