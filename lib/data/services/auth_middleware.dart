// import 'package:flutter/material.dart';
// import '../services/firebase_auth_service.dart';

// class AuthMiddleware {
//   final FirebaseAuthService _authService = FirebaseAuthService();

//   // Check if the user is logged in, if not redirect to login page
//   Future<bool> checkAuth(BuildContext context) async {
//     bool isLoggedIn = await _authService.isLoggedIn();

//     if (!isLoggedIn) {
//       // Navigate to login page
//       Navigator.of(context).pushReplacementNamed('/login');
//       return false;
//     }

//     return true;
//   }

//   // If user is already logged in, redirect to home page
//   Future<bool> checkNotAuth(BuildContext context) async {
//     bool isLoggedIn = await _authService.isLoggedIn();

//     if (isLoggedIn) {
//       // Navigate to home page
//       Navigator.of(context).pushReplacementNamed('/home');
//       return false;
//     }

//     return true;
//   }
// }
