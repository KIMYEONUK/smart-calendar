import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calendar/core/network/api_endpoints.dart';
import 'package:smart_calendar/core/network/dio_client.dart';
import 'package:smart_calendar/features/event/data/models/event_model.dart';

final eventDatasourceProvider = Provider<EventDatasource>((ref) {
  return EventDatasource(ref.read(dioClientProvider));
});

class EventDatasource {
  final Dio _dio;
  const EventDatasource(this._dio);

  Future<List<EventModel>> getEvents({DateTime? from, DateTime? to}) async {
    final response = await _dio.get(
      ApiEndpoints.events,
      queryParameters: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    final list = response.data as List;
    return list
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiEndpoints.events, data: data);
    return EventModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EventModel> updateEvent(
      String id, Map<String, dynamic> data) async {
    final response =
        await _dio.put(ApiEndpoints.eventDetail(id), data: data);
    return EventModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete(ApiEndpoints.eventDetail(id));
  }

  Future<List<EventModel>> getUpcomingEvents({int limit = 5}) async {
    final response = await _dio.get(
      ApiEndpoints.eventsUpcoming,
      queryParameters: {'limit': limit},
    );
    final list = response.data as List;
    return list
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EventModel>> extractEventsFromImage(
      List<int> imageBytes) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(imageBytes, filename: 'image.jpg'),
    });
    final response = await _dio.post(
      ApiEndpoints.ocrExtract,
      data: formData,
    );
    final list = response.data as List;
    return list
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
