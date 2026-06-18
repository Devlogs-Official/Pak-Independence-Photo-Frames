import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_ids.dart';
import '../../core/widgets/empty_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../features/details/greeting_card_detail_screen.dart';
import '../../features/details/live_wallpaper_detail_screen.dart';
import '../../features/details/static_wallpaper_detail_screen.dart';
import '../../models/wallpaper_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/wallpaper_provider.dart';
import '../photo_selection/photo_selection_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String title;
  final int categoryId;

  const CategoryDetailScreen({
    required this.title,
    required this.categoryId,
    super.key,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final ScrollController _scrollController;
  late final WallpaperProvider _wallpaperProvider;

  static const double _canvasAspect = 1080 / 1720;
  static const double _dpCanvasAspect = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _scrollController = ScrollController()..addListener(_onScroll);
    _wallpaperProvider = WallpaperProvider(categoryId: widget.categoryId)
      ..loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _wallpaperProvider.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 520) {
      _wallpaperProvider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _wallpaperProvider,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            title: Text(widget.title),
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppColors.deepGreen,
          ),
          body: Consumer<WallpaperProvider>(
            builder: (context, provider, _) {
              return CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (provider.isInitialLoading)
                    const SliverFillRemaining(
                      child: LoadingWidget(message: 'Loading ...'),
                    )
                  else if (provider.items.isEmpty && provider.hasError)
                    SliverFillRemaining(
                      child: AppErrorWidget(
                        message: provider.errorMessage!,
                        onRetry: provider.loadInitial,
                      ),
                    )
                  else if (provider.items.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyWidget(message: 'No Data Found.'),
                    )
                  else ...[
                    // SliverPadding(
                    //   padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    //   sliver: SliverToBoxAdapter(
                    //     child: FadeTransition(
                    //       opacity: _fadeAnimation,
                    //       child: _CategorySummary(
                    //         count: provider.totalRecords == 0
                    //             ? provider.items.length
                    //             : provider.totalRecords,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      sliver: SliverGrid.builder(
                        itemCount: provider.items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: _gridAspectForCategory(
                            widget.categoryId,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final wallpaper = provider.items[index];
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: _WallpaperGridCard(
                              wallpaper: wallpaper,
                              index: index,
                              label: _labelForCategory(widget.categoryId),
                              onTap: () => _openWallpaper(context, wallpaper),
                            ),
                          );
                        },
                      ),
                    ),
                    if (provider.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 8, 0, 28),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (provider.hasError)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                          child: _InlineRetry(
                            message: provider.errorMessage!,
                            onRetry: provider.retry,
                          ),
                        ),
                      )
                    else
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // String _hintForCategory(int categoryId) {
  //   if (CategoryIds.isFrameCategory(categoryId)) return 'Tap a frame to use it';
  //   if (categoryId == CategoryIds.liveWallpapers) return 'Tap to preview live';
  //   if (categoryId == CategoryIds.greetingCards) return 'Tap to open card';
  //   return 'Tap to preview wallpaper';
  // }

  double _gridAspectForCategory(int categoryId) {
    if (categoryId == CategoryIds.dpFrames) return _dpCanvasAspect;
    if (CategoryIds.isFrameCategory(categoryId)) return _canvasAspect;
    return 0.66;
  }

  String _labelForCategory(int categoryId) {
    if (categoryId == CategoryIds.staticWallpapers) return 'Wallpaper';
    if (categoryId == CategoryIds.liveWallpapers) return 'Live';
    if (categoryId == CategoryIds.greetingCards) return 'Card';
    if (categoryId == CategoryIds.dpFrames) return 'DP';
    return 'Frame';
  }

  void _openWallpaper(BuildContext context, WallpaperModel wallpaper) {
    Widget screen;
    switch (wallpaper.categoryId) {
      case CategoryIds.staticWallpapers:
        screen = WallpaperDetailScreen(wallpaper: wallpaper);
      case CategoryIds.liveWallpapers:
        screen = LiveWallpaperDetailScreen(wallpaper: wallpaper);
      case CategoryIds.greetingCards:
        screen = GreetingCardDetailScreen(wallpaper: wallpaper);
      case CategoryIds.frames:
      case CategoryIds.dpFrames:
        screen = PhotoSelectionScreen(
          selectedFrame: wallpaper.imageUrl,
          categoryId: wallpaper.categoryId,
        );
      default:
        screen = WallpaperDetailScreen(wallpaper: wallpaper);
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _WallpaperGridCard extends StatefulWidget {
  final WallpaperModel wallpaper;
  final int index;
  final String label;
  final VoidCallback onTap;

  const _WallpaperGridCard({
    required this.wallpaper,
    required this.index,
    required this.label,
    required this.onTap,
  });

  @override
  State<_WallpaperGridCard> createState() => _WallpaperGridCardState();
}

class _WallpaperGridCardState extends State<_WallpaperGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isFrameCategory = CategoryIds.isFrameCategory(
      widget.wallpaper.categoryId,
    );
    final imageUrl = widget.wallpaper.thumbnailUrl.isNotEmpty
        ? widget.wallpaper.thumbnailUrl
        : widget.wallpaper.imageUrl;

    return AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pakistanGreen.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: isFrameCategory
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.pakistanGreen.withValues(alpha: .10),
                              AppColors.gold.withValues(alpha: .18),
                              Colors.white,
                            ],
                          )
                        : null,
                    color: isFrameCategory ? null : Colors.white,
                  ),
                ),
                if (imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: isFrameCategory ? BoxFit.contain : BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.pakistanGreen.withValues(alpha: .08),
                    ),
                    errorWidget: (_, _, _) =>
                        const Center(child: Icon(Icons.broken_image_rounded)),
                  )
                else
                  const Center(child: Icon(Icons.broken_image_rounded)),
                if (isFrameCategory)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .65),
                            width: 6,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favorites, _) {
                      final selected = favorites.isFavorite(widget.wallpaper);
                      return _FavoriteButton(
                        selected: selected,
                        onPressed: () =>
                            favorites.toggleFavorite(widget.wallpaper),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.label} ${widget.index + 1}',
                      style: const TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pakistanGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Open',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _FavoriteButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onPressed;

  const _FavoriteButton({required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .90),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          height: 34,
          width: 34,
          child: Icon(
            selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: selected ? Colors.redAccent : AppColors.deepGreen,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _InlineRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: Text(message),
    );
  }
}
