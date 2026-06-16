import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/wallpaper_model.dart';

class MediaActions {
  MediaActions._();

  static Future<void> shareWallpaper(
    BuildContext context,
    WallpaperModel wallpaper,
  ) {
    return shareRemoteFile(
      context: context,
      url: wallpaper.imageUrl,
      filename: _filenameFor(wallpaper),
    );
  }

  static Future<void> shareRemoteFile({
    required BuildContext context,
    required String url,
    required String filename,
  }) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const FileSystemException('Could not download media.');
      }

      final bytes = await response.fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Pakistan Independence'),
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _filenameFor(WallpaperModel wallpaper) {
    final extension = Uri.tryParse(wallpaper.imageUrl)?.pathSegments.last;
    final hasExtension = extension != null && extension.contains('.');
    final safeName = wallpaper.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return hasExtension
        ? '${safeName}_${wallpaper.id}_$extension'
        : '${safeName}_${wallpaper.id}.jpg';
  }
}
