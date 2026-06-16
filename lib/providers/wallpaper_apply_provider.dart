import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';

enum WallpaperTarget {
  home('Home Screen', 'Apply to your home screen'),
  lock('Lock Screen', 'Apply to your lock screen'),
  both('Both Screens', 'Apply to home and lock screens');

  final String title;
  final String subtitle;

  const WallpaperTarget(this.title, this.subtitle);
}

class WallpaperApplyResult {
  final bool success;
  final String message;

  const WallpaperApplyResult({required this.success, required this.message});
}

class WallpaperApplyProvider extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel(
    AppConstants.androidLiveWallpaperMethodChannel,
  );

  bool _isApplying = false;

  bool get isApplying => _isApplying;

  Future<WallpaperApplyResult> apply({
    required String imageUrl,
    required WallpaperTarget target,
  }) async {
    return _runApply(() async {
      await _channel.invokeMethod<void>('applyWallpaper', {
        'imageUrl': imageUrl,
        'target': target.name,
      });
      return const WallpaperApplyResult(
        success: true,
        message: 'Wallpaper applied successfully.',
      );
    });
  }

  Future<WallpaperApplyResult> applyLive({
    required String videoUrl,
    required String id,
  }) async {
    return _runApply(() async {
      await _channel.invokeMethod<void>('applyLiveWallpaper', {
        'videoUrl': videoUrl,
        'id': id,
      });
      return const WallpaperApplyResult(
        success: true,
        message: 'Live wallpaper applied successfully.',
      );
    });
  }

  Future<WallpaperApplyResult> _runApply(
    Future<WallpaperApplyResult> Function() action,
  ) async {
    if (_isApplying) {
      return const WallpaperApplyResult(
        success: false,
        message: 'Please wait, wallpaper is being applied.',
      );
    }

    _isApplying = true;
    notifyListeners();
    try {
      return await action();
    } on PlatformException catch (error) {
      return WallpaperApplyResult(
        success: false,
        message: error.message ?? 'Unable to apply wallpaper.',
      );
    } on MissingPluginException {
      return const WallpaperApplyResult(
        success: false,
        message: 'Wallpaper apply is not available on this device.',
      );
    } catch (_) {
      return const WallpaperApplyResult(
        success: false,
        message: 'Unable to apply wallpaper.',
      );
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }
}
