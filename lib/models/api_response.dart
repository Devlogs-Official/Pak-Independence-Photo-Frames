import 'wallpaper_model.dart';

class ApiResponse {
  final List<WallpaperModel> wallpapers;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalRecords;
  final String? message;

  const ApiResponse({
    required this.wallpapers,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.totalRecords,
    this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    required int fallbackCategoryId,
    required int fallbackPage,
    required int fallbackPageSize,
  }) {
    final pagination = _paginationMap(json);
    final rawItems = _itemsList(json);
    final wallpapers = rawItems
        .whereType<Map>()
        .map(
          (item) => WallpaperModel.fromJson(
            Map<String, dynamic>.from(item),
            fallbackCategoryId: fallbackCategoryId,
          ),
        )
        .where((wallpaper) => wallpaper.imageUrl.isNotEmpty)
        .toList(growable: false);

    final currentPage =
        _intValue(pagination, const ['current_page', 'currentPage', 'page']) ??
        _intValue(json, const ['current_page', 'currentPage', 'page']) ??
        fallbackPage;
    final pageSize =
        _intValue(pagination, const ['page_size', 'pageSize', 'per_page']) ??
        _intValue(json, const ['page_size', 'pageSize', 'per_page']) ??
        fallbackPageSize;
    final totalRecords =
        _intValue(pagination, const [
          'total_records',
          'totalRecords',
          'total',
        ]) ??
        _intValue(json, const ['total_records', 'totalRecords', 'total']) ??
        wallpapers.length;
    final totalPages =
        _intValue(pagination, const [
          'total_pages',
          'totalPages',
          'last_page',
        ]) ??
        _intValue(json, const ['total_pages', 'totalPages', 'last_page']) ??
        (totalRecords == 0 ? currentPage : (totalRecords / pageSize).ceil());

    return ApiResponse(
      wallpapers: wallpapers,
      currentPage: currentPage,
      pageSize: pageSize,
      totalPages: totalPages < currentPage ? currentPage : totalPages,
      totalRecords: totalRecords,
      message: json['message']?.toString(),
    );
  }

  static Map<String, dynamic> _paginationMap(Map<String, dynamic> json) {
    final direct = json['pagination'];
    if (direct is Map) return Map<String, dynamic>.from(direct);

    final data = json['data'];
    if (data is Map && data['pagination'] is Map) {
      return Map<String, dynamic>.from(data['pagination'] as Map);
    }
    return const {};
  }

  static List<dynamic> _itemsList(Map<String, dynamic> json) {
    for (final key in const ['wallpapers', 'items', 'records', 'results']) {
      final value = json[key];
      if (value is List) return value;
    }

    final data = json['data'];
    if (data is List) return data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const ['wallpapers', 'items', 'records', 'results']) {
        final value = map[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  static int? _intValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }
}
