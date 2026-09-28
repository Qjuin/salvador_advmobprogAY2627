import 'dart:async';

import 'package:flutter/material.dart';

import '../services/user_service.dart';

/// Enhancement 1: branded splash screen with persistent authentication routing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final delay = Completer<void>();
    _splashTimer = Timer(const Duration(milliseconds: 1500), delay.complete);
    await delay.future;
    final loggedIn = await _userService.isLoggedIn();
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, loggedIn ? '/home' : '/signin');
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/nubdexchange_logo.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}