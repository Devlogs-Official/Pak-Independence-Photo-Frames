import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/services/wallpaper_service.dart';
import '../models/wallpaper_model.dart';

class WallpaperProvider extends ChangeNotifier {
  final WallpaperService _service;
  final int categoryId;
  final int pageSize;

  WallpaperProvider({
    required this.categoryId,
    this.pageSize = 20,
    WallpaperService service = const WallpaperService(),
  }) : _service = service;

  final List<WallpaperModel> _items = [];
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalRecords = 0;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<WallpaperModel> get items => List.unmodifiable(_items);
  int get totalRecords => _totalRecords;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _currentPage < _totalPages;

  Future<void> loadInitial() async {
    if (_isInitialLoading) return;
    _isInitialLoading = true;
    _errorMessage = null;
    _currentPage = 0;
    _totalPages = 1;
    _totalRecords = 0;
    _items.clear();
    notifyListeners();

    try {
      await _loadPage(1);
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isInitialLoading || _isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadPage(_currentPage + 1);
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    if (_items.isEmpty) {
      await loadInitial();
    } else {
      await loadMore();
    }
  }

  Future<void> _loadPage(int page) async {
    final response = await _service.fetchWallpapers(
      categoryId: categoryId,
      page: page,
      pageSize: pageSize,
    );

    final seen = _items.map((item) => item.favoriteKey).toSet();
    for (final item in response.wallpapers) {
      if (seen.add(item.favoriteKey)) {
        _items.add(item);
      }
    }
    _currentPage = response.currentPage;
    _totalPages = response.totalPages;
    _totalRecords = response.totalRecords;
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}
