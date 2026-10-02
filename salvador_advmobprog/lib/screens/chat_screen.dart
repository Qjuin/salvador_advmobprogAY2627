import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserEmail;
  String? _currentUserId;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _currentUserEmail = _auth.currentUser?.email;
    _currentUserId = _auth.currentUser?.uid;
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 12.h),
          // Enhancement 2: Search bar for filtering users by name or email
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchChatController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          // StreamBuilder rendering existing Firebase accounts
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading users: ${snapshot.error}',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No registered accounts found.',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  );
                }

                // Enhancement 1 & 2: Exclude current user and filter by search text
                final users = snapshot.data!.where((user) {
                  final email = user['email']?.toString().toLowerCase() ?? '';
                  final firstName = user['firstName']?.toString().toLowerCase() ?? '';
                  final uid = user['uid']?.toString() ?? '';

                  final isNotCurrentUser = (uid.isNotEmpty && uid != _currentUserId) ||
                      (email.isNotEmpty && email != _currentUserEmail?.toLowerCase());

                  final matchesSearch = _searchText.isEmpty ||
                      email.contains(_searchText) ||
                      firstName.contains(_searchText);

                  return isNotCurrentUser && matchesSearch;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching accounts found.',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final firstName = user['firstName']?.toString() ?? 'User';
                    final email = user['email']?.toString() ?? 'No email';

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                      leading: CircleAvatar(
                        radius: 24.r,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                      title: Text(
                        firstName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 20.sp,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUserEmail: _currentUserEmail ?? '',
                              tappedUser: user,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}