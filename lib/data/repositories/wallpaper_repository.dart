import '../../models/api_response.dart';
import '../api/api_client.dart';

class WallpaperRepository {
  final ApiClient _apiClient;

  const WallpaperRepository({ApiClient apiClient = const ApiClient()})
    : _apiClient = apiClient;

  Future<ApiResponse> fetchWallpapers({
    required int categoryId,
    required int page,
    required int pageSize,
  }) {
    return _apiClient.fetchWallpapers(
      categoryId: categoryId,
      page: page,
      pageSize: pageSize,
    );
  }
}
