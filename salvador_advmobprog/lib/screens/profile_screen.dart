import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late final Future<User> _dummyUserFuture;

  @override
  void initState() {
    super.initState();
    _dummyUserFuture = _userService.getUser();
  }

  Future<void> _logout() async {
    await signOut();
    await _userService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/signin');
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _logout();
    }
  }

  String _cleanError(dynamic error) {
    return error.toString().replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
  }

  void _showUpdateUsernameDialog() {
    final controller = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Update Username'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'New Username'),
                ),
                if (errorMessage != null) ...[
                  SizedBox(height: 8.h),
                  Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await updateUsername(username: controller.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {});
                    }
                  } catch (e) {
                    setStateDialog(() {
                      errorMessage = _cleanError(e);
                    });
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: currentPwController, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
                TextField(controller: newPwController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
                if (errorMessage != null) ...[
                  SizedBox(height: 8.h),
                  Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await resetPasswordFromCurrentPassword(
                      email: currentUser!.email!,
                      currentPassword: currentPwController.text,
                      newPassword: newPwController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Updated')));
                    }
                  } catch (e) {
                    setStateDialog(() {
                      errorMessage = _cleanError(e);
                    });
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final pwController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter your password to confirm account deletion. This cannot be undone.'),
                TextField(controller: pwController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                if (errorMessage != null) ...[
                  SizedBox(height: 8.h),
                  Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    await deleteAccount(email: currentUser!.email!, password: pwController.text);
                    if (mounted) Navigator.pushReplacementNamed(context, '/signin');
                  } catch (e) {
                    setStateDialog(() {
                      errorMessage = _cleanError(e);
                    });
                  }
                },
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser != null) {
      return _buildFirebaseProfile(currentUser!);
    }
    
    return _buildDummyJsonProfile();
  }

  Widget _buildFirebaseProfile(firebase.User user) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            CircleAvatar(
              radius: 52.r,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null ? const Icon(Icons.person, size: 48) : null,
            ),
            SizedBox(height: 12.h),
            Text(
              user.displayName ?? 'No Username Set',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
            Text(user.email ?? '', style: TextStyle(color: Colors.amber.shade800)),
            SizedBox(height: 24.h),
            
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update Username'),
              onTap: _showUpdateUsernameDialog,
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              onTap: _showChangePasswordDialog,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              onTap: _showDeleteAccountDialog,
            ),
            
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDummyJsonProfile() {
    return SafeArea(
      child: FutureBuilder<User>(
        future: _dummyUserFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || snapshot.data == null) return const Center(child: Text('Unable to load profile'));

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
                    onPressed: _confirmLogout,
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