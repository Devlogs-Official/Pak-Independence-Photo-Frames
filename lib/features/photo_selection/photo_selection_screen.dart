import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../frames/screens/frames_editing_screen.dart';

class PhotoSelectionScreen extends StatefulWidget {
  final String selectedFrame;

  const PhotoSelectionScreen({required this.selectedFrame, super.key});

  @override
  State<PhotoSelectionScreen> createState() => _PhotoSelectionScreenState();
}

class _PhotoSelectionScreenState extends State<PhotoSelectionScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;
  late AnimationController _starController;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _IndependenceAppBar(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 20),

              // ── Frame preview ──────────────────────────────────────────
              Center(
                child: Hero(
                  tag: 'frame-${widget.selectedFrame}',
                  child: Container(
                    width: 200,
                    height: 270,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: AppColors.primaryGradient,
                      border: Border.all(
                        color: AppColors.gold,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pakistanGreen.withValues(alpha: 0.22),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        widget.selectedFrame,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Heading ────────────────────────────────────────────────
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Text(
                  'جشنِ آزادی مبارک',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Happy Independence Day 🇵🇰',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pakistanGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a photo to create your Independence Day frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              // ── Gold divider ───────────────────────────────────────────
              const _GoldDivider(),
              const SizedBox(height: 24),

              // ── Action cards ───────────────────────────────────────────
              _ActionCard(
                icon: AppAssets.galleryIcon,
                title: 'Gallery',
                subtitle: 'Pick an existing photo',
                onTap: _isPicking ? null : () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 14),
              _ActionCard(
                icon: AppAssets.cameraIcon,
                title: 'Camera',
                subtitle: 'Capture a new moment',
                onTap: _isPicking ? null : () => _pickImage(ImageSource.camera),
              ),

              if (_isPicking) ...[
                const SizedBox(height: 28),
                const Center(child: CircularProgressIndicator()),
              ],

              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPicking = true);
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2400,
      );
      if (!mounted || image == null) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FramesEditingScreen(
            frameImageUrl: widget.selectedFrame,
            imagePath: image.path,
            categoryId: 'independence',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the selected source.')),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _IndependenceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _IndependenceAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🇵🇰  Independence Day Frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold divider
// ─────────────────────────────────────────────────────────────────────────────

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.gold.withValues(alpha: 0.4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '★',
            style: TextStyle(color: AppColors.gold, fontSize: 14),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.gold.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Card
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 130),
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.pakistanGreen.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.pakistanGreen.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Icon with gradient background + gold border accent
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pakistanGreen.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          widget.icon,
                          height: 26,
                          width: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chevron pill
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: AppColors.pakistanGreen.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.pakistanGreen,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (mounted) setState(() => _pressed = value);
  }
}