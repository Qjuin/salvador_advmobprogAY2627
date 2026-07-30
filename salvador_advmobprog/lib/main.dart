import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings.dart'; // Imports ThemeModel and SettingsPage
// The entry point of the app. It initializes the app and wraps it with a ChangeNotifierProvider so the ThemeModel is available globally.
void main() {
 runApp(
   ChangeNotifierProvider(
     create: (context) => ThemeModel(),
     child: const MyApp(),
   ),
 );
}
// The root widget of the application. It sets up the core app structure and listens to the ThemeModel to apply the correct theme.
class MyApp extends StatelessWidget {
 const MyApp({super.key});
 // Builds the MaterialApp which contains global configurations like the active theme and the default home screen.
 @override
 Widget build(BuildContext context) {
   final themeModel = Provider.of<ThemeModel>(context);
   return MaterialApp(
     debugShowCheckedModeBanner: false,
     theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
     home: const MyHomePage(),
   );
 }
}
// The main screen of the app. It holds the structural UI layout and requests a separate state class to manage its dynamic data.
class MyHomePage extends StatefulWidget {
 const MyHomePage({super.key});
 // Creates and attaches the mutable state object (_MyHomePageState) to this widget so it can track changes.
 @override
 State<MyHomePage> createState() => _MyHomePageState();
}
// The state manager for MyHomePage. It holds the local counter data and handles user interactions for this specific screen.
class _MyHomePageState extends State<MyHomePage> {
 int _counter = 0;
 // Increases the counter by 1 and triggers a UI rebuild (via setState) to show the new number on the screen.
 void incrementCounter() {
   setState(() {
     _counter++;
   });
 }
 // Builds the visual layout for the Home page, including the app bar, the counter text, and the floating action button.
 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('Counter Page'),
       actions: [
         IconButton(
           icon: const Icon(Icons.settings),
           tooltip: 'Settings',
           onPressed: () async {
             // Wait for the user to navigate to the Settings Page and eventually return
             await Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => const SettingsPage(),
               ),
             );
             // Reset the counter to 0 once the user navigates back to this page
             if (!mounted) return;
             setState(() {
               _counter = 0;
             });
           },
         ),
       ],
     ),
     body: Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           const Text(
             'You have pushed the button this many times:',
           ),
           Text(
             '$_counter',
             style: Theme.of(context).textTheme.headlineMedium,
           ),
         ],
       ),
     ),
     floatingActionButton: FloatingActionButton(
       onPressed: incrementCounter,
       tooltip: 'Increment',
       child: const Icon(Icons.add),
     ),
   );
 }
}