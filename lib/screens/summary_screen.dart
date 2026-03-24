import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/food_entry.dart';
import '../providers/food_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_widgets.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEntries = ref.watch(foodEntriesProvider);
    final totalKcal = ref.watch(todayCaloriesProvider);
    final goal = ref.watch(dailyGoalProvider);
    final days = ref.watch(daysWithEntriesProvider);
    final todayKey = StorageService.todayKey();

    final pastDays = days.where((d) => d != todayKey).toList();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // ── Today card ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: todayEntries.isEmpty
                  ? null
                  : () => _showNutritionDialog(context, ref, todayKey, goal, 'Today'),
              child: _TodayCard(
                entries: todayEntries,
                totalKcal: totalKcal,
                goal: goal,
              ),
            ),
          ),

          // ── History section ──────────────────────────────────────────────
          if (pastDays.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Text('History', style: AppTextStyles.subheading()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final dateKey = pastDays[i];
                    return _HistoryRow(
                      dateKey: dateKey,
                      goal: goal,
                      onTap: () => _showNutritionDialog(context, ref, dateKey, goal, null),
                    );
                  },
                  childCount: pastDays.length,
                ),
              ),
            ),
          ],

          // ── Empty state ──────────────────────────────────────────────────
          if (todayEntries.isEmpty && pastDays.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                today: DateFormat('EEEE, MMMM d').format(DateTime.now()),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showNutritionDialog(
    BuildContext context,
    WidgetRef ref,
    String dateKey,
    int goal,
    String? labelOverride,
  ) {
    final entries = ref.read(entriesForDateProvider(dateKey));
    showDialog(
      context: context,
      builder: (_) => NutritionDialog(
        entries: entries,
        dateKey: dateKey,
        goal: goal,
        labelOverride: labelOverride,
      ),
    );
  }
}

