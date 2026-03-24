import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_entry.dart';
import 'auth_service.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => AuthService.currentUid;

  static Future<void> addFoodEntry(FoodEntry entry) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('food_entries')
        .doc(entry.id)
        .set({
      'foodName': entry.foodName,
      'calories': entry.calories,
      'carbs': entry.carbs,
      'protein': entry.protein,
      'fat': entry.fat,
      'dateKey': entry.dateKey,
      'timestamp': entry.timestamp.toIso8601String(),
      'rawInput': entry.rawInput,
    });
  }

  static Future<void> saveDailyGoal(int goal) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('settings')
        .set({'dailyGoal': goal}, SetOptions(merge: true));
  }

  static Future<List<FoodEntry>> loadAllEntries() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('food_entries')
        .get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return FoodEntry(
        id: doc.id,
        foodName: d['foodName'] as String,
        calories: (d['calories'] as num).toInt(),
        carbs: (d['carbs'] as num?)?.toInt() ?? 0,
        protein: (d['protein'] as num?)?.toInt() ?? 0,
        fat: (d['fat'] as num?)?.toInt() ?? 0,
        timestamp: DateTime.parse(d['timestamp'] as String),
        rawInput: d['rawInput'] as String? ?? '',
      );
    }).toList();
  }

  static Future<int?> loadDailyGoal() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('settings')
        .get();
    if (!doc.exists) return null;
    return (doc.data()?['dailyGoal'] as num?)?.toInt();
  }
}
