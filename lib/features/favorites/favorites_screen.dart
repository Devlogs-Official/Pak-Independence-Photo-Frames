import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_ids.dart';
import '../../core/widgets/empty_widget.dart';
import '../../features/details/greeting_card_detail_screen.dart';
import '../../features/details/live_wallpaper_detail_screen.dart';
import '../../features/details/static_wallpaper_detail_screen.dart';
import '../../models/wallpaper_model.dart';
import '../../providers/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          foregroundColor: Colors.white,
          title: const Text(
            'Favorites',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xB3FFFFFF),
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Static'),
              Tab(text: 'Live'),
              Tab(text: 'Cards'),
            ],
          ),
        ),
        body: Consumer<FavoritesProvider>(
          builder: (context, favorites, _) {
            return TabBarView(
              children: [
                _FavoritesGrid(
                  items: favorites.byCategory(CategoryIds.staticWallpapers),
                  onOpen: (wallpaper) => _open(context, wallpaper),
                ),
                _FavoritesGrid(
                  items: favorites.byCategory(CategoryIds.liveWallpapers),
                  onOpen: (wallpaper) => _open(context, wallpaper),
                ),
                _FavoritesGrid(
                  items: favorites.byCategory(CategoryIds.greetingCards),
                  onOpen: (wallpaper) => _open(context, wallpaper),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _open(BuildContext context, WallpaperModel wallpaper) {
    final Widget screen = switch (wallpaper.categoryId) {
      CategoryIds.liveWallpapers => LiveWallpaperDetailScreen(
        wallpaper: wallpaper,
      ),
      CategoryIds.greetingCards => GreetingCardDetailScreen(
        wallpaper: wallpaper,
      ),
      _ => WallpaperDetailScreen(wallpaper: wallpaper),
    };

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _FavoritesGrid extends StatelessWidget {
  final List<WallpaperModel> items;
  final ValueChanged<WallpaperModel> onOpen;

  const _FavoritesGrid({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyWidget(
        message: 'No favorites found.',
        icon: Icons.favorite_border_rounded,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: .66,
      ),
      itemBuilder: (context, index) {
        final wallpaper = items[index];
        return _FavoriteCard(
          wallpaper: wallpaper,
          onTap: () => onOpen(wallpaper),
        );
      },
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final WallpaperModel wallpaper;
  final VoidCallback onTap;

  const _FavoriteCard({required this.wallpaper, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withValues(alpha: .34)),
            boxShadow: [
              BoxShadow(
                color: AppColors.pakistanGreen.withValues(alpha: .10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: wallpaper.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: AppColors.pakistanGreen.withValues(alpha: .08),
                  ),
                  errorWidget: (_, _, _) =>
                      const Center(child: Icon(Icons.broken_image_rounded)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favorites, _) {
                      return Material(
                        color: Colors.white.withValues(alpha: .92),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => favorites.toggleFavorite(wallpaper),
                          child: const SizedBox(
                            height: 34,
                            width: 34,
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Colors.redAccent,
                              size: 19,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
