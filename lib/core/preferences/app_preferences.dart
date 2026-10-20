import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api.dart';

String activeLanguageCode = 'en';
String t(String key) => tr(key, activeLanguageCode);

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
    activeLanguageCode = language == 'km' ? 'km' : 'en';
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
    activeLanguageCode = language;
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
  'All chats': {'km': 'ការជជែកទាំងអស់'},
  'All': {'km': 'ទាំងអស់'},
  'Unread': {'km': 'មិនទាន់អាន'},
  'Groups': {'km': 'ក្រុម'},
  'Direct': {'km': 'ផ្ទាល់'},
  'No messages yet': {'km': 'មិនទាន់មានសារ'},
  'No contacts found': {'km': 'រកមិនឃើញទំនាក់ទំនង'},
  'No conversations found': {'km': 'រកមិនឃើញការជជែក'},
  'Load more': {'km': 'បង្ហាញបន្ថែម'},
  'Search': {'km': 'ស្វែងរក'},
  'Search contacts or @username': {'km': 'ស្វែងរកទំនាក់ទំនង ឬ @username'},
  'Settings': {'km': 'ការកំណត់'},
  'Account': {'km': 'គណនី'},
  'Username': {'km': 'ឈ្មោះអ្នកប្រើ'},
  'Name': {'km': 'ឈ្មោះ'},
  'Bio': {'km': 'ប្រវត្តិខ្លី'},
  'Save': {'km': 'រក្សាទុក'},
  'SAVE': {'km': 'រក្សាទុក'},
  'online': {'km': 'អនឡាញ'},
  'Log out': {'km': 'ចាកចេញ'},
  'Blocked users': {'km': 'អ្នកប្រើដែលបានទប់ស្កាត់'},
  'New': {'km': 'ថ្មី'},
  'No notifications yet': {'km': 'មិនទាន់មានការជូនដំណឹង'},
  'Delete': {'km': 'លុប'},
  'Members': {'km': 'សមាជិក'},
  'members': {'km': 'សមាជិក'},
  'Open messages': {'km': 'បើកសារ'},
  'Privacy': {'km': 'ឯកជនភាព'},
  'Cancel': {'km': 'បោះបង់'},
  'Done': {'km': 'រួចរាល់'},
  'Edit': {'km': 'កែប្រែ'},
  'Create group': {'km': 'បង្កើតក្រុម'},
  'New group': {'km': 'ក្រុមថ្មី'},
  'Search conversations': {'km': 'ស្វែងរកការជជែក'},
  'No results': {'km': 'គ្មានលទ្ធផល'},
  'New message': {'km': 'សារថ្មី'},
  'You received a new message': {'km': 'អ្នកបានទទួលសារថ្មី'},
  'Today': {'km': 'ថ្ងៃនេះ'},
  'Yesterday': {'km': 'ម្សិលមិញ'},
  'Mark as read': {'km': 'សម្គាល់ថាបានអាន'},
  'unread': {'km': 'មិនទាន់អាន'},
  'Appearance': {'km': 'រូបរាង'},
  'Language & appearance': {'km': 'ភាសា និងរូបរាង'},
  'Profile updated': {'km': 'បានកែប្រែប្រវត្តិរូប'},
  'Chat': {'km': 'ការជជែក'},
  'Notifications history': {'km': 'ប្រវត្តិការជូនដំណឹង'},
  'Color theme': {'km': 'ពណ៌កម្មវិធី'},
  'Notifications and sounds': {'km': 'ការជូនដំណឹង និងសំឡេង'},
  'These options are view-only for now. Editing will be available soon.': {'km': 'ជម្រើសទាំងនេះអាចមើលបានតែប៉ុណ្ណោះ។'},
};
String tr(String key, String lang) {
  if (lang == 'km') {
    return translations[key]?['km'] ?? key;
  }

  return key;
}