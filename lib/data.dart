import 'package:shared_preferences/shared_preferences.dart';

abstract class Data {
    void init(SharedPreferences prefs);
    void save(SharedPreferences prefs);
}


