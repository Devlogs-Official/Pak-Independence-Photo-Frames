import 'package:flutter/material.dart';

class LoadingShimmer extends StatelessWidget {
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    required this.height,
    this.borderRadius = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: .10),
              Colors.white.withValues(alpha: .22),
              Colors.white.withValues(alpha: .10),
            ],
          ),
        ),
      ),
    );
  }
}
