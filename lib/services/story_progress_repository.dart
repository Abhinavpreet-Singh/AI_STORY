import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_story_progress.dart';

class StoryProgressRepository {
  static const _key = 'story_progress';

  SavedStoryProgress? _cached;

  SavedStoryProgress? get current => _cached;

  Future<SavedStoryProgress?> load() async {
    if (_cached != null) return _cached;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    _cached = SavedStoryProgress.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    return _cached;
  }

  Future<void> save(SavedStoryProgress progress) async {
    _cached = progress;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }

  Future<void> clear() async {
    _cached = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
