import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'summary_screen.dart';
import 'streak_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ChatScreen(),
    SummaryScreen(),
    StreakScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.coral,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Nibble',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            color: AppColors.darkGray,
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const SettingsBottomSheet(),
            ),
          ),
        ],
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.softGray),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.coral.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.coral),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.coral),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department_rounded, color: AppColors.coral),
            label: 'Streak',
          ),
        ],
      ),
    );
  }
}
