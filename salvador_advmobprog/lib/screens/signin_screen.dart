import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService(); // <-- Added this line
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final input = _usernameController.text.trim();
      final password = _passwordController.text;

      if (input.contains('@')) {
        await signIn(email: input, password: password);
      } else {
        await _userService.loginUser(input, password);
      }
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login failed: ${error.toString().replaceFirst(RegExp(r'^\[.*?\]\s*'), '')}'
            )
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('assets/images/nubdexchange_logo.png', width: 110.w, height: 110.w),
                  SizedBox(height: 12.h),
                  Text('Welcome', style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 28.h),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Email or Username', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 14.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 22.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Log In'),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text("Don't have an account? Sign up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}