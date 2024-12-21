import 'package:shared_preferences/shared_preferences.dart';

class ConfigsLocalDataSource {
  static const String _isFirstHealthReceivedKey = 'first_health_received';

  const ConfigsLocalDataSource();


  Future<bool> isFirstHealthReceived() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_isFirstHealthReceivedKey)) ?? false;
  }

  Future<void> setFirstHealthReceived(bool received) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstHealthReceivedKey, received);
  }
}
