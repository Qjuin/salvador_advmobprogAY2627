import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// This class acts as a provider to hold and manage the theme state (light or dark) for the entire app.
class ThemeModel with ChangeNotifier {
 bool _isDark = false;
 // Retrieves the current theme state (true for dark, false for light).
 bool get isDark => _isDark;
 // Switches the theme between light and dark mode, then notifies the app to rebuild the UI to reflect the change.
 void toggleTheme() {
   _isDark = !_isDark;
   notifyListeners();
 }
}
// This class represents the Settings screen where the user can change the app's theme.
class SettingsPage extends StatelessWidget {
 const SettingsPage({super.key});
 // Builds the layout and UI elements for the Settings page.
 @override
 Widget build(BuildContext context) {
   // Listen to the ThemeModel to update the switch and text dynamically
   final themeModel = Provider.of<ThemeModel>(context);
   return Scaffold(
     appBar: AppBar(
       title: const Text('Theme Settings'),
     ),
     body: Center(
       child: Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Text(
             themeModel.isDark ? 'Dark Mode' : 'Light Mode',
             style: const TextStyle(fontSize: 18),
           ),
           const SizedBox(width: 20),
           Switch(
             value: themeModel.isDark,
             onChanged: (value) {
               themeModel.toggleTheme();
             },
           ),
         ],
       ),
     ),
   );
 }
}