import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../photo_selection/photo_selection_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String title;
  final String categoryId;

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

  // Canvas aspect ratio  1080 × 1720
  static const double _canvasAspect = 1080 / 1720;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _frames => AppAssets.frames;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Themed app bar ───────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryAppBarDelegate(title: widget.title),
            ),

            // ── Count badge ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_frames.length} Designs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '· Tap a frame to use it',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Grid ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid.builder(
                itemCount: _frames.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  // Match canvas 1080×1720 ratio so thumbnails look identical
                  // to what will be applied on the editing canvas.
                  childAspectRatio: _canvasAspect,
                ),
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _FrameGridCard(
                      frame: _frames[index],
                      index: index,
                      onTap: () => _navigateToPhotoSelection(
                        context,
                        _frames[index],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPhotoSelection(BuildContext context, String frame) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PhotoSelectionScreen(selectedFrame: frame),
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

// ─────────────────────────────────────────────────────────────────────────────
// Pinned App Bar Delegate
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryAppBarDelegate extends SliverPersistentHeaderDelegate {
  final String title;

  const _CategoryAppBarDelegate({required this.title});

  @override
  double get minExtent => kToolbarHeight + 32;
  @override
  double get maxExtent => 160;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final topPad = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Stack(
        children: [
          // Decorative crescent fades out on scroll
          Positioned(
            right: -10,
            top: topPad,
            child: Opacity(
              opacity: 1 - progress,
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: const SizedBox.expand(),
                    ),
                    Positioned(
                      left: 22,
                      top: -4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.deepGreen.withValues(alpha: 0.9),
                        ),
                        child: const SizedBox(height: 88, width: 88),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Gold bottom accent line
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.goldGradient),
              ),
            ),
          ),
          // Back button + title
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Padding(
              padding: EdgeInsets.only(top: topPad),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        if (progress < 0.7)
                          Text(
                            'Independence Day 2024  🇵🇰',
                            style: TextStyle(
                              color: AppColors.gold.withValues(
                                alpha: 1 - progress,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Gold star pill
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '★ 14 Aug',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryAppBarDelegate oldDelegate) =>
      oldDelegate.title != title;
}

// ─────────────────────────────────────────────────────────────────────────────
// Frame Grid Card
// ─────────────────────────────────────────────────────────────────────────────

class _FrameGridCard extends StatefulWidget {
  final String frame;
  final int index;
  final VoidCallback onTap;

  const _FrameGridCard({
    required this.frame,
    required this.index,
    required this.onTap,
  });

  @override
  State<_FrameGridCard> createState() => _FrameGridCardState();
}

class _FrameGridCardState extends State<_FrameGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
                // Frame image — fill exactly to match canvas proportions
                SizedBox.expand(
                  child: Image.asset(widget.frame, fit: BoxFit.fill),
                ),
                // Gradient overlay at bottom for badge readability
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                // Frame number badge
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
                      'Frame ${widget.index + 1}',
                      style: const TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // Use button bottom-right
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
                      'Use →',
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
