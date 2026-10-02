import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSending = false;
  late String _currentUserId;
  late String _tappedUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
    _tappedUserId = widget.tappedUser['uid']?.toString() ?? '';

    // Automatically mark unread messages from recipient as seen
    _chatService.markMessagesAsSeen(_tappedUserId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(_tappedUserId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';
    final dt = timestamp.toDate();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserName = widget.tappedUser['firstName']?.toString() ?? 'User';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          tappedUserName,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessage(_currentUserId, _tappedUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!'));
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final msgText = data['message']?.toString() ?? '';
                    final senderId = data['senderId']?.toString() ?? '';
                    final isMe = senderId == _currentUserId;
                    final isSeen = data['seen'] == true;
                    final formattedTime = _formatTime(data['timestamp']);

                    // Enhancement 3: Smooth Slide & Fade transition animation for bubbles
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(isMe ? (24 * (1 - value)) : (-24 * (1 - value)), 0),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 12.w),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16.r),
                                  topRight: Radius.circular(16.r),
                                  bottomLeft: Radius.circular(isMe ? 16.r : 2.r),
                                  bottomRight: Radius.circular(isMe ? 2.r : 16.r),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Text(
                                msgText,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            // Enhancement 3: Timestamps and Delivered/Seen indicators
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (formattedTime.isNotEmpty)
                                  Text(
                                    formattedTime,
                                    style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                                  ),
                                if (isMe) ...[
                                  SizedBox(width: 6.w),
                                  Icon(
                                    isSeen ? Icons.done_all : Icons.done,
                                    size: 14.sp,
                                    color: isSeen ? Colors.blue : Colors.grey,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    isSeen ? 'Seen' : 'Delivered',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: isSeen ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isSending)
            Padding(
              padding: EdgeInsets.only(right: 16.w, bottom: 4.h),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Sending...',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      focusNode: _msgFocus,
                      enabled: !_isSending,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _isSending
                      ? Padding(
                          padding: EdgeInsets.all(10.r),
                          child: SizedBox(
                            height: 22.r,
                            width: 22.r,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            icon: Icon(Icons.send, color: Colors.white, size: 18.sp),
                            onPressed: _send,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}