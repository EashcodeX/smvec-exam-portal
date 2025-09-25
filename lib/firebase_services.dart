// // Create this file: lib/services/firebase_service.dart
// import 'package:flutter/foundation.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:io' show Platform;

// class FirebaseService {
//   static FirebaseFirestore? _firestore;
  
//   static FirebaseFirestore get firestore {
//     if (kIsWeb) {
//       return FirebaseFirestore.instance;
//     } else {
//       // For Windows development, return a mock or throw an error with helpful message
//       throw Exception('Firebase is not available on ${Platform.operatingSystem}. Please use web version for full functionality.');
//     }
//   }
  
//   static bool get isFirebaseAvailable => kIsWeb;
  
//   // Mock data for development on Windows
//   static final Map<String, dynamic> mockAdminData = {
//     'Name': 'admin',
//     'password': 'admin123',
//   };
  
//   static final Map<String, dynamic> mockStudentData = {
//     'name': 'Test Student',
//     'password': 'student123',
//     'set': '1',
//     'program': 'B.Tech CSE',
//     'gmail': 'test@student.com',
//     'phone': '9876543210',
//   };
  
//   static final List<Map<String, dynamic>> mockQuestions = [
//     {
//       'qs': 'What is the capital of India?',
//       'option': ['New Delhi', 'Mumbai', 'Kolkata', 'Chennai'],
//       'correct_ans': 'New Delhi',
//       'type': 'multiple_choice',
//       'question_number': 1,
//     },
//     {
//       'qs': 'Flutter is developed by which company?',
//       'option': ['Google', 'Microsoft', 'Apple', 'Meta'],
//       'correct_ans': 'Google',
//       'type': 'multiple_choice',
//       'question_number': 2,
//     },
//     // Add more mock questions as needed
//   ];
  
//   // Mock authentication method
//   static Future<Map<String, dynamic>?> mockLogin(String userId, String password) async {
//     // Simulate network delay
//     await Future.delayed(Duration(milliseconds: 500));
    
//     // Check admin credentials
//     if (mockAdminData['Name'] == userId && mockAdminData['password'] == password) {
//       return {'type': 'admin', 'data': mockAdminData};
//     }
    
//     // Check student credentials (for demo, any student ID works)
//     if (password == mockStudentData['password']) {
//       return {'type': 'student', 'data': {...mockStudentData, 'register_number': userId}};
//     }
    
//     return null; // Invalid credentials
//   }
// } 