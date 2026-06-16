import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../../models/api_response.dart';

class ApiClient {
  const ApiClient();

  Future<ApiResponse> fetchWallpapers({
    required int categoryId,
    required int page,
    required int pageSize,
  }) async {
    final uri = Uri.parse(AppConstants.apiBaseUrl).replace(
      queryParameters: {
        'category_id': categoryId.toString(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Server error (${response.statusCode}). Please try again.',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Invalid response from server.');
      }

      return ApiResponse.fromJson(
        decoded,
        fallbackCategoryId: categoryId,
        fallbackPage: page,
        fallbackPageSize: pageSize,
      );
    } on SocketException {
      throw const ApiException('No internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid response from server.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Something went wrong. Please try again.');
    } finally {
      client.close(force: true);
    }
  }
}

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}
