import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../providers/food_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputCtrl.clear();
    setState(() => _isSending = true);

    await ref.read(chatProvider.notifier).sendMessage(text, ref);

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  String _moodLabel(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return 'Looking good today!';
      case PetMood.neutral:
        return 'Keeping it balanced';
      case PetMood.worried:
        return 'Getting close to your goal...';
      case PetMood.sad:
        return 'Over your goal today';
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final todayKcal = ref.watch(todayCaloriesProvider);
    final goal = ref.watch(dailyGoalProvider);

    ref.listen(chatProvider, (prev, next) => _scrollToBottom());

    final progress = (todayKcal / goal).clamp(0.0, 1.0);
    final isOverGoal = todayKcal > goal;

    PetMood mood;
    if (isOverGoal) {
      mood = PetMood.sad;
    } else if (progress >= 0.9) {
      mood = PetMood.worried;
    } else if (progress >= 0.6) {
      mood = PetMood.neutral;
    } else {
      mood = PetMood.happy;
    }

    return Column(
      children: [
        // ── Daily counter banner ───────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.softGray, width: 1.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today',
                    style: AppTextStyles.label(),
                  ),
                  Text(
                    'Goal: $goal kcal',
                    style: AppTextStyles.caption(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$todayKcal',
                    style: AppTextStyles.number(
                      color: isOverGoal ? AppColors.errorRed : AppColors.darkGray,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text('kcal', style: AppTextStyles.body(color: AppColors.mediumGray)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverGoal
                          ? AppColors.errorRed.withValues(alpha: 0.1)
                          : AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isOverGoal
                            ? AppColors.errorRed.withValues(alpha: 0.25)
                            : AppColors.successGreen.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isOverGoal
                          ? '+${todayKcal - goal} over'
                          : '${goal - todayKcal} left',
                      style: AppTextStyles.label(
                        color: isOverGoal ? AppColors.errorRed : AppColors.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SegmentedBar(progress: progress, isOver: isOverGoal),
            ],
          ),
        ),

        // ── Messages / Bunny area ──────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              // Bunny always visible as background
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: messages.isEmpty ? 1.0 : 0.18,
                    child: PixelBunny(mood: mood),
                  ),
                ),
              ),

              // Empty-state text (only when no messages)
              if (messages.isEmpty)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        _moodLabel(mood),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subheading(),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Type a meal below to log it',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                ),

              // Message list (on top of bunny)
              if (messages.isNotEmpty)
                ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
                ),
            ],
          ),
        ),

        // ── Input row ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(color: AppColors.softGray, width: 1.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  onSubmitted: (_) => _send(),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'What did you eat?',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _isSending
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                    )
                  : Material(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: _send,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pixel Bunny ───────────────────────────────────────────────────────────────

enum PetMood { happy, neutral, worried, sad }

class PixelBunny extends StatefulWidget {
  final PetMood mood;
  const PixelBunny({super.key, required this.mood});

  @override
  State<PixelBunny> createState() => _PixelBunnyState();
}

class _PixelBunnyState extends State<PixelBunny>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _bounceAnim;
  bool _blinking = false;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bounce, curve: Curves.easeInOut),
    );
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 3000 + Random().nextInt(3000)),
      () {
        if (!mounted) return;
        setState(() => _blinking = true);
        Timer(const Duration(milliseconds: 130), () {
          if (!mounted) return;
          setState(() => _blinking = false);
          _scheduleBlink();
        });
      },
    );
  }

  @override
  void dispose() {
    _bounce.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context2, child) => Transform.translate(
        offset: Offset(0, _bounceAnim.value),
        child: CustomPaint(
          size: const Size(130, 180),
          painter: _BunnyPainter(mood: widget.mood, blinking: _blinking),
        ),
      ),
    );
  }
}

// ── Bunny Painter ─────────────────────────────────────────────────────────────
//
// 13 columns × 18 rows grid.  Each cell = size.width / 13.
// Color codes:
//   0 = transparent   1 = outline #3D3D3D
//   2 = cream #FEFEF2  3 = ear-pink #FFB3C6
//   4 = blush #FFCDD5  5 = nose #C9956C   6 = eye (same dark as outline)

class _BunnyPainter extends CustomPainter {
  final PetMood mood;
  final bool blinking;

  const _BunnyPainter({required this.mood, required this.blinking});

  static const _dark  = Color(0xFF3D3D3D);
  static const _cream = Color(0xFFFEFEF2);
  static const _pink  = Color(0xFFFFB3C6);
  static const _blush = Color(0xFFFFCDD5);
  static const _nose  = Color(0xFFC9956C);

  Color _color(int v) {
    switch (v) {
      case 1: return _dark;
      case 2: return _cream;
      case 3: return _pink;
      case 4: return _blush;
      case 5: return _nose;
      default: return _dark; // 6 = eye
    }
  }

