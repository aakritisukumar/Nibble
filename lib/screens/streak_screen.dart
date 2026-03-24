import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1);
    if (next.year < now.year ||
        (next.year == now.year && next.month <= now.month)) {
      setState(() => _displayMonth = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider);
    final dates = ref.watch(datesWithEntriesProvider);
    final today = DateTime.now();
    final todayKey = StorageService.todayKey();

    final isCurrentMonth = _displayMonth.year == today.year &&
        _displayMonth.month == today.month;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Streak card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md + 4),
              decoration: BoxDecoration(
                color: streak > 0 ? AppColors.coral : AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: streak > 0
                      ? AppColors.coral.withValues(alpha: 0.5)
                      : AppColors.darkGray.withValues(alpha: 0.18),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: streak > 0
                        ? AppColors.coral.withValues(alpha: 0.35)
                        : AppColors.darkGray.withValues(alpha: 0.18),
                    blurRadius: 0,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Streak',
                          style: AppTextStyles.label(
                            color: streak > 0
                                ? AppColors.white.withValues(alpha: 0.75)
                                : AppColors.mediumGray,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          streak == 0
                              ? 'No streak yet'
                              : '$streak day${streak == 1 ? '' : 's'}',
                          style: AppTextStyles.number(
                            color: streak > 0 ? AppColors.white : AppColors.darkGray,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          streak == 0
                              ? 'Log a meal to start your streak'
                              : streak == 1
                                  ? 'Keep it up!'
                                  : 'You\'re on a roll!',
                          style: AppTextStyles.caption(
                            color: streak > 0
                                ? AppColors.white.withValues(alpha: 0.8)
                                : AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: streak > 0
                          ? AppColors.white.withValues(alpha: 0.2)
                          : AppColors.softGray,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: 30,
                      color: streak > 0 ? AppColors.white : AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Month navigation ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavArrow(icon: Icons.chevron_left_rounded, onTap: _prevMonth),
                Text(
                  DateFormat('MMMM yyyy').format(_displayMonth),
                  style: AppTextStyles.subheading(),
                ),
                _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: isCurrentMonth ? null : _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Day-of-week headers ──────────────────────────────────────
            Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(d, style: AppTextStyles.label()),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Calendar grid ─────────────────────────────────────────────
            _CalendarGrid(
              displayMonth: _displayMonth,
              dates: dates,
              todayKey: todayKey,
              today: today,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav Arrow ─────────────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? AppColors.darkGray.withValues(alpha: 0.18)
                : AppColors.softGray,
            width: 1.5,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.darkGray.withValues(alpha: 0.12),
                    blurRadius: 0,
                    offset: const Offset(2, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.darkGray : AppColors.mediumGray.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ── Calendar Grid ──────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime displayMonth;
  final Set<String> dates;
  final String todayKey;
  final DateTime today;

  const _CalendarGrid({
    required this.displayMonth,
    required this.dates,
    required this.todayKey,
    required this.today,
  });

  String _keyForDay(int day) {
    return '${displayMonth.year}-${displayMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: rows * 7,
      itemBuilder: (_, index) {
        final dayNum = index - startOffset + 1;
        if (dayNum < 1 || dayNum > daysInMonth) {
          return const SizedBox.shrink();
        }

        final key = _keyForDay(dayNum);
        final isToday = key == todayKey;
        final hasEntry = dates.contains(key);
        final thisDate = DateTime(displayMonth.year, displayMonth.month, dayNum);
        final isFuture = thisDate.isAfter(today);

        return _DayCell(
          day: dayNum,
          isToday: isToday,
          hasEntry: hasEntry,
          isFuture: isFuture,
        );
      },
    );
  }
}

// ── Day Cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasEntry;
  final bool isFuture;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasEntry,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor;
    Border? border;
    List<BoxShadow>? shadow;

    if (hasEntry) {
      bgColor = AppColors.coral;
      textColor = AppColors.white;
      shadow = [
        BoxShadow(
          color: AppColors.coral.withValues(alpha: 0.4),
          blurRadius: 0,
          offset: const Offset(2, 2),
        ),
      ];
    } else if (isToday) {
      bgColor = null;
      textColor = AppColors.mint;
      border = Border.all(color: AppColors.mint, width: 1.5);
    } else if (isFuture) {
      bgColor = null;
      textColor = AppColors.mediumGray.withValues(alpha: 0.3);
    } else {
      bgColor = null;
      textColor = AppColors.darkGray;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: border,
        boxShadow: shadow,
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppTextStyles.caption(
            color: textColor,
          ).copyWith(
            fontWeight: (isToday || hasEntry) ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
