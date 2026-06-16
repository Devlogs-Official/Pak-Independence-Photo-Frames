import '../../models/api_response.dart';
import '../repositories/wallpaper_repository.dart';

class WallpaperService {
  final WallpaperRepository _repository;

  const WallpaperService({
    WallpaperRepository repository = const WallpaperRepository(),
  }) : _repository = repository;

  Future<ApiResponse> fetchWallpapers({
    required int categoryId,
    required int page,
    required int pageSize,
  }) {
    return _repository.fetchWallpapers(
      categoryId: categoryId,
      page: page,
      pageSize: pageSize,
    );
  }
}