  List<List<int>> get _buildGrid {
    final g = <List<int>>[
      [0,0,1,2,1,0,0,0,1,2,1,0,0],  // 0  ear tips (3-cell: outline+cream+outline)
      [0,0,1,3,1,0,0,0,1,3,1,0,0],  // 1  pink visible from top
      [0,0,1,3,1,0,0,0,1,3,1,0,0],  // 2  pink ear upper
      [0,1,2,3,2,1,0,1,2,3,2,1,0],  // 3  ears widen (5-cell with gap)
      [0,1,2,3,2,1,0,1,2,3,2,1,0],  // 4  ear mid
      [0,1,2,3,2,1,0,1,2,3,2,1,0],  // 5  ear base
      [0,0,1,2,2,2,1,2,2,2,1,0,0],  // 6  ear→head (gap closes to center outline)
      [0,1,2,2,2,2,2,2,2,2,2,1,0],  // 7  head top
      [1,2,2,2,2,2,2,2,2,2,2,2,1],  // 8  head
      [1,2,2,2,6,2,2,2,6,2,2,2,1],  // 9  eyes  (replaced below)
      [1,2,2,4,2,2,5,2,2,4,2,2,1],  // 10 blush + nose
      [1,2,2,2,2,2,2,2,2,2,2,2,1],  // 11 mouth (replaced below)
      [1,2,2,2,2,2,2,2,2,2,2,2,1],  // 12 body
      [0,1,2,2,2,2,2,2,2,2,2,1,0],  // 13
      [0,1,2,2,2,2,2,2,2,2,2,1,0],  // 14
      [0,0,1,1,2,2,0,2,2,1,1,0,0],  // 15 feet start
      [0,0,1,2,2,1,0,1,2,2,1,0,0],  // 16 feet
      [0,0,0,1,1,0,0,0,1,1,0,0,0],  // 17 foot tips
    ];

    if (blinking) {
      g[9] = [1,2,2,2,2,2,2,2,2,2,2,2,1]; // eyes closed
      return g;
    }

    switch (mood) {
      case PetMood.happy:
        g[9]  = [1,2,2,2,6,2,2,2,6,2,2,2,1]; // dot eyes
        g[11] = [1,2,2,2,2,6,2,6,2,2,2,2,1]; // smile
        break;
      case PetMood.neutral:
        g[9]  = [1,2,2,2,6,2,2,2,6,2,2,2,1]; // dot eyes
        break;
      case PetMood.worried:
        g[9]  = [1,2,2,6,6,2,2,2,6,6,2,2,1]; // wide alarmed eyes
        g[11] = [1,2,2,2,2,2,6,2,2,2,2,2,1]; // uncertain dot
        break;
      case PetMood.sad:
        g[9]  = [1,2,2,6,2,6,2,6,2,6,2,2,1]; // X eyes
        g[11] = [1,2,2,2,6,2,2,2,6,2,2,2,1]; // sad mouth
        break;
    }

    return g;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ps = size.width / 13;
    final grid = _buildGrid;

    for (int r = 0; r < 18; r++) {
      for (int c = 0; c < 13; c++) {
        final v = grid[r][c];
        if (v == 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(c * ps, r * ps, ps, ps),
          Paint()..color = _color(v),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BunnyPainter o) =>
      o.mood != mood || o.blinking != blinking;
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isError = message.type == MessageType.error;
    final isClarify = message.type == MessageType.clarify;

    // Icon widget for bot-side messages
    Widget? leadingIcon;
    if (!isUser) {
      final iconColor = isClarify
          ? AppColors.macroFat
          : isError
              ? AppColors.errorRed
              : AppColors.mint;
      final bgColor = isClarify
          ? AppColors.macroFat.withValues(alpha: 0.15)
          : isError
              ? AppColors.errorRed.withValues(alpha: 0.1)
              : AppColors.mint.withValues(alpha: 0.15);
      final borderColor = isClarify
          ? AppColors.macroFat.withValues(alpha: 0.5)
          : isError
              ? AppColors.errorRed.withValues(alpha: 0.3)
              : AppColors.mint.withValues(alpha: 0.4);
      leadingIcon = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Icon(
          isClarify ? Icons.help_outline_rounded : Icons.bolt_rounded,
          size: 18,
          color: iconColor,
        ),
      );
    }

    // Bubble colors
    Color bubbleBg;
    Color? bubbleTextColor;
    Border? bubbleBorder;
    List<BoxShadow>? bubbleShadow;

    if (isUser) {
      bubbleBg = AppColors.coral;
      bubbleTextColor = AppColors.white;
      bubbleShadow = [
        BoxShadow(
          color: AppColors.coral.withValues(alpha: 0.4),
          blurRadius: 0,
          offset: const Offset(2, 2),
        ),
      ];
    } else if (isError) {
      bubbleBg = AppColors.errorRed.withValues(alpha: 0.08);
      bubbleTextColor = AppColors.errorRed;
      bubbleBorder = Border.all(color: AppColors.errorRed.withValues(alpha: 0.3));
    } else if (isClarify) {
      bubbleBg = AppColors.macroFat.withValues(alpha: 0.12);
      bubbleTextColor = AppColors.darkGray;
      bubbleBorder = Border.all(
        color: AppColors.macroFat.withValues(alpha: 0.5),
        width: 1.5,
      );
      bubbleShadow = [
        BoxShadow(
          color: AppColors.macroFat.withValues(alpha: 0.25),
          blurRadius: 0,
          offset: const Offset(2, 2),
        ),
      ];
    } else {
      bubbleBg = AppColors.white;
      bubbleTextColor = AppColors.darkGray;
      bubbleBorder = Border.all(
        color: AppColors.darkGray.withValues(alpha: 0.12),
        width: 1.5,
      );
      bubbleShadow = [
        BoxShadow(
          color: AppColors.darkGray.withValues(alpha: 0.12),
          blurRadius: 0,
          offset: const Offset(2, 2),
        ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            leadingIcon!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: Radius.circular(isUser ? 8 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 8),
                ),
                border: bubbleBorder,
                boxShadow: bubbleShadow,
              ),
              child: Text(
                message.text,
                style: AppTextStyles.body(color: bubbleTextColor)
                    .copyWith(fontSize: 15, height: 1.4),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
