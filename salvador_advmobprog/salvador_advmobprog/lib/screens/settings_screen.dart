import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
// This class represents the Settings screen where the user can change the app's theme.
class SettingsScreen extends StatelessWidget {
 const SettingsScreen({super.key});
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