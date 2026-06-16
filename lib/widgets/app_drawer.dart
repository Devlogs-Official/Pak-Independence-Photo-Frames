
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onFavorites;
  final VoidCallback onShare;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  const AppDrawer({super.key,
    required this.onFavorites,
    required this.onShare,
    required this.onPrivacy,
    required this.onTerms,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          decoration: const BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _DrawerHeaderCard(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  children: [
                    _DrawerTile(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      subtitle: 'Back to main screen',
                      isSelected: true,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 8),
                    _DrawerTile(
                      icon: Icons.favorite_rounded,
                      label: 'Favorites',
                      subtitle: 'Saved frames and wallpapers',
                      accentColor: const Color(0xFFD23A2E),
                      onTap: () {
                        Navigator.of(context).pop();
                        onFavorites();
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.share_rounded,
                      label: 'Share App',
                      subtitle: 'Invite friends to celebrate',
                      onTap: () {
                        Navigator.of(context).pop();
                        onShare();
                      },
                    ),
                    const _DrawerDivider(),
                    _DrawerTile(
                      icon: Icons.privacy_tip_rounded,
                      label: 'Privacy Policy',
                      subtitle: 'How your data is handled',
                      accentColor: const Color(0xFF1976D2),
                      onTap: () {
                        Navigator.of(context).pop();
                        onPrivacy();
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.description_rounded,
                      label: 'Terms & Conditions',
                      subtitle: 'App usage guidelines',
                      accentColor: const Color(0xFFC89B2B),
                      onTap: () {
                        Navigator.of(context).pop();
                        onTerms();
                      },
                    ),
                  ],
                ),
              ),
              // const _DrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerHeaderCard extends StatelessWidget {
  const _DrawerHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -34,
            top: -26,
            child: _DrawerGlowCircle(
              size: 118,
              color: Colors.white,
              opacity: .08,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .14),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.pakistanGreen,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .18),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 15,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Azadi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                AppConstants.appName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Celebrate 14 August with frames, DPs, and wallpapers',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .84),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerGlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _DrawerGlowCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;
  final bool isSelected;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.accentColor = AppColors.pakistanGreen,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? accentColor.withValues(alpha: .10)
        : Colors.white.withValues(alpha: .62);
    final borderColor = isSelected
        ? accentColor.withValues(alpha: .22)
        : Colors.white.withValues(alpha: .82);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isSelected ? .10 : .05),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected
                        ? null
                        : accentColor.withValues(alpha: .10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: accentColor.withValues(alpha: .64),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.pakistanGreen.withValues(alpha: .10),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.gold.withValues(alpha: .95),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.pakistanGreen.withValues(alpha: .10),
            ),
          ),
        ],
      ),
    );
  }
}
