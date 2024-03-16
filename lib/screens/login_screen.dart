import 'package:flutter/material.dart';
import 'package:unop/main.dart';
import 'package:unop/navigator/navigation_service.dart';
import 'package:unop/resources/auth_methods.dart';
import 'package:unop/responsive/mobile_screen_layout.dart';
import 'package:unop/responsive/responsive_layout.dart';
import 'package:unop/responsive/web_screen_layout.dart';
import 'package:unop/screens/signup_screen.dart';
import 'package:unop/utils/colors.dart';
import 'package:unop/utils/global_variable.dart';
import 'package:unop/utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  // Function to handle user login.
  void loginUser(String mathod) async {
    setState(() {
      _isLoading = true; // Sets loading state to true when login starts.
    });
    String res = "error";
    if (mathod == "email") {
// Calls loginUser method from AuthMethods to perform the login operation.
      res = await AuthMethods().loginUser(
          email: _emailController.text, password: _passwordController.text);
    } else if (mathod == "google") {
      res = await AuthMethods().loginUserWithGoogle();
    } else if (mathod == "apple") {
      res = await AuthMethods().loginUserWithApple();
    }

    if (res == "first_time") {
      bool? getAgree = await showEulaDialog(context);
      if (!getAgree!) {
        res = "Failed with agreement";
      } else {
        res = "success";
      }
    }

    await Future.delayed(
        const Duration(seconds: 2)); // Add a delay of 2 seconds

    // Handling the response after the login attempt.
    if (res == 'success') {
      if (mounted) {
        mainNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        // Navigates to the main app screen on successful login.
        mainNavigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ResponsiveLayout(
              mobileScreenLayout: MobileScreenLayout(),
            ),
          ),
        );
      }
    } else {
      // Resets loading state and shows error message if login fails.
      if (context.mounted) {
        showSnackBar(context, res);
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false; // Resets loading state after login process.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          // Adjusts padding based on screen size.
          padding: MediaQuery.of(context).size.width > webScreenSize
              ? EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width / 3)
              : const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 1,
                child: Container(),
              ),
              SizedBox(
                // Placeholder for logo or branding image.
                height: 200,
                child: Image.asset(
                  'assets/UnoP_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(
                height: 64,
              ),
              TextField(
                decoration: const InputDecoration(
                  filled:
                      true, // this is required for backgroundColor to take effect
                  fillColor: Colors.black, // sets the background color to black
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(
                      color: Colors.white), // optional, for better contrast
                  // Add other styling as needed
                ),
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                style: const TextStyle(
                    color: Colors.white), // sets the text color to white
                // Add other properties as needed
              ),
              const SizedBox(
                height: 24,
              ),
              // Password input field with visibility toggle.
              TextField(
                // Styling and functionality for password field.s
                decoration: InputDecoration(
                  filled:
                      true, // this is required for backgroundColor to take effect
                  fillColor: Colors.black, // sets the background color to black
                  hintText: 'Enter your password',
                  hintStyle: const TextStyle(
                    color: Colors.white60, // optional, for better contrast
                  ),
                  // Add icon to toggle password visibility
                  suffixIcon: IconButton(
                    icon: Icon(
                      // Toggles the password show status
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white60,
                    ),
                    onPressed: () {
                      // Update the state to toggle password visibility
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  // Add other styling as needed
                ),
                obscureText: !_isPasswordVisible, // Ensures text is obscured
                controller: _passwordController,
                style: const TextStyle(
                  color: Colors.white, // sets the text color to white
                ),
                // Add other properties as needed
              ),
              const SizedBox(
                height: 24,
              ),
              InkWell(
                onTap: () => {loginUser("email")},
                // Styling for the login button.
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 50,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    color: Color.fromARGB(
                        255, 130, 110, 100), // Changed color to green
                  ),
                  child: !_isLoading
                      ? const Text(
                          'Log in',
                        )
                      : const CircularProgressIndicator(
                          color:
                              primaryColor, // This color will apply to the progress indicator
                        ),
                ),
              ),
              const SizedBox(
                height: 24, // Spacing between widgets.
              ),
              Center(
                  child: SizedBox(
                      width: MediaQuery.of(context).size.width *
                          0.8, // 80% of screen width
                      child: Card(
                        color: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: InkWell(
                          onTap: () async {
                            // Your Google sign-in logic
                            loginUser("google");
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize
                                  .min, // to keep the row size to a minimum
                              children: [
                                Image.asset(
                                  'assets/google.png',
                                  height: 40, // Adjust the size as needed
                                ),
                                const SizedBox(
                                    width:
                                        10), // for spacing between image and text
                                const Text(
                                  'Log in with Google',
                                  style: TextStyle(
                                      fontSize:
                                          16, // Adjust the font size as needed
                                      fontWeight: FontWeight
                                          .bold, // optional, for emphasis
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ))),
              Center(
                  child: SizedBox(
                      width: MediaQuery.of(context).size.width *
                          0.8, // 80% of screen width
                      child: Card(
                        color: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: InkWell(
                          onTap: () async {
                            // Your Google sign-in logic
                            loginUser("apple");
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize
                                  .min, // to keep the row size to a minimum
                              children: [
                                Image.asset(
                                  'assets/apple.png',
                                  height: 40, // Adjust the size as needed
                                ),
                                const SizedBox(
                                    width:
                                        10), // for spacing between image and text
                                const Text(
                                  'Log in with Apple',
                                  style: TextStyle(
                                      fontSize:
                                          16, // Adjust the font size as needed
                                      fontWeight: FontWeight
                                          .bold, // optional, for emphasis
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ))),
              const SizedBox(
                height: 12,
              ),

              // Spacing at the bottom.
              Flexible(
                flex: 2,
                child: Container(),
              ),

              // Link to sign up screen for users without an account.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text asking if the user doesn't have an account.
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text(
                      'Dont have an account?',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigator.of(context).push(
                      //   MaterialPageRoute(
                      //     builder: (context) => const SignupScreen(),
                      //   ),
                      // );
                      mainNavigatorKey.currentState
                          ?.popUntil((route) => route.isFirst);
                      mainNavigatorKey.currentState?.push(MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Text(
                        ' Signup.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
