import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/category_ids.dart';
import '../../features/details/greeting_card_detail_screen.dart';
import '../../features/details/live_wallpaper_detail_screen.dart';
import '../../features/details/static_wallpaper_detail_screen.dart';
import '../../models/wallpaper_model.dart';
import '../../providers/favorites_provider.dart';

enum _CollectionTabType { frames, dp, live, static, cards }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  _CollectionTabType _selectedTab = _CollectionTabType.frames;
  List<File> _frameCreations = const [];
  List<File> _dpCreations = const [];
  bool _isLoadingCreations = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCreations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        bottom: false,
        child: Consumer<FavoritesProvider>(
          builder: (context, favorites, _) {
            final tabs = _buildTabs(favorites);
            final activeTab = tabs.firstWhere(
              (tab) => tab.type == _selectedTab,
              orElse: () => tabs.first,
            );
            final total = tabs.fold<int>(0, (sum, tab) => sum + tab.count);

            return Column(
              children: [
                _FavoritesHeader(total: total),
                _FavoritesFilterBar(
                  tabs: tabs,
                  selectedTab: _selectedTab,
                  onChanged: (tab) => setState(() => _selectedTab = tab),
                ),
                Expanded(child: _buildBody(activeTab, favorites)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(_CollectionTab tab, FavoritesProvider favorites) {
    return switch (tab.type) {
      _CollectionTabType.frames => _SavedWorkGrid(
        label: 'Frames',
        files: _frameCreations,
        isLoading: _isLoadingCreations,
        onRefresh: _loadSavedCreations,
        onOpen: (index) => _openSavedWork(_frameCreations, index, 'Photo Frames'),
      ),
      _CollectionTabType.dp => _SavedWorkGrid(
        label: 'DP',
        files: _dpCreations,
        isLoading: _isLoadingCreations,
        onRefresh: _loadSavedCreations,
        onOpen: (index) => _openSavedWork(_dpCreations, index, 'DP Frames'),
      ),
      _CollectionTabType.live => _FavoriteTabBody(
        label: 'Live',
        items: favorites.byCategory(CategoryIds.liveWallpapers),
        onOpen: (wallpaper) => _openFavorite(context, wallpaper),
      ),
      _CollectionTabType.static => _FavoriteTabBody(
        label: 'Static',
        items: favorites.byCategory(CategoryIds.staticWallpapers),
        onOpen: (wallpaper) => _openFavorite(context, wallpaper),
      ),
      _CollectionTabType.cards => _FavoriteTabBody(
        label: 'Cards',
        items: favorites.byCategory(CategoryIds.greetingCards),
        onOpen: (wallpaper) => _openFavorite(context, wallpaper),
      ),
    };
  }

  List<_CollectionTab> _buildTabs(FavoritesProvider favorites) {
    return [
      _CollectionTab(
        type: _CollectionTabType.frames,
        label: 'Frames',
        icon: Icons.filter_frames_rounded,
        count: _frameCreations.length,
      ),
      _CollectionTab(
        type: _CollectionTabType.dp,
        label: 'DP',
        icon: Icons.account_box_rounded,
        count: _dpCreations.length,
      ),
      _CollectionTab(
        type: _CollectionTabType.live,
        label: 'Live',
        icon: Icons.auto_awesome_motion_rounded,
        count: favorites.byCategory(CategoryIds.liveWallpapers).length,
      ),
      _CollectionTab(
        type: _CollectionTabType.static,
        label: 'Static',
        icon: Icons.wallpaper_rounded,
        count: favorites.byCategory(CategoryIds.staticWallpapers).length,
      ),
      _CollectionTab(
        type: _CollectionTabType.cards,
        label: 'Cards',
        icon: Icons.card_giftcard_rounded,
        count: favorites.byCategory(CategoryIds.greetingCards).length,
      ),
    ];
  }

  Future<void> _loadSavedCreations() async {
    setState(() => _isLoadingCreations = true);
    final frames = await _loadPngFiles([
      'independence_frames',
      'wedding_frames',
    ]);
    final dp = await _loadPngFiles(['independence_dp', 'dp_frames']);
    if (!mounted) return;
    setState(() {
      _frameCreations = frames;
      _dpCreations = dp;
      _isLoadingCreations = false;
    });
  }

  Future<List<File>> _loadPngFiles(List<String> folders) async {
    final root = await getExternalStorageDirectory();
    if (root == null) return const [];

    final files = <File>[];
    for (final folder in folders) {
      final directory = Directory('${root.path}/$folder');
      if (!await directory.exists()) continue;
      files.addAll(
        directory.listSync().whereType<File>().where(
          (file) => file.path.toLowerCase().endsWith('.png'),
        ),
      );
    }

    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return files;
  }

  void _openFavorite(BuildContext context, WallpaperModel wallpaper) {
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

  void _openSavedWork(List<File> files, int index, String title) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => _SavedWorkPreviewScreen(
              files: files,
              initialIndex: index,
              title: title,
            ),
          ),
        )
        .then((_) => _loadSavedCreations());
  }
}

class _CollectionTab {
  final _CollectionTabType type;
  final String label;
  final IconData icon;
  final int count;

  const _CollectionTab({
    required this.type,
    required this.label,
    required this.icon,
    required this.count,
  });
}

class _FavoritesHeader extends StatelessWidget {
  final int total;

  const _FavoritesHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.gold.withValues(alpha: .38)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: .26),
            Colors.white,
            AppColors.pakistanGreen.withValues(alpha: .13),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pakistanGreen.withValues(alpha: .08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -24,
            child: Icon(
              Icons.favorite_rounded,
              size: 150,
              color: AppColors.gold.withValues(alpha: .16),
            ),
          ),
          Positioned(
            left: -36,
            bottom: -34,
            child: Icon(
              Icons.collections_rounded,
              size: 116,
              color: AppColors.pakistanGreen.withValues(alpha: .12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _HeaderBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Saved Collection',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Your edited frames, DP creations, and favorite designs in one place.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: .04, end: 0);
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.pakistanGreen.withValues(alpha: .1),
        ),
      ),
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
        color: AppColors.deepGreen,
        tooltip: 'Back',
      ),
    );
  }
}

