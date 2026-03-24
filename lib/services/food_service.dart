import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ── Result types ──────────────────────────────────────────────────────────────

class FoodResult {
  final String foodName;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;

  FoodResult({
    required this.foodName,
    required this.calories,
    this.carbs = 0,
    this.protein = 0,
    this.fat = 0,
  });
}

class FoodServiceResult {
  final List<FoodResult>? items;
  final String? clarifyQuestion;
  final String? error;

  const FoodServiceResult._({this.items, this.clarifyQuestion, this.error});

  factory FoodServiceResult.items(List<FoodResult> items) =>
      FoodServiceResult._(items: items);
  factory FoodServiceResult.clarify(String question) =>
      FoodServiceResult._(clarifyQuestion: question);
  factory FoodServiceResult.error(String message) =>
      FoodServiceResult._(error: message);

  bool get hasItems => items != null && items!.isNotEmpty;
  bool get needsClarification => clarifyQuestion != null;
  bool get hasError => error != null;
}

// ── Service ───────────────────────────────────────────────────────────────────

class FoodService {
  // Replace this with your Vercel URL after deployment
  static const _apiUrl = 'https://calorie-app-virid.vercel.app/api/parse-food';

  static Future<FoodServiceResult> parseInput(
    String input, {
    List<Map<String, String>>? context,
  }) async {
    // Get Firebase ID token to authenticate with Vercel backend
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return FoodServiceResult.error('Not signed in.');
    }

    String idToken;
    try {
      idToken = await user.getIdToken() ?? '';
    } catch (_) {
      return FoodServiceResult.error('Authentication error. Please sign in again.');
    }

    final body = context != null
        ? jsonEncode({'messages': context})
        : jsonEncode({'input': input});

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      return FoodServiceResult.error('Network error. Check your connection.');
    }

    if (response.statusCode == 429) {
      final errBody = jsonDecode(response.body) as Map<String, dynamic>;
      return FoodServiceResult.error(errBody['error'] ?? 'Daily limit reached. Try again tomorrow.');
    }

    if (response.statusCode != 200) {
      return FoodServiceResult.error('Server error. Please try again.');
    }

    final respBody = jsonDecode(response.body) as Map<String, dynamic>;
    final resultStr = respBody['result'] as String;

    dynamic parsed;
    try {
      parsed = jsonDecode(resultStr);
    } catch (_) {
      return FoodServiceResult.error('Unexpected response. Please try again.');
    }

    // Claude returned a clarify question
    if (parsed is Map && parsed.containsKey('clarify')) {
      return FoodServiceResult.clarify(parsed['clarify'] as String);
    }

    // Claude returned a list of food items
    if (parsed is List && parsed.isNotEmpty) {
      final items = parsed.map((item) {
        return FoodResult(
          foodName: item['name'] as String? ?? 'Unknown',
          calories: (item['calories'] as num?)?.toInt() ?? 0,
          carbs: (item['carbs'] as num?)?.toInt() ?? 0,
          protein: (item['protein'] as num?)?.toInt() ?? 0,
          fat: (item['fat'] as num?)?.toInt() ?? 0,
        );
      }).toList();
      return FoodServiceResult.items(items);
    }

    return FoodServiceResult.error("I couldn't identify that food. Try being more specific.");
  }
}
