class AppConstants {
  AppConstants._();

  static const String appName = 'Pakistan Independence Wallpapers';
  static const String appVersion = '1.0.0';
  static const String androidPackageId =
      'pro.devlogs.pakistan.independence.wallpapers';
  static const String androidLiveWallpaperMethodChannel =
      'wallpaper.apply/channel';
  static const String apiBaseUrl =
      'https://api.devlogs.pro/apps/pakistanPhotoFrames/get_wallpapers.php';

  static String get playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  static String get playStoreDeepLink =>
      'market://details?id=$androidPackageId';

  static const String privacyPolicyUrl =
      'https://www.devlogs.pro/privacy-policy/';

  static const String termsAndConditionsUrl =
      'https://www.devlogs.pro/terms-and-conditions/';

  static String get shareMessage =>
      'Check out Pakistan Independence Wallpapers\n$playStoreUrl';
}
