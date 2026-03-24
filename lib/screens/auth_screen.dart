import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/food_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;
  String? _successMessage;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _goalCtrl = TextEditingController(text: '2000');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _switchMode(bool isLogin) {
    setState(() {
      _isLogin = isLogin;
      _error = null;
      _successMessage = null;
    });
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    if (!_isLogin) {
      final goal = int.tryParse(_goalCtrl.text.trim());
      if (goal == null || goal < 500 || goal > 10000) {
        setState(() => _error = 'Goal must be between 500 and 10,000 kcal');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      if (_isLogin) {
        final cred = await AuthService.signIn(email, password);
        if (cred.user?.emailVerified == false) {
          await AuthService.signOut();
          setState(() => _error = 'Please verify your email first. Check your inbox for the verification link.');
          return;
        }
        await ref.read(allFoodEntriesProvider.notifier).loadFromFirestore();
        await ref.read(dailyGoalProvider.notifier).loadGoalFromFirestore();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        await AuthService.signUp(email, password);
        final goal = int.parse(_goalCtrl.text.trim());
        await ref.read(dailyGoalProvider.notifier).setGoal(goal);
        await AuthService.signOut();
        if (mounted) {
          setState(() {
            _isLogin = true;
            _successMessage = 'Verification email sent to $email. Click the link then log in.';
            _emailCtrl.clear();
            _passwordCtrl.clear();
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    try {
      final result = await AuthService.signInWithGoogle();
      if (result == null) {
        // User cancelled
        setState(() => _googleLoading = false);
        return;
      }

      final isNewUser = result.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // New Google user — ask for calorie goal
        if (mounted) {
          final goal = await _showGoalDialog();
          if (goal != null) {
            await ref.read(dailyGoalProvider.notifier).setGoal(goal);
          }
        }
      } else {
        // Returning user — load their data
        await ref.read(allFoodEntriesProvider.notifier).loadFromFirestore();
        await ref.read(dailyGoalProvider.notifier).loadGoalFromFirestore();
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (_) {
      setState(() => _error = 'Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<int?> _showGoalDialog() {
    final ctrl = TextEditingController(text: '2000');
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
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
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Daily calorie goal',
                suffixText: 'kcal',
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val >= 500 && val <= 10000) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('Start Tracking'),
          ),
        ],
      ),
    );
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Something went wrong. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final anyLoading = _loading || _googleLoading;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Logo + title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nibble',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGray,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track calories by just typing',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Google sign-in button
              _GoogleButton(
                loading: _googleLoading,
                disabled: anyLoading,
                onTap: _googleSignIn,
              ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.softGray)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.softGray)),
                ],
              ),

              const SizedBox(height: 20),

              // Mode toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _ToggleTab(
                      label: 'Log In',
                      selected: _isLogin,
                      onTap: () => _switchMode(true),
                    ),
                    _ToggleTab(
                      label: 'Sign Up',
                      selected: !_isLogin,
                      onTap: () => _switchMode(false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form fields
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                textInputAction:
                    _isLogin ? TextInputAction.done : TextInputAction.next,
                onSubmitted: _isLogin ? (_) => _submit() : null,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),

              // Goal field (signup only)
              if (!_isLogin) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _goalCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Daily calorie goal',
                    prefixIcon: Icon(Icons.flag_outlined),
                    suffixText: 'kcal',
                  ),
                ),
              ],

              // Success message
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.mint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.mint.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _successMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.mint,
                    ),
                  ),
                ),
              ],

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.errorRed,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: anyLoading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(_isLogin ? 'Log In' : 'Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google Button ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const _GoogleButton({
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.softGray, width: 1.5),
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.coral,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google G logo using colored text
                    _GoogleLogo(),
                    const SizedBox(width: 10),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the colored arcs (Google G)
    final colors = [
      const Color(0xFF4285F4), // blue  — top
      const Color(0xFFEA4335), // red   — top-left
      const Color(0xFFFBBC05), // yellow — bottom-left
      const Color(0xFF34A853), // green  — bottom-right
    ];
    final sweeps = [
      const [0.0, 90.0],   // blue: right to bottom
      const [90.0, 90.0],  // red: bottom to left
      const [180.0, 90.0], // yellow: left to top
      const [270.0, 90.0], // green: top to right
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22;

      final startAngle = sweeps[i][0] * 3.14159265 / 180;
      final sweepAngle = sweeps[i][1] * 3.14159265 / 180;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // White cutout on the right to form the "G" gap
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - size.height * 0.12,
          size.width * 0.55, size.height * 0.24),
      whitePaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Toggle Tab ────────────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.darkGray : AppColors.mediumGray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
