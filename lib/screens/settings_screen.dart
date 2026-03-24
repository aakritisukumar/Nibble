import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/food_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class SettingsBottomSheet extends ConsumerStatefulWidget {
  const SettingsBottomSheet({super.key});

  @override
  ConsumerState<SettingsBottomSheet> createState() =>
      _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends ConsumerState<SettingsBottomSheet> {
  bool _editingGoal = false;
  late TextEditingController _goalCtrl;

  @override
  void initState() {
    super.initState();
    _goalCtrl = TextEditingController(
        text: ref.read(dailyGoalProvider).toString());
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final val = int.tryParse(_goalCtrl.text.trim());
    if (val == null || val < 500 || val > 10000) return;
    await ref.read(dailyGoalProvider.notifier).setGoal(val);
    setState(() => _editingGoal = false);
  }

  Future<void> _signOut() async {
    Navigator.of(context).pop(); // close bottom sheet
    await ref.read(allFoodEntriesProvider.notifier).clearAll();
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentEmail ?? '';
    final goal = ref.watch(dailyGoalProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.softGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Profile',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 20),

          // Email
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Account',
            value: email,
          ),
          const SizedBox(height: 4),
          const Divider(color: AppColors.softGray),
          const SizedBox(height: 4),

          // Daily Goal
          if (!_editingGoal)
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag_outlined,
                      color: AppColors.coral, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Goal',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.mediumGray)),
                      Text('$goal kcal',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _editingGoal = true),
                  child: Text('Edit',
                      style: GoogleFonts.inter(
                          color: AppColors.coral, fontWeight: FontWeight.w600)),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _goalCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onSubmitted: (_) => _saveGoal(),
                    decoration: const InputDecoration(
                      labelText: 'Daily calorie goal',
                      suffixText: 'kcal',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveGoal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),

          const SizedBox(height: 4),
          const Divider(color: AppColors.softGray),
          const SizedBox(height: 8),

          // Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.errorRed, size: 18),
              label: Text('Sign Out',
                  style: GoogleFonts.inter(
                      color: AppColors.errorRed, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppColors.errorRed.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.mint, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.mediumGray)),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray)),
          ],
        ),
      ],
    );
  }
}
