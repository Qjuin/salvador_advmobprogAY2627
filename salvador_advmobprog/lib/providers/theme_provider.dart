import 'package:flutter/material.dart';

class ThemeModel with ChangeNotifier {
	bool _isDark = false;

	bool get isDark => _isDark;

	ThemeData get lightMode => ThemeData(
				brightness: Brightness.light,
				primarySwatch: Colors.blue,
			);

	ThemeData get darkMode => ThemeData(
				brightness: Brightness.dark,
				primarySwatch: Colors.blue,
			);

	void toggleTheme() {
		_isDark = !_isDark;
		notifyListeners();
	}
}
