import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class HolidayService {
  static const _apiKey =
      '54c343a505978494a2054bcaa0e00c2537f2d3a9cc2b78043ede386005472ed2';

  final Map<String, Map<String, String>> _cache = {};

  Future<Map<String, String>> fetchHolidays(int year, int month) async {
    final mm = month.toString().padLeft(2, "0");
    final cacheKey = "$year-$mm";
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final uri = Uri.parse(
        "https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getHoliDeInfo"
        "?serviceKey=$_apiKey"
        "&solYear=$year"
        "&solMonth=$mm"
        "&_type=json"
        "&numOfRows=20",
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        _cache[cacheKey] = {};
        return {};
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final items = decoded["response"]?["body"]?["items"];
      if (items == null || items == "") {
        _cache[cacheKey] = {};
        return {};
      }

      final result = <String, String>{};
      final itemList = items["item"];
      final list = itemList is List ? itemList : [itemList];

      for (final item in list) {
        final dateStr = item["locdate"].toString();
        if (dateStr.length == 8) {
          final key =
              "${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}";
          result[key] = item["dateName"] as String;
        }
      }

      _cache[cacheKey] = result;
      return result;
    } catch (e) {
      print("[HolidayService] ERROR: $e");
      _cache[cacheKey] = {};
      return {};
    }
  }

  String fmt(DateTime d) {
    final mm = d.month.toString().padLeft(2, "0");
    final dd = d.day.toString().padLeft(2, "0");
    return "${d.year}-$mm-$dd";
  }

  bool isHoliday(DateTime day, Map<String, String> holidays) =>
      holidays.containsKey(fmt(day));

  String? getName(DateTime day, Map<String, String> holidays) =>
      holidays[fmt(day)];
}

final holidayServiceProvider =
    Provider<HolidayService>((_) => HolidayService());

final holidayProvider =
    FutureProvider.family<Map<String, String>, String>((ref, monthKey) async {
  final parts = monthKey.split("-");
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  return ref.read(holidayServiceProvider).fetchHolidays(year, month);
});