class _FavoritesFilterBar extends StatelessWidget {
  final List<_CollectionTab> tabs;
  final _CollectionTabType selectedTab;
  final ValueChanged<_CollectionTabType> onChanged;

  const _FavoritesFilterBar({
    required this.tabs,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.pakistanGreen.withValues(alpha: .1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pakistanGreen.withValues(alpha: .07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return _FilterTab(
            tab: tab,
            selected: tab.type == selectedTab,
            onTap: () => onChanged(tab.type),
          );
        },
      ),
    ).animate().fadeIn(delay: 80.ms, duration: 260.ms).slideY(begin: .05);
  }
}

class _FilterTab extends StatelessWidget {
  final _CollectionTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 19,
                color: selected ? AppColors.deepGreen : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: TextStyle(
                  color: selected ? AppColors.deepGreen : AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${tab.count}',
                style: TextStyle(
                  color: selected
                      ? AppColors.deepGreen
                      : AppColors.muted.withValues(alpha: .72),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedWorkGrid extends StatelessWidget {
  final String label;
  final List<File> files;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onOpen;

  const _SavedWorkGrid({
    required this.label,
    required this.files,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (files.isEmpty) {
      return _EmptyCollection(
        title: 'No $label creations',
        message: label == 'DP'
            ? 'Saved DP edits will appear here after you download them.'
            : 'Saved frame edits will appear here after you download them.',
        icon: label == 'DP'
            ? Icons.account_box_rounded
            : Icons.filter_frames_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: label == 'DP' ? 1 : .68,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) => _SavedWorkItem(
          file: files[index],
          label: '$label ${index + 1}',
          onTap: () => onOpen(index),
        ).animate(delay: (40 * index).ms).fadeIn().slideY(begin: .04),
      ),
    );
  }
}

class _SavedWorkItem extends StatelessWidget {
  final File file;
  final String label;
  final VoidCallback onTap;

  const _SavedWorkItem({
    required this.file,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gold.withValues(alpha: .34)),
            boxShadow: [
              BoxShadow(
                color: AppColors.pakistanGreen.withValues(alpha: .09),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(file, fit: BoxFit.cover),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: .60),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ],
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

class _FavoriteTabBody extends StatelessWidget {
  final String label;
  final List<WallpaperModel> items;
  final ValueChanged<WallpaperModel> onOpen;

  const _FavoriteTabBody({
    required this.label,
    required this.items,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyCollection(
        title: 'No $label favorites',
        message: switch (label) {
          'Cards' =>
            'Greeting cards you favorite will be ready here for quick sharing.',
          'Live' => 'Save live wallpapers you want to revisit later.',
          _ => 'Save static wallpapers you love and build your collection.',
        },
        icon: switch (label) {
          'Cards' => Icons.card_giftcard_rounded,
          'Live' => Icons.auto_awesome_motion_rounded,
          _ => Icons.wallpaper_rounded,
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: .68,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _FavoriteGridItem(
        wallpaper: items[index],
        index: index,
        onTap: () => onOpen(items[index]),
      ).animate(delay: (40 * index).ms).fadeIn().slideY(begin: .04),
    );
  }
}

class _FavoriteGridItem extends StatelessWidget {
  final WallpaperModel wallpaper;
  final int index;
  final VoidCallback onTap;

  const _FavoriteGridItem({
    required this.wallpaper,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = wallpaper.thumbnailUrl.isNotEmpty
        ? wallpaper.thumbnailUrl
        : wallpaper.imageUrl;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gold.withValues(alpha: .34)),
            boxShadow: [
              BoxShadow(
                color: AppColors.pakistanGreen.withValues(alpha: .09),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.pakistanGreen.withValues(alpha: .08),
                    ),
                    errorWidget: (_, _, _) =>
                        const Center(child: Icon(Icons.broken_image_rounded)),
                  )
                else
                  const Center(child: Icon(Icons.broken_image_rounded)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: .62),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favorites, _) {
                      return Material(
                        color: Colors.white.withValues(alpha: .92),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => favorites.toggleFavorite(wallpaper),
                          child: const SizedBox(
                            height: 36,
                            width: 36,
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_labelFor(wallpaper.categoryId)} ${index + 1}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Text(
                          'Open',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(int categoryId) {
    return switch (categoryId) {
      CategoryIds.greetingCards => 'Card',
      CategoryIds.liveWallpapers => 'Live',
      _ => 'Wallpaper',
    };
  }
}

class _EmptyCollection extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _EmptyCollection({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.pakistanGreen.withValues(alpha: .10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.gold.withValues(alpha: .28),
                      Colors.white.withValues(alpha: .10),
                      AppColors.pakistanGreen.withValues(alpha: .18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: .34),
                  ),
                ),
                child: Icon(icon, color: AppColors.gold, size: 56),
              ).animate().scale().fadeIn(),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(begin: .06),
    );
  }
}

class _SavedWorkPreviewScreen extends StatefulWidget {
  final List<File> files;
  final int initialIndex;
  final String title;

  const _SavedWorkPreviewScreen({
    required this.files,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_SavedWorkPreviewScreen> createState() =>
      _SavedWorkPreviewScreenState();
}

class _SavedWorkPreviewScreenState extends State<_SavedWorkPreviewScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.deepGreen,
        title: Text(widget.title),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.files.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: .8,
            maxScale: 4,
            child: Center(
              child: Image.file(widget.files[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
