import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/media_actions.dart';
import '../../models/wallpaper_model.dart';
import '../../providers/favorites_provider.dart';

class GreetingCardDetailScreen extends StatefulWidget {
  const GreetingCardDetailScreen({required this.wallpaper, super.key});

  final WallpaperModel wallpaper;

  @override
  State<GreetingCardDetailScreen> createState() =>
      _GreetingCardDetailScreenState();
}

class _GreetingCardDetailScreenState extends State<GreetingCardDetailScreen> {
  int _retryToken = 0;
  bool _isSharing = false;
  late Future<Size> _imageSizeFuture;

  @override
  void initState() {
    super.initState();
    _imageSizeFuture = _loadImageSize(widget.wallpaper.imageUrl);
  }

  @override
  void didUpdateWidget(covariant GreetingCardDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallpaper.imageUrl != widget.wallpaper.imageUrl) {
      _imageSizeFuture = _loadImageSize(widget.wallpaper.imageUrl);
    }
  }

  Future<Size> _loadImageSize(String imageUrl) {
    final completer = Completer<Size>();
    final imageProvider = CachedNetworkImageProvider(imageUrl);
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (imageInfo, _) {
        imageStream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(
            Size(
              imageInfo.image.width.toDouble(),
              imageInfo.image.height.toDouble(),
            ),
          );
        }
      },
      onError: (error, stackTrace) {
        imageStream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    imageStream.addListener(listener);
    return completer.future;
  }

  void _retryImageLoad() {
    setState(() {
      _retryToken++;
      _imageSizeFuture = _loadImageSize(widget.wallpaper.imageUrl);
    });
  }

  Future<void> _shareGreetingCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await MediaActions.shareWallpaper(context, widget.wallpaper);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    AppColors.backgroundDark,
                    Color(0xFF14213D),
                    Color(0xFF062316),
                  ]
                : const [
                    Color(0xFFFFF7ED),
                    AppColors.backgroundLight,
                    Color(0xFFEFFDF3),
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: 72,
              child: Icon(
                Icons.brightness_5_rounded,
                size: 150,
                color: AppColors.saffron.withValues(alpha: .1),
              ),
            ),
            Positioned(
              left: -34,
              bottom: 124,
              child: Icon(
                Icons.flag_rounded,
                size: 128,
                color: AppColors.indiaGreen.withValues(alpha: .12),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        _CircleButton(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Greeting Card',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: FutureBuilder<Size>(
                          future: _imageSizeFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return _GreetingCardError(
                                onRetry: _retryImageLoad,
                              );
                            }

                            final imageSize = snapshot.data;
                            final aspectRatio = imageSize == null
                                ? 4 / 3
                                : imageSize.width / imageSize.height;

                            return _GreetingCardFrame(
                              aspectRatio: aspectRatio,
                              child: CachedNetworkImage(
                                key: ValueKey(_retryToken),
                                imageUrl: widget.wallpaper.imageUrl,
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(
                                  milliseconds: 260,
                                ),
                                placeholder: (context, url) => ColoredBox(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return _GreetingCardError(
                                    onRetry: _retryImageLoad,
                                  );
                                },
                              ),
                            ).animate().fadeIn().scale(
                              begin: const Offset(.96, .96),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSharing ? null : _shareGreetingCard,
                            icon: _isSharing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Icon(Icons.share_rounded),
                            label: Text(
                              _isSharing ? 'Sharing...' : 'Share Greeting Card',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Consumer<FavoritesProvider>(
                          builder: (context, favorites, _) {
                            final selected = favorites.isFavorite(
                              widget.wallpaper,
                            );
                            return IconButton.filledTonal(
                              onPressed: () =>
                                  favorites.toggleFavorite(widget.wallpaper),
                              icon: Icon(
                                selected
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                              ),
                              tooltip: selected
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                            );
                          },
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: .18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingCardFrame extends StatelessWidget {
  const _GreetingCardFrame({required this.aspectRatio, required this.child});

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const borderRadius = 24.0;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var height = width / aspectRatio;

        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * aspectRatio;
        }

        return Align(
          child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .28),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: .16),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GreetingCardError extends StatelessWidget {
  const _GreetingCardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broken_image_rounded,
                color: AppColors.saffron,
                size: 44,
              ),
              const SizedBox(height: 14),
              Text(
                'Unable to load greeting card',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: .66),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: .16)),
      ),
      child: IconButton(onPressed: onPressed, icon: Icon(icon)),
    );
  }
}
