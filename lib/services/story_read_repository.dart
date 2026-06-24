import 'package:shared_preferences/shared_preferences.dart';

class StoryReadRepository {
  static const _key = 'read_story_ids';

  Set<String> _readIds = {};

  Set<String> get readIds => Set.unmodifiable(_readIds);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _readIds = (prefs.getStringList(_key) ?? []).toSet();
  }

  bool isRead(String storyId) => _readIds.contains(storyId);

  Future<void> markRead(String storyId) async {
    if (_readIds.contains(storyId)) return;
    _readIds = {..._readIds, storyId};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _readIds.toList());
  }

  Future<void> clearAll() async {
    _readIds = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
