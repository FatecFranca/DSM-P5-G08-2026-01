part of '../main.dart';

class SessionStore extends ChangeNotifier {
  SessionStore(this._prefs);

  final SharedPreferences _prefs;
  String apiUrl = defaultApiUrl;
  String? accessToken;
  String? refreshToken;
  Map<String, dynamic>? user;

  Future<void> load() async {
    apiUrl = _prefs.getString('apiUrl') ?? defaultApiUrl;
    accessToken = _prefs.getString('accessToken');
    refreshToken = _prefs.getString('refreshToken');
    final rawUser = _prefs.getString('user');
    user = rawUser == null ? null : jsonDecode(rawUser) as Map<String, dynamic>;
  }

  Future<void> saveAuth(Map<String, dynamic> data) async {
    accessToken = (data['accessToken'] ?? data['token']) as String?;
    refreshToken = data['refreshToken'] as String?;
    user = data['user'] as Map<String, dynamic>?;
    if (accessToken != null) {
      await _prefs.setString('accessToken', accessToken!);
    }
    if (refreshToken != null) {
      await _prefs.setString('refreshToken', refreshToken!);
    }
    if (user != null) await _prefs.setString('user', jsonEncode(user));
    notifyListeners();
  }

  Future<void> saveApiUrl(String value) async {
    apiUrl = value.trim().replaceAll(RegExp(r'/+$'), '');
    await _prefs.setString('apiUrl', apiUrl);
    notifyListeners();
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    user = null;
    await _prefs.remove('accessToken');
    await _prefs.remove('refreshToken');
    await _prefs.remove('user');
    notifyListeners();
  }
}