// ── Today Card ─────────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final List<FoodEntry> entries;
  final int totalKcal;
  final int goal;

  const _TodayCard({
    required this.entries,
    required this.totalKcal,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (totalKcal / goal).clamp(0.0, 1.0);
    final isOverGoal = totalKcal > goal;
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final tappable = entries.isNotEmpty;

    final totalCarbs = entries.fold(0, (s, e) => s + e.carbs);
    final totalProtein = entries.fold(0, (s, e) => s + e.protein);
    final totalFat = entries.fold(0, (s, e) => s + e.fat);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: pixelCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + details chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(today, style: AppTextStyles.caption()),
              if (tappable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.coral.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Details', style: AppTextStyles.label(color: AppColors.coral)),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.coral, size: 14),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Big calorie number
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalKcal',
                style: AppTextStyles.number(
                  color: isOverGoal ? AppColors.errorRed : AppColors.darkGray,
                  size: 48,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ $goal kcal',
                  style: AppTextStyles.subheading(color: AppColors.mediumGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Pixel segmented bar
          SegmentedBar(progress: progress, isOver: isOverGoal),
          const SizedBox(height: AppSpacing.xs),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entries.isEmpty
                    ? 'Nothing logged yet'
                    : '${entries.length} item${entries.length == 1 ? '' : 's'} logged',
                style: AppTextStyles.caption(),
              ),
              if (entries.isNotEmpty)
                Text(
                  isOverGoal
                      ? '+${totalKcal - goal} kcal over'
                      : '${goal - totalKcal} kcal left',
                  style: AppTextStyles.label(
                    color: isOverGoal ? AppColors.errorRed : AppColors.successGreen,
                  ),
                ),
            ],
          ),

          // Macro row
          if (entries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(height: 1, color: AppColors.softGray),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroBar(label: 'Protein', value: totalProtein, maxValue: 150, color: AppColors.macroProtein),
                _MacroBar(label: 'Carbs',   value: totalCarbs,   maxValue: 300, color: AppColors.macroCarbs),
                _MacroBar(label: 'Fat',     value: totalFat,     maxValue: 80,  color: AppColors.macroFat),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Macro Bar (pixel segmented, replaces ring) ────────────────────────────────

class _MacroBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    const segments = 5;
    final filled = (progress * segments).ceil().clamp(0, segments);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${value}g',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Row(
            children: List.generate(segments, (i) {
              final isFilled = i < filled;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: 8,
                  decoration: BoxDecoration(
                    color: isFilled ? color : AppColors.softGray,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: isFilled
                          ? color.withValues(alpha: 0.6)
                          : AppColors.mediumGray.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTextStyles.caption()),
      ],
    );
  }
}

// ── History Row ────────────────────────────────────────────────────────────────

class _HistoryRow extends ConsumerWidget {
  final String dateKey;
  final int goal;
  final VoidCallback onTap;

  const _HistoryRow({
    required this.dateKey,
    required this.goal,
    required this.onTap,
  });

  String _formatDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return key;
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final diff = DateTime.now().difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    final label = diff == 1
        ? 'Yesterday'
        : diff == 2
            ? '2 days ago'
            : DateFormat('MMM d').format(dt);
    return '${DateFormat('EEE').format(dt)}, $label';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesForDateProvider(dateKey));
    final totalCals = entries.fold(0, (s, e) => s + e.calories);
    final isOverGoal = totalCals > goal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: pixelCard(),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.coral.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: AppColors.coral, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_formatDateKey(dateKey), style: AppTextStyles.body()),
            ),
            Text(
              '$totalCals kcal',
              style: AppTextStyles.subheading(
                color: isOverGoal ? AppColors.errorRed : AppColors.coral,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, color: AppColors.mediumGray, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Nutrition Dialog ───────────────────────────────────────────────────────────

class NutritionDialog extends StatelessWidget {
  final List<FoodEntry> entries;
  final String dateKey;
  final int goal;
  final String? labelOverride;

  const NutritionDialog({
    super.key,
    required this.entries,
    required this.dateKey,
    required this.goal,
    this.labelOverride,
  });

  String _formatTitle() {
    if (labelOverride != null) return labelOverride!;
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return DateFormat('EEEE, MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final totalCals = entries.fold(0, (s, e) => s + e.calories);
    final totalCarbs = entries.fold(0, (s, e) => s + e.carbs);
    final totalProtein = entries.fold(0, (s, e) => s + e.protein);
    final totalFat = entries.fold(0, (s, e) => s + e.fat);
    final progress = (totalCals / goal).clamp(0.0, 1.0);
    final isOverGoal = totalCals > goal;
    final pct = (progress * 100).round();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatTitle(), style: AppTextStyles.heading()),
            const SizedBox(height: AppSpacing.md),

            // Calorie progress row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalCals / $goal kcal',
                  style: AppTextStyles.body(
                    color: isOverGoal ? AppColors.errorRed : AppColors.darkGray,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOverGoal
                        ? AppColors.errorRed.withValues(alpha: 0.1)
                        : AppColors.coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isOverGoal
                          ? AppColors.errorRed.withValues(alpha: 0.3)
                          : AppColors.coral.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$pct%',
                    style: AppTextStyles.label(
                      color: isOverGoal ? AppColors.errorRed : AppColors.coral,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedBar(progress: progress, isOver: isOverGoal),
            const SizedBox(height: AppSpacing.lg),

            // Macro bars row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroBar(label: 'Protein', value: totalProtein, maxValue: 150, color: AppColors.macroProtein),
                _MacroBar(label: 'Carbs',   value: totalCarbs,   maxValue: 300, color: AppColors.macroCarbs),
                _MacroBar(label: 'Fat',     value: totalFat,     maxValue: 80,  color: AppColors.macroFat),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Food items list
            if (entries.isNotEmpty) ...[
              Text('Items logged', style: AppTextStyles.label()),
              const SizedBox(height: AppSpacing.sm),
              ...entries.take(3).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.foodName, style: AppTextStyles.caption(color: AppColors.darkGray)),
                      ),
                      Text('${e.calories} kcal', style: AppTextStyles.caption()),
                    ],
                  ),
                ),
              ),
              if (entries.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('+ ${entries.length - 3} more', style: AppTextStyles.caption()),
                ),
            ],

            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Done',
                  style: AppTextStyles.body(color: AppColors.coral)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String today;
  const _EmptyState({required this.today});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.coral.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.restaurant_menu_rounded, size: 40, color: AppColors.coral),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Nothing logged yet', style: AppTextStyles.heading()),
          const SizedBox(height: AppSpacing.sm),
          Text(today, style: AppTextStyles.caption()),
          const SizedBox(height: AppSpacing.xs),
          Text('Go to Chat and type what you ate!', style: AppTextStyles.caption()),
        ],
      ),
    );
  }
}

