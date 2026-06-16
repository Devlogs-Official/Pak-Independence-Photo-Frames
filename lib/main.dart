import 'package:flutter/material.dart';
import 'package:pak_independence_photo_frames/features/splash/splash_screen.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'features/frames/screens/frames_editing_screen.dart';
import 'providers/favorites_provider.dart';
import 'providers/wallpaper_apply_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IndependenceFrameProvider()),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider()..loadFavorites(),
        ),
        ChangeNotifierProvider(create: (_) => WallpaperApplyProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
