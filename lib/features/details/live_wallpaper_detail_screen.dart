import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/media_actions.dart';
import '../../core/utils/snackbars.dart';
import '../../models/wallpaper_model.dart';
import '../../providers/wallpaper_apply_provider.dart';
import '../../widgets/loading_shimmer.dart';

class LiveWallpaperDetailScreen extends StatefulWidget {
  const LiveWallpaperDetailScreen({required this.wallpaper, super.key});

  final WallpaperModel wallpaper;

  @override
  State<LiveWallpaperDetailScreen> createState() =>
      _LiveWallpaperDetailScreenState();
}

class _LiveWallpaperDetailScreenState extends State<LiveWallpaperDetailScreen> {
  VideoPlayerController? _videoController;
  Future<void>? _videoInitFuture;
  bool _isSharing = false;
  bool _isVideoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.wallpaper.imageUrl),
    );
    _videoInitFuture = _videoController!
        .initialize()
        .then((_) async {
          await _videoController!.setLooping(true);
          await _videoController!.setVolume(0);
          await _videoController!.play();
          if (!mounted) return;
          setState(() => _isVideoReady = true);
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() => _videoFailed = true);
        });
  }

  Future<void> _applyLiveWallpaper() async {
    final applyProvider = context.read<WallpaperApplyProvider>();
    if (applyProvider.isApplying) return;

    final result = await applyProvider.applyLive(
      videoUrl: widget.wallpaper.imageUrl,
      id: widget.wallpaper.id.toString(),
    );

    if (!mounted) return;
    AppSnackbars.show(context, result.message);
  }

  Future<void> _shareWallpaper() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await MediaActions.shareRemoteFile(
        context: context,
        url: widget.wallpaper.imageUrl,
        filename: _videoFilename(widget.wallpaper.name),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _videoFilename(String name) {
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '$safeName-${widget.wallpaper.id}.mp4';
  }

  Widget _buildVideoLayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.wallpaper.thumbnailUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: widget.wallpaper.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                const LoadingShimmer(height: double.infinity, borderRadius: 0),
            errorWidget: (_, _, _) => const ColoredBox(color: Colors.black),
          )
        else
          const LoadingShimmer(height: double.infinity, borderRadius: 0),
        FutureBuilder<void>(
          future: _videoInitFuture,
          builder: (context, snapshot) {
            if (_isVideoReady &&
                snapshot.connectionState == ConnectionState.done &&
                _videoController != null &&
                !snapshot.hasError) {
              return AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              );
            }
            if (snapshot.hasError || _videoFailed) {
              return ColoredBox(
                color: Colors.black.withValues(alpha: .45),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white70,
                    size: 42,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final applyProvider = context.watch<WallpaperApplyProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildVideoLayer()),
          if (!_isVideoReady && !_videoFailed)
            const Positioned.fill(child: _LiveDetailShimmer()),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 12,
                  child: _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _ActionPanel(
                    isApplying: applyProvider.isApplying,
                    isSharing: _isSharing,
                    onApply: applyProvider.isApplying
                        ? null
                        : _applyLiveWallpaper,
                    onShare: _isSharing ? null : _shareWallpaper,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDetailShimmer extends StatelessWidget {
  const _LiveDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LoadingShimmer(height: double.infinity, borderRadius: 18),
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.isApplying,
    required this.isSharing,
    required this.onApply,
    required this.onShare,
  });

  final bool isApplying;
  final bool isSharing;
  final VoidCallback? onApply;
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
                icon: isApplying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_motion_rounded),
                label: isApplying ? 'Applying' : 'Apply Wallpaper',
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _DetailActionButton(
                onPressed: onShare,
                icon: isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_outlined),
                label: 'Share',
                isPrimary: false,
              ),
            ),
          ],
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
                  if (label.isNotEmpty) ...[
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
                ],
              ),
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .55)),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.black87),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
