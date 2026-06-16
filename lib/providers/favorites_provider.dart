import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallpaper_model.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _storageKey = 'favorite_wallpapers';

  final Map<String, WallpaperModel> _favorites = {};
  bool _loaded = false;

  List<WallpaperModel> get favorites =>
      _favorites.values.toList()..sort((a, b) => b.id.compareTo(a.id));

  bool get loaded => _loaded;

  Future<void> loadFavorites() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? const [];
    _favorites
      ..clear()
      ..addEntries(
        stored
            .map((item) => jsonDecode(item))
            .whereType<Map>()
            .map(
              (item) => WallpaperModel.fromStoredJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.imageUrl.isNotEmpty)
            .map((item) => MapEntry(item.favoriteKey, item)),
      );
    _loaded = true;
    notifyListeners();
  }

  bool isFavorite(WallpaperModel wallpaper) {
    return _favorites.containsKey(wallpaper.favoriteKey);
  }

  Future<void> toggleFavorite(WallpaperModel wallpaper) async {
    if (isFavorite(wallpaper)) {
      _favorites.remove(wallpaper.favoriteKey);
    } else {
      _favorites[wallpaper.favoriteKey] = wallpaper;
    }
    notifyListeners();
    await _persist();
  }

  List<WallpaperModel> byCategory(int categoryId) {
    return favorites
        .where((wallpaper) => wallpaper.categoryId == categoryId)
        .toList(growable: false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _favorites.values.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
