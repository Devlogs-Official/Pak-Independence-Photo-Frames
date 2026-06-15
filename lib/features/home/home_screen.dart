import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import 'category_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero header ──────────────────────────────────────────────
            const SliverToBoxAdapter(child: _HeroHeader()),

            // ── Section title ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 14),
              sliver: SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Explore Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Category cards row ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              sliver: SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Expanded(
                        child: _CategoryCard(
                          icon: AppAssets.photoFrameRounded,
                          label: 'Frames',
                          subtitle: '${AppAssets.frames.length} designs',
                          gradient: AppColors.primaryGradient,
                          onTap: () => _openCategory(
                            context,
                            title: 'Independence Frames',
                            categoryId: 'independence',
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _CategoryCard(
                          icon: AppAssets.dps,
                          label: 'DPs',
                          subtitle: 'Profile pics',
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1C9A46), Color(0xFF0A7D32)],
                          ),
                          onTap: () => _openCategory(
                            context,
                            title: 'DP Frames',
                            categoryId: 'dp',
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _CategoryCard(
                          icon: AppAssets.wallpapers,
                          label: 'Wallpapers',
                          subtitle: 'Phone walls',
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEBCB6A), Color(0xFFC89B2B)],
                          ),
                          onTap: () => _openCategory(
                            context,
                            title: 'Wallpapers',
                            categoryId: 'wallpaper',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── "All Frames" quick section title ─────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              sliver: SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Featured Frames',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _openCategory(
                          context,
                          title: 'Independence Frames',
                          categoryId: 'independence',
                        ),
                        child: const Text(
                          'See all →',
                          style: TextStyle(
                            color: AppColors.pakistanGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Horizontal frames preview ─────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: AppAssets.frames.length.clamp(0, 8),
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final frame = AppAssets.frames[index];
                      return _HorizontalFrameCard(
                        frame: frame,
                        index: index,
                        onTap: () => _openCategory(
                          context,
                          title: 'Independence Frames',
                          categoryId: 'independence',
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }

  void _openCategory(
    BuildContext context, {
    required String title,
    required String categoryId,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CategoryDetailScreen(title: title, categoryId: categoryId),
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
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(22, topPad + 16, 22, 24),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Stack(
        children: [
          // Decorative crescent top-right
          Positioned(
            right: -10,
            top: 0,
            child: _CrescentDecoration(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          // Gold star accent
          Positioned(
            right: 30,
            bottom: 8,
            child: Icon(
              Icons.star_rounded,
              color: AppColors.gold.withValues(alpha: 0.85),
              size: 28,
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: date badge + flag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Text('🇵🇰 ', style: TextStyle(fontSize: 14)),
                        Text(
                          '14 August 1947',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gold star badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '★  Azadi',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Photo Editor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Capture Azadi with Style! 🎉',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
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
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.pakistanGreen.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pakistanGreen.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle with gradient
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pakistanGreen.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  widget.icon,
                  color: Colors.white,
                  height: 15,
                  width: 15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal Frame Card (preview strip)
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalFrameCard extends StatefulWidget {
  final String frame;
  final int index;
  final VoidCallback onTap;

  const _HorizontalFrameCard({
    required this.frame,
    required this.index,
    required this.onTap,
  });

  @override
  State<_HorizontalFrameCard> createState() => _HorizontalFrameCardState();
}

class _HorizontalFrameCardState extends State<_HorizontalFrameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          width: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pakistanGreen.withValues(alpha: 0.09),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.frame, fit: BoxFit.cover),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Crescent decoration (top-right of header)
// ─────────────────────────────────────────────────────────────────────────────

class _CrescentDecoration extends StatelessWidget {
  final Color color;

  const _CrescentDecoration({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: 110,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: const SizedBox.expand(),
          ),
          Positioned(
            left: 28,
            top: -4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.deepGreen.withValues(alpha: 0.9),
              ),
              child: const SizedBox(height: 108, width: 108),
            ),
          ),
        ],
      ),
    );
  }
}

