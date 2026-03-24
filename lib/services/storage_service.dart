import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_entry.dart';

class StorageService {
  static const String _foodBoxName = 'food_entries';
  static const String _settingsBoxName = 'settings';

  static Box<FoodEntry>? _foodBox;
  static Box? _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FoodEntryAdapter());
    _foodBox = await Hive.openBox<FoodEntry>(_foodBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  static Box<FoodEntry> get foodBox => _foodBox!;
  static Box get settingsBox => _settingsBox!;

  // Food entries
  static Future<void> addFoodEntry(FoodEntry entry) async {
    await _foodBox!.put(entry.id, entry);
  }

  static List<FoodEntry> getAllEntries() => _foodBox!.values.toList();

  static Future<void> clearAllEntries() => _foodBox!.clear();

  static List<FoodEntry> getTodayEntries() {
    final today = todayKey();
    return _foodBox!.values
        .where((e) => e.dateKey == today)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static int getTodayCalories() {
    return getTodayEntries().fold(0, (sum, e) => sum + e.calories);
  }

  // Settings
  static bool get isFirstLaunch =>
      _settingsBox!.get('firstLaunch', defaultValue: true) as bool;
  static Future<void> setFirstLaunchDone() =>
      _settingsBox!.put('firstLaunch', false);

  static int get dailyGoal =>
      _settingsBox!.get('dailyGoal', defaultValue: 2000) as int;
  static Future<void> setDailyGoal(int goal) =>
      _settingsBox!.put('dailyGoal', goal);

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
