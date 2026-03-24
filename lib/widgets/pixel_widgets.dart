import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 10-segment pixel-style progress bar shared across screens.
class SegmentedBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0+
  final bool isOver;
  final double height;

  const SegmentedBar({
    super.key,
    required this.progress,
    required this.isOver,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    const segments = 10;
    final filled = (progress * segments).ceil().clamp(0, segments);

    return Row(
      children: List.generate(segments, (i) {
        final isFilled = i < filled;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: height,
            decoration: BoxDecoration(
              color: isFilled
                  ? (isOver ? AppColors.errorRed : AppColors.coral)
                  : AppColors.softGray,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: isFilled
                    ? (isOver
                        ? AppColors.errorRed.withValues(alpha: 0.6)
                        : AppColors.coral.withValues(alpha: 0.6))
                    : AppColors.mediumGray.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}
