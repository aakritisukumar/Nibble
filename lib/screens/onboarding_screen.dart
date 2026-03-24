import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../providers/food_provider.dart';
import 'main_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Track by Typing',
      description:
          'Just type what you ate — "KFC Zinger burger" or "banana and coffee" — and we handle the rest.',
      accentColor: AppColors.coral,
    ),
    _OnboardingPage(
      icon: Icons.bolt_rounded,
      title: 'Instant Calorie Estimates',
      description:
          'Get calorie info in seconds. No searching through databases or picking portion sizes.',
      accentColor: AppColors.mint,
    ),
    _OnboardingPage(
      icon: Icons.bar_chart_rounded,
      title: 'See Your Daily Total',
      description:
          'A live calorie counter keeps you on track throughout the day. Check your summary anytime.',
      accentColor: AppColors.coral,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showGoalDialog();
    }
  }

  void _showGoalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _GoalDialog(
        onConfirm: (goal) async {
          await ref.read(dailyGoalProvider.notifier).setGoal(goal);
          await StorageService.setFirstLaunchDone();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _showGoalDialog,
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    color: AppColors.mediumGray,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Dots
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                activeDotColor: AppColors.coral,
                dotColor: AppColors.softGray,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
              ),
            ),

            const SizedBox(height: 32),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 56,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGray,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.mediumGray,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GoalDialog extends StatefulWidget {
  final void Function(int goal) onConfirm;

  const _GoalDialog({required this.onConfirm});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final TextEditingController _ctrl = TextEditingController(text: '2000');
  String? _error;

  void _confirm() {
    final val = int.tryParse(_ctrl.text.trim());
    if (val == null || val < 500 || val > 10000) {
      setState(() => _error = 'Enter a number between 500 and 10,000');
      return;
    }
    widget.onConfirm(val);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.white,
      title: Text(
        'Set Your Daily Goal',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.darkGray,
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many calories do you want to eat per day?',
            style: GoogleFonts.inter(
              color: AppColors.mediumGray,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Daily calorie goal',
              suffixText: 'kcal',
              errorText: _error,
            ),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: _confirm,
          child: const Text('Start Tracking'),
        ),
      ],
    );
  }
}
