import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calendar/core/network/dio_client.dart';

class PhotoDatasource {
  final Dio _dio;
  PhotoDatasource(this._dio);

  Future<List<Map<String, dynamic>>> getPhotos(String eventId) async {
    final res = await _dio.get('/events/$eventId/photos');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> uploadPhoto(String eventId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last),
    });
    final res = await _dio.post('/events/$eventId/photos', data: formData);
    return res.data;
  }

  Future<void> deletePhoto(String eventId, String photoId) async {
    await _dio.delete('/events/$eventId/photos/$photoId');
  }
}

final photoDatasourceProvider = Provider<PhotoDatasource>((ref) {
  return PhotoDatasource(ref.read(dioClientProvider));
});

final eventPhotosProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, eventId) {
  return ref.read(photoDatasourceProvider).getPhotos(eventId);
});
