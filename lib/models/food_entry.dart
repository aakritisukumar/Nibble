import 'package:hive/hive.dart';

part 'food_entry.g.dart';

@HiveType(typeId: 0)
class FoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String foodName;

  @HiveField(2)
  final int calories;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String rawInput;

  @HiveField(5)
  final int carbs;

  @HiveField(6)
  final int protein;

  @HiveField(7)
  final int fat;

  FoodEntry({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.timestamp,
    required this.rawInput,
    this.carbs = 0,
    this.protein = 0,
    this.fat = 0,
  });

  String get dateKey {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }
}
