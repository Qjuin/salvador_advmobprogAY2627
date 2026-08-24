import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';

/// Enhancement 3: render the authenticated user's persisted profile data.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late final Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Unable to load profile'));
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52.r,
                  backgroundImage: user.image.isEmpty ? null : NetworkImage(user.image),
                  child: user.image.isEmpty ? const Icon(Icons.person, size: 48) : null,
                ),
                SizedBox(height: 12.h),
                Text(
                  '${user.firstName} ${user.lastName}'.trim(),
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                ),
                Text('@${user.username}', style: TextStyle(color: Colors.amber.shade800)),
                SizedBox(height: 24.h),
                _ProfileRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                _ProfileRow(icon: Icons.wc_outlined, label: 'Gender', value: user.gender),
                _ProfileRow(icon: Icons.badge_outlined, label: 'User ID', value: '#${user.id}'),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber.shade700),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value.isEmpty ? 'Not provided' : value),
    );
  }
}
