import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/food_entry.dart';
import '../models/chat_message.dart';
import '../services/food_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

const _uuid = Uuid();

// ── Source of truth: ALL entries ever logged ─────────────────────────────────

class AllFoodEntriesNotifier extends Notifier<List<FoodEntry>> {
  @override
  List<FoodEntry> build() => StorageService.getAllEntries();

  Future<void> addEntry(FoodEntry entry) async {
    await StorageService.addFoodEntry(entry);
    state = [...state, entry];
    // Sync to Firestore in background — no-op if not logged in
    FirestoreService.addFoodEntry(entry).catchError((_) {});
  }

  Future<void> loadFromFirestore() async {
    final entries = await FirestoreService.loadAllEntries();
    for (final entry in entries) {
      await StorageService.addFoodEntry(entry);
    }
    state = StorageService.getAllEntries();
  }

  Future<void> clearAll() async {
    await StorageService.clearAllEntries();
    state = [];
  }
}

final allFoodEntriesProvider =
    NotifierProvider<AllFoodEntriesNotifier, List<FoodEntry>>(
        AllFoodEntriesNotifier.new);

// ── Today's entries (derived) ─────────────────────────────────────────────────

final foodEntriesProvider = Provider<List<FoodEntry>>((ref) {
  final all = ref.watch(allFoodEntriesProvider);
  final today = StorageService.todayKey();
  return all.where((e) => e.dateKey == today).toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
});

// ── Today's total calories ────────────────────────────────────────────────────

final todayCaloriesProvider = Provider<int>((ref) {
  return ref.watch(foodEntriesProvider).fold(0, (sum, e) => sum + e.calories);
});

// ── All distinct date keys that have ≥1 entry ─────────────────────────────────

final datesWithEntriesProvider = Provider<Set<String>>((ref) {
  return ref.watch(allFoodEntriesProvider).map((e) => e.dateKey).toSet();
});

// ── Sorted list of dates (newest first) ──────────────────────────────────────

final daysWithEntriesProvider = Provider<List<String>>((ref) {
  final dates = ref.watch(datesWithEntriesProvider).toList();
  dates.sort((a, b) => b.compareTo(a));
  return dates;
});

// ── Streak: consecutive logged days going backwards from today ────────────────

final streakProvider = Provider<int>((ref) {
  return _calculateStreak(ref.watch(datesWithEntriesProvider));
});

int _calculateStreak(Set<String> dates) {
  if (dates.isEmpty) return 0;

  final today = DateTime.now();
  DateTime checkDate = today;

  // If today has no entry, start streak check from yesterday
  if (!dates.contains(_dateKey(checkDate))) {
    checkDate = today.subtract(const Duration(days: 1));
    if (!dates.contains(_dateKey(checkDate))) return 0;
  }

  int streak = 0;
  while (dates.contains(_dateKey(checkDate))) {
    streak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
  }
  return streak;
}

String _dateKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

// ── Entries for a specific date (family provider) ─────────────────────────────

final entriesForDateProvider =
    Provider.family<List<FoodEntry>, String>((ref, dateKey) {
  return ref
      .watch(allFoodEntriesProvider)
      .where((e) => e.dateKey == dateKey)
      .toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
});

// ── Daily goal ────────────────────────────────────────────────────────────────

class DailyGoalNotifier extends Notifier<int> {
  @override
  int build() => StorageService.dailyGoal;

  Future<void> setGoal(int goal) async {
    await StorageService.setDailyGoal(goal);
    state = goal;
    FirestoreService.saveDailyGoal(goal).catchError((_) {});
  }

  Future<void> loadGoalFromFirestore() async {
    final goal = await FirestoreService.loadDailyGoal();
    if (goal != null) {
      await StorageService.setDailyGoal(goal);
      state = goal;
    }
  }
}

final dailyGoalProvider =
    NotifierProvider<DailyGoalNotifier, int>(DailyGoalNotifier.new);

// ── Chat ──────────────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<List<ChatMessage>> {
  // Accumulates full conversation context across clarification rounds
  List<Map<String, String>> _conversationContext = [];

  @override
  List<ChatMessage> build() => [
        ChatMessage(
          text:
              "Hey! Tell me what you ate and I'll track the calories for you.",
          type: MessageType.bot,
          timestamp: DateTime.now(),
        ),
      ];

  Future<void> sendMessage(String input, WidgetRef ref) async {
    state = [
      ...state,
      ChatMessage(
        text: input,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    ];

    FoodServiceResult result;
    if (_conversationContext.isNotEmpty) {
      final context = [
        ..._conversationContext,
        {'role': 'user', 'content': input},
      ];
      result = await FoodService.parseInput(input, context: context);
    } else {
      result = await FoodService.parseInput(input);
    }

    if (result.hasError) {
      _conversationContext = [];
      state = [
        ...state,
        ChatMessage(
          text: result.error!,
          type: MessageType.error,
          timestamp: DateTime.now(),
        ),
      ];
      return;
    }

    if (result.needsClarification) {
      _conversationContext = [
        ..._conversationContext,
        {'role': 'user', 'content': input},
        {'role': 'assistant', 'content': result.clarifyQuestion!},
      ];
      state = [
        ...state,
        ChatMessage(
          text: result.clarifyQuestion!,
          type: MessageType.clarify,
          timestamp: DateTime.now(),
        ),
      ];
      return;
    }

    if (result.hasItems) {
      _conversationContext = [];
      final items = result.items!;
      for (final item in items) {
        final entry = FoodEntry(
          id: _uuid.v4(),
          foodName: item.foodName,
          calories: item.calories,
          carbs: item.carbs,
          protein: item.protein,
          fat: item.fat,
          timestamp: DateTime.now(),
          rawInput: input,
        );
        await ref.read(allFoodEntriesProvider.notifier).addEntry(entry);
      }

      final totalCals = items.fold(0, (sum, r) => sum + r.calories);
      String botText;
      if (items.length == 1) {
        botText =
            "Got it! ${items[0].foodName} is around ${items[0].calories} kcal. Added to your daily total!";
      } else {
        final lines =
            items.map((r) => '${r.foodName} → ${r.calories} kcal').join('\n');
        botText = "$lines\n\nTotal: $totalCals kcal added to your day!";
      }

      state = [
        ...state,
        ChatMessage(
          text: botText,
          type: MessageType.bot,
          timestamp: DateTime.now(),
          calories: totalCals,
        ),
      ];
      return;
    }

    state = [
      ...state,
      ChatMessage(
        text: "I couldn't identify that food. Try being more specific.",
        type: MessageType.error,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

final chatProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);
