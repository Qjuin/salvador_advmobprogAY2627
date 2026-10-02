import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/user.dart' as model;

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  // Save User Data to SharedPreferences
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    
    final user = model.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  // Return user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  // Return user object from SharedPreferences
  Future<model.User> getUser() async {
    final userData = await getUserData();
    return model.User.fromJson(userData);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // Logout and clear user data
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }
}

// Global Firebase Auth Variables & Helper Functions
final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
final FirebaseFirestore firestore = FirebaseFirestore.instance;

User? get currentUser => firebaseAuth.currentUser;
Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

Future<UserCredential> signIn({
  required String email,
  required String password,
}) async {
  return await firebaseAuth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

Future<UserCredential> createAccount({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
  required String username,
  required String age,
  required String contactNo,
}) async {
  // 1. Create user in Firebase Auth
  UserCredential credential = await firebaseAuth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  final uid = credential.user!.uid;

  // 2. Save user profile into Firestore "Users" collection
  await firestore.collection('Users').doc(uid).set({
    'uid': uid,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'username': username,
    'age': age,
    'contactNo': contactNo,
    'createdAt': Timestamp.now(),
  });

  return credential;
}

Future<void> signOut() async {
  await firebaseAuth.signOut();
}

Future<void> updateUsername({required String username}) async {
  await currentUser!.updateDisplayName(username);
}

Future<void> deleteAccount({
  required String email,
  required String password,
}) async {
  AuthCredential credential = EmailAuthProvider.credential(
    email: email,
    password: password,
  );
  await currentUser!.reauthenticateWithCredential(credential);
  await currentUser!.delete();
  await firebaseAuth.signOut();
}

Future<void> resetPasswordFromCurrentPassword({
  required String currentPassword,
  required String newPassword,
  required String email,
}) async {
  AuthCredential credential = EmailAuthProvider.credential(
    email: email,
    password: currentPassword,
  );
  await currentUser!.reauthenticateWithCredential(credential);
  await currentUser!.updatePassword(newPassword);
}