import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:unop/resources/auth_methods.dart';
import 'package:unop/responsive/mobile_screen_layout.dart';
import 'package:unop/responsive/responsive_layout.dart';
import 'package:unop/utils/utils.dart';

// EmailVerificationScreen is responsible for handling the email verification process.
class EmailVerificationScreen extends StatefulWidget {
  // Constructor parameters to hold user data for signup
  final String email;
  final String password;
  final String username;
  final String bio;
  final Uint8List file;
  final String userSearchId;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.username,
    required this.bio,
    required this.file,
    required this.userSearchId,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false; // Tracks if the email has been verified
  Timer? timer; // Timer for periodic check of email verification status
  String res = "success";

  @override
  void initState() {
    super.initState();

    //AuthMethods().sendUserEmailVerification();
    // Set up a timer to periodically check email verification status
    timer =
        Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  // Method to check if the email has been verified
  Future<void> checkEmailVerified() async {
    if (await AuthMethods().checkUserEmailVerification()) {
      // Show success message when email is verified
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email Successfully Verified")));
      timer?.cancel(); // Stop the timer as email has been verified

      // Navigate to the main layout on successful signup
      if (res == "success") {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ResponsiveLayout(
                mobileScreenLayout: MobileScreenLayout(),
                //webScreenLayout: WebScreenLayout(),
              ),
            ),
          );
        }
      } else {
        // Show error message if signup fails
        if (context.mounted) {
          showSnackBar(context, res);
        }
      }
    }
  }

  @override
  void dispose() {
    // Clean up the timer when the widget is disposed
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Verification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('A verification email has been sent to: ${widget.email}',
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              isEmailVerified
                  ? const Text('Your email has been verified!')
                  : const CircularProgressIndicator(),
              const SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: () async {
              //     try {
              //       await AuthMethods().sendUserEmailVerification();
              //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              //           content: Text("Verification email re-sent")));
              //     } catch (e) {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //           SnackBar(content: Text("Error: ${e.toString()}")));
              //     }
              //   },
              //   child: const Text('Resend Email'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
