import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/media_actions.dart';
import '../../core/utils/snackbars.dart';
import '../../models/wallpaper_model.dart';
import '../../providers/wallpaper_apply_provider.dart';
import '../../widgets/loading_shimmer.dart';

class WallpaperDetailScreen extends StatelessWidget {
  const WallpaperDetailScreen({required this.wallpaper, super.key});

  final WallpaperModel wallpaper;

  @override
  Widget build(BuildContext context) {
    return WallpaperPreviewScaffold(
      wallpaper: wallpaper,
      applyLabel: 'Apply Wallpaper',
      applyIcon: Icons.wallpaper_rounded,
    );
  }
}

class WallpaperPreviewScaffold extends StatefulWidget {
  const WallpaperPreviewScaffold({
    required this.wallpaper,
    required this.applyLabel,
    required this.applyIcon,
    super.key,
  });

  final WallpaperModel wallpaper;
  final String applyLabel;
  final IconData applyIcon;

  @override
  State<WallpaperPreviewScaffold> createState() =>
      _WallpaperPreviewScaffoldState();
}

class _WallpaperPreviewScaffoldState extends State<WallpaperPreviewScaffold> {
  bool _isSharing = false;

  Future<void> _showApplySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<WallpaperApplyProvider>(
          builder: (context, applyProvider, _) {
            return _WallpaperApplySheet(
              isApplying: applyProvider.isApplying,
              onSelect: (target) => _applyWallpaper(sheetContext, target),
            );
          },
        );
      },
    );
  }

  Future<void> _applyWallpaper(
    BuildContext sheetContext,
    WallpaperTarget target,
  ) async {
    final applyProvider = context.read<WallpaperApplyProvider>();
    if (applyProvider.isApplying) return;

    final navigator = Navigator.of(sheetContext);
    final result = await applyProvider.apply(
      imageUrl: widget.wallpaper.imageUrl,
      target: target,
    );

    if (!mounted) return;
    navigator.pop();
    AppSnackbars.show(context, result.message);
  }

  Future<void> _shareWallpaper() async {
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
    final applyProvider = context.watch<WallpaperApplyProvider>();
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.wallpaper.imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, _) =>
                const LoadingShimmer(height: double.infinity, borderRadius: 0),
            errorWidget: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined, size: 56),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black87],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: _CircleBackButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20 + MediaQuery.paddingOf(context).bottom,
            child: _ActionPanel(
              applyLabel: applyProvider.isApplying
                  ? 'Applying'
                  : widget.applyLabel,
              applyIcon: applyProvider.isApplying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Icon(widget.applyIcon),
              onApply: applyProvider.isApplying ? null : _showApplySheet,
              shareLabel: _isSharing ? 'Sharing' : 'Share',
              shareIcon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share_outlined),
              onShare: _isSharing ? null : _shareWallpaper,
            ).animate().fadeIn().slideY(begin: .25),
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.backgroundDark,
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.applyLabel,
    required this.applyIcon,
    required this.onApply,
    required this.shareLabel,
    required this.shareIcon,
    required this.onShare,
  });

  final String applyLabel;
  final Widget applyIcon;
  final VoidCallback? onApply;
  final String shareLabel;
  final Widget shareIcon;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .48),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _DetailActionButton(
                onPressed: onApply,
                icon: applyIcon,
                label: applyLabel,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _DetailActionButton(
                onPressed: onShare,
                icon: shareIcon,
                label: shareLabel,
                isPrimary: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WallpaperApplySheet extends StatelessWidget {
  const _WallpaperApplySheet({
    required this.isApplying,
    required this.onSelect,
  });

  final bool isApplying;
  final ValueChanged<WallpaperTarget> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.saffron.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .28),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apply Wallpaper',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            for (final target in WallpaperTarget.values)
              _ApplyTargetTile(
                target: target,
                isApplying: isApplying,
                onTap: () => onSelect(target),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApplyTargetTile extends StatelessWidget {
  const _ApplyTargetTile({
    required this.target,
    required this.isApplying,
    required this.onTap,
  });

  final WallpaperTarget target;
  final bool isApplying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          enabled: !isApplying,
          onTap: onTap,
          leading: const Icon(
            Icons.wallpaper_rounded,
            color: AppColors.saffron,
          ),
          title: Text(target.title),
          subtitle: Text(target.subtitle),
          trailing: isApplying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final start = isPrimary ? AppColors.saffron : const Color(0x33FFFFFF);
    final end = isPrimary ? AppColors.indiaGreen : const Color(0x1FFFFFFF);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: [start, end]),
        boxShadow: [
          BoxShadow(
            color: (isPrimary ? AppColors.saffron : Colors.black).withValues(
              alpha: isPrimary ? .32 : .18,
            ),
            blurRadius: isPrimary ? 22 : 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Opacity(
            opacity: onPressed == null ? .62 : 1,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isPrimary ? 18 : 14,
                vertical: isPrimary ? 15 : 13,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme.merge(
                    data: const IconThemeData(color: Colors.white, size: 20),
                    child: icon,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
