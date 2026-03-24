import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    Future.delayed(const Duration(milliseconds: 1500), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final user = AuthService.currentUser;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            user != null ? const MainScreen() : const AuthScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.coral,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 60,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Nibble',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track calories by just typing',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
