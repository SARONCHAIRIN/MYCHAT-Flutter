import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api.dart';

final appPreferencesProvider = StateNotifierProvider<AppPreferencesController, AppPreferences>((ref) {
  return AppPreferencesController()..restore();
});

class AppPreferences {
  final ThemeMode themeMode;
  final String languageCode;
  const AppPreferences({this.themeMode = ThemeMode.system, this.languageCode = 'en'});
  AppPreferences copyWith({ThemeMode? themeMode, String? languageCode}) =>
      AppPreferences(themeMode: themeMode ?? this.themeMode, languageCode: languageCode ?? this.languageCode);
}

class AppPreferencesController extends StateNotifier<AppPreferences> {
  AppPreferencesController() : super(const AppPreferences());
  Future<void> restore() async {
    final theme = await secureStorage.read(key: 'mychat_theme');
    final language = await secureStorage.read(key: 'mychat_language');
    state = AppPreferences(
      themeMode: theme == 'dark' ? ThemeMode.dark : theme == 'light' ? ThemeMode.light : ThemeMode.system,
      languageCode: language == 'km' ? 'km' : 'en',
    );
  }
  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await secureStorage.write(key: 'mychat_theme', value: mode.name);
  }
  Future<void> setLanguage(String language) async {
    if (language != 'en' && language != 'km') return;
    state = state.copyWith(languageCode: language);
    await secureStorage.write(key: 'mychat_language', value: language);
  }
}

const translations = <String, Map<String, String>>{
  'Chats': {'km': 'ការជជែក'},
  'Contacts': {'km': 'ទំនាក់ទំនង'},
  'Notifications': {'km': 'ការជូនដំណឹង'},
  'Alerts': {'km': 'ដំណឹង'},
  'Profile': {'km': 'ប្រវត្តិរូប'},
  'My profile': {'km': 'ប្រវត្តិរូបខ្ញុំ'},
  'No notifications': {'km': 'មិនមានការជូនដំណឹង'},
  'New activity will show up here.': {'km': 'សកម្មភាពថ្មីនឹងបង្ហាញនៅទីនេះ។'},
  'Mark all as read': {'km': 'សម្គាល់ថាបានអានទាំងអស់'},
  'Refresh': {'km': 'ផ្ទុកឡើងវិញ'},
  'Retry': {'km': 'សាកល្បងម្ដងទៀត'},
  'Settings & privacy': {'km': 'ការកំណត់ និងឯកជនភាព'},
  'Appearance & language': {'km': 'រូបរាង និងភាសា'},
  'Theme': {'km': 'រូបរាង'},
  'Language': {'km': 'ភាសា'},
  'System': {'km': 'តាមប្រព័ន្ធ'},
  'Light': {'km': 'ភ្លឺ'},
  'Dark': {'km': 'ងងឹត'},
  'English': {'km': 'អង់គ្លេស'},
  'Khmer': {'km': 'ខ្មែរ'},
};
String tr(String key, String lang) {
  if (lang == 'km') {
    return translations[key]?['km'] ?? key;
  }

  return key;
}