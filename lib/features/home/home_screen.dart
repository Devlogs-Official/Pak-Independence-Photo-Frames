import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/category_ids.dart';
import '../../widgets/app_drawer.dart';
import '../favorites/favorites_screen.dart';
import 'category_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.lightBackground,
          drawer: AppDrawer(
            onFavorites: _openFavorites,
            onShare: _shareApp,
            onPrivacy: () => _openUrl(AppConstants.privacyPolicyUrl),
            onTerms: () => _openUrl(AppConstants.termsAndConditionsUrl),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
                sliver: SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _SectionTitle(
                      label: 'Explore Categories',
                      accentGradient: AppColors.primaryGradient,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                sliver: SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _CategoryCard(
                                  icon: AppAssets.photoFrameRounded,
                                  label: 'Frames',
                                  subtitle:
                                      '${AppAssets.frames.length} designs',
                                  gradient: AppColors.primaryGradient,
                                  accentColor: AppColors.pakistanGreen,
                                  onTap: () => _openCategory(
                                    context,
                                    title: 'Independence Frames',
                                    categoryId: CategoryIds.frames,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CategoryCard(
                                  icon: AppAssets.dps,
                                  label: 'DPs',
                                  subtitle: 'Profile pics',
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF20A95A),
                                      Color(0xFF08742F),
                                    ],
                                  ),
                                  accentColor: AppColors.emerald,
                                  onTap: () => _openCategory(
                                    context,
                                    title: 'DP Frames',
                                    categoryId: CategoryIds.dpFrames,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _CategoryCard(
                                  icon: AppAssets.wallpapers,
                                  label: 'Live Wallpaper',
                                  subtitle: 'Animated walls',
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF1976D2),
                                      Color(0xFF0D47A1),
                                    ],
                                  ),
                                  accentColor: const Color(0xFF1565C0),
                                  onTap: () => _openCategory(
                                    context,
                                    title: 'Live Wallpapers',
                                    categoryId: CategoryIds.liveWallpapers,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CategoryCard(
                                  icon: AppAssets.wallpapers,
                                  label: 'Static',
                                  subtitle: 'Phone walls',
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFFE38B),
                                      Color(0xFFC89B2B),
                                    ],
                                  ),
                                  accentColor: AppColors.gold,
                                  iconColor: AppColors.deepGreen,
                                  onTap: () => _openCategory(
                                    context,
                                    title: 'Static Wallpapers',
                                    categoryId: CategoryIds.staticWallpapers,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _CategoryCardWide(
                            icon: Icons.card_giftcard_rounded,
                            label: 'Greeting Cards',
                            subtitle: 'Your saved frames and wallpapers',
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF087232), Color(0xFF0A8E3E)],
                            ),
                            onTap: () => _openCategory(
                              context,
                              title: 'Greeting Cards',
                              categoryId: CategoryIds.greetingCards,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _CategoryCardWide(
                            icon: Icons.favorite_rounded,
                            label: 'My Creations/Favorites',
                            subtitle: 'Your saved frames and wallpapers',
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFFD23A2E), Color(0xFF9D241B)],
                            ),
                            onTap: _openFavorites,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 42)),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory(
    BuildContext context, {
    required String title,
    required int categoryId,
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

  void _openFavorites() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()));
  }

  Future<void> _shareApp() async {
    await SharePlus.instance.share(
      ShareParams(text: AppConstants.shareMessage),
    );
  }


  Future<void> _openUrl(String value) async {
    final uri = Uri.parse(value);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Exit App?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final LinearGradient accentGradient;

  const _SectionTitle({required this.label, required this.accentGradient});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: accentGradient,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;

  const _HeroHeader({required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, topPad + 24, 22, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _HeroMenuButton(onPressed: onMenuPressed),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroBadge(icon: Icons.flag_rounded, label: '14 August 1947'),
                  _HeroBadge(
                    icon: Icons.star_rounded,
                    label: 'Azadi',
                    isGold: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Photo Frames',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture Azadi with style',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 14,
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

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isGold;

  const _HeroBadge({
    required this.icon,
    required this.label,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: isGold ? null : Colors.white.withValues(alpha: 0.14),
        gradient: isGold ? AppColors.goldGradient : null,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isGold
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.22),
        ),
        boxShadow: isGold
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isGold ? AppColors.deepGreen : Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isGold ? AppColors.deepGreen : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HeroMenuButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          height: 42,
          width: 42,
          child: Icon(Icons.menu_rounded, color: Colors.white),
        ),
      ),
    );
  }
}


class _CategoryCard extends StatefulWidget {
  final String icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final Color accentColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    this.iconColor = Colors.white,
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
          constraints: const BoxConstraints(minHeight: 128),
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  widget.icon,
                  color: widget.iconColor,
                  height: 28,
                  width: 28,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
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

class _CategoryCardWide extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _CategoryCardWide({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_CategoryCardWide> createState() => _CategoryCardWideState();
}

class _CategoryCardWideState extends State<_CategoryCardWide> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepGreen.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
