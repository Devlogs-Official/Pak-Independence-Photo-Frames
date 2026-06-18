import '../core/constants/app_constants.dart';

class WallpaperModel {
  final int id;
  final String name;
  final String imageUrl;
  final String thumbnailUrl;
  final int categoryId;
  final DateTime? createdAt;

  const WallpaperModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.categoryId,
    this.createdAt,
  });

  factory WallpaperModel.fromJson(
    Map<String, dynamic> json, {
    required int fallbackCategoryId,
  }) {
    final imageUrl = _absoluteUrl(
      _stringValue(json, const [
        'image_url',
        'imageUrl',
        'image',
        'wallpaper_url',
        'wallpaperUrl',
        'file_url',
        'fileUrl',
        'frame_url',
        'frameUrl',
        'url',
        'path',
      ]),
    );
    final thumbnailUrl = _absoluteUrl(
      _stringValue(json, const [
        'thumbnail_url',
        'thumbnailUrl',
        'thumbnail',
        'thumb_url',
        'thumbUrl',
        'thumb',
        'preview_url',
        'previewUrl',
      ]),
    );
    final displayUrl = imageUrl.isEmpty ? thumbnailUrl : imageUrl;
    final thumbnail = thumbnailUrl.isEmpty ? displayUrl : thumbnailUrl;
    final categoryId =
        _intValue(json, const ['category_id', 'categoryId', 'cat_id']) ??
        fallbackCategoryId;
    final id =
        _intValue(json, const ['id', 'wallpaper_id', 'wallpaperId']) ??
        Object.hash(displayUrl, categoryId);
    final name = _stringValue(json, const ['name', 'title', 'filename']);
    final createdRaw = _stringValue(json, const [
      'created_at',
      'createdAt',
      'date',
      'created',
    ]);

    return WallpaperModel(
      id: id,
      name: name.isEmpty ? 'Wallpaper $id' : name,
      imageUrl: displayUrl,
      thumbnailUrl: thumbnail,
      categoryId: categoryId,
      createdAt: DateTime.tryParse(createdRaw),
    );
  }

  factory WallpaperModel.fromStoredJson(Map<String, dynamic> json) {
    return WallpaperModel(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      thumbnailUrl:
          json['thumbnailUrl']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
      categoryId: _asInt(json['categoryId']) ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'categoryId': categoryId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get favoriteKey => '$categoryId-$id';

  static String _stringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static int? _intValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final parsed = _asInt(json[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _absoluteUrl(String value) {
    if (value.isEmpty ||
        value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    final base = Uri.parse(AppConstants.apiBaseUrl);
    if (value.startsWith('/')) {
      return '${base.scheme}://${base.host}$value';
    }

    final basePath = base.path.substring(0, base.path.lastIndexOf('/') + 1);
    return '${base.scheme}://${base.host}$basePath$value';
  }
}
