import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unop/main.dart';
import 'package:unop/resources/auth_methods.dart';
import 'package:unop/responsive/mobile_screen_layout.dart';
import 'package:unop/responsive/responsive_layout.dart';
import 'package:unop/responsive/web_screen_layout.dart';
import 'package:unop/screens/email_verification_screen.dart';
import 'package:unop/screens/login_screen.dart';
import 'package:unop/utils/colors.dart';
import 'package:unop/utils/image_rotation.dart';
import 'package:unop/utils/utils.dart';
import 'package:unop/widgets/text_field_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userSearchIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;
  String res = "";

  Uint8List? _image;

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _userSearchIdController.dispose();
  }

  void signUpUser() async {
    // set loading to true
    setState(() {
      _isLoading = true;
    });

    // Validate email and username fields
    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String userSearchId = _userSearchIdController.text.trim();
    String bio = _bioController.text.trim();

    if (email.isEmpty ||
        username.isEmpty ||
        userSearchId.isEmpty ||
        password.isEmpty) {
      // Show an error message if email or username is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and username cannot be empty")),
      );
      setState(() {
        _isLoading = false;
      });
      return; // Exit the function early
    }

    // Handling default image if no image is selected
    if (_image == null) {
      ByteData bytes = await rootBundle.load('assets/UnoP_logo.png');
      _image = bytes.buffer.asUint8List();
    }
    res = await AuthMethods().signUpUser(
        email: email,
        password: password,
        username: username,
        bio: bio,
        file: _image!,
        userSearchId: userSearchId);

    bool? getAgree = await showEulaDialog(context);
    if (!getAgree!) {
      res = "Failed with agreement";
    }

    // Navigate to EmailVerificationScreen with the provided details
    if (res == "success") {
      if (context.mounted) {
        mainNavigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
              password: password,
              username: username,
              userSearchId: userSearchId,
              bio: bio,
              file: _image!,
            ),
          ),
        );
      }
    } else {
      // Show the error
      if (context.mounted) {
        showSnackBar(context, res);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _signUpUserWithGoogle() async {
    try {
      // set loading to true
      setState(() {
        _isLoading = true;
      });

      if (_image == null) {
        ByteData bytes = await rootBundle.load('assets/UnoP_logo.png');
        _image = bytes.buffer.asUint8List();
      }

      // signup user using our authmethodds
      String res = await AuthMethods().signInWithGoogle(
        username: _usernameController.text,
        userSearchId: _userSearchIdController.text,
        bio: _bioController.text,
        file: _image!,
        userInfo: null,
        finishedAuth: false,
      );

      bool? getAgree = await showEulaDialog(context);
      if (!getAgree) {
        res = "Failed with agreement";
      }

      // if string returned is sucess, user has been created
      if (res == "success") {
        setState(() {
          _isLoading = false;
        });
        // navigate to the home screen
        if (context.mounted) {
          mainNavigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ResponsiveLayout(
                mobileScreenLayout: MobileScreenLayout(),
                //webScreenLayout: WebScreenLayout(),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        // show the error
        if (context.mounted) {
          showSnackBar(context, res);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  void _signInWithApple() async {
    try {
      // set loading to true
      setState(() {
        _isLoading = true;
      });

      if (_image == null) {
        ByteData bytes = await rootBundle.load('assets/UnoP_logo.png');
        _image = bytes.buffer.asUint8List();
      }

      //signup user using our authmethodds
      String res = await AuthMethods().signInWithApple(
        username: _usernameController.text,
        userSearchId: _userSearchIdController.text,
        bio: _bioController.text,
        file: _image!,
        finishedAuth: false,
        userInfo: null,
      );

      // if string returned is sucess, user has been created
      if (res == "success") {
        setState(() {
          _isLoading = false;
        });
        // navigate to the home screen
        //if (context.mounted) {
        // Navigates to the main app screen on successful login.

        bool? getAgree = await showEulaDialog(context);

        // Handling the response after the login attempt.
        if (getAgree!) {
          if (context.mounted) {
            // Navigates to the main app screen on successful login.
            mainNavigatorKey.currentState?.popUntil((route) => route.isFirst);
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
            showSnackBar(context, "You need to agree on app regulation");
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        // show the error
        if (context.mounted) {
          showSnackBar(context, res);
        }
      }
    } catch (e) {
      // TODO: Show alert here
      print(e);
    }
  }

// Function to select an image from the gallery
  Future<void> selectImage() async {
    final ImagePicker _picker = ImagePicker();

    // Pick an image
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Fix the image rotation if necessary
      File fixedImage = await fixExifRotation(imageFile.path);

      // Convert to Uint8List
      Uint8List imageBytes = await fixedImage.readAsBytes();

      // Update the state to display the image
      setState(() {
        _image = imageBytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Building the UI for the SignupScreen.
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Prevents the UI from resizing when the keyboard appears.
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 32), // Padding for the container.
          width:
              double.infinity, // Container takes the full width of the screen.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .center, // Centers the column items horizontally.
            children: [
              Flexible(
                flex: 2,
                child: Container(), // Flexible space at the top of the screen.
              ),

              Stack(
                children: [
                  // CircleAvatar to display selected image or default avatar.
                  _image != null
                      ? CircleAvatar(
                          radius: 64,
                          backgroundImage: MemoryImage(_image!),
                          backgroundColor:
                              Colors.white, // Background color for the avatar.
                        )
                      : const CircleAvatar(
                          radius: 64,
                          backgroundImage: AssetImage('assets/UnoP_logo.png'),
                          backgroundColor: Colors.white,
                        ),
                  Positioned(
                    bottom: 0, // Positioning of the add photo icon.
                    left: 80,
                    child: IconButton(
                      onPressed:
                          selectImage, // Calls selectImage function to pick an image.
                      icon: const Icon(
                        Icons.add_a_photo,
                        color: Colors.black,
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(
                height: 24, // Spacing between widgets.
              ),
              // Text field for entering the username.
              TextFieldInput(
                hintText: 'Enter your username (Required)',
                textInputType: TextInputType.text,
                textEditingController: _usernameController,
              ),
              const SizedBox(
                height: 24, // Spacing between widgets.
              ),
              TextFieldInput(
                hintText: 'Enter your user ID (Required)',
                textInputType: TextInputType.text,
                textEditingController: _userSearchIdController,
              ),

              const SizedBox(
                height: 24, // Spacing between widgets.
              ),
              // Text field for entering the bio.
              TextFieldInput(
                hintText: 'Enter your bio (Required)',
                textInputType: TextInputType.text,
                textEditingController: _bioController,
              ),
              const SizedBox(
                height: 24, // Spacing between widgets.
              ),
              Center(
                  child: Card(
                color: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: InkWell(
                  onTap: () async {
                    // Your Google sign-in logic
                    _signUpUserWithGoogle();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // to keep the row size to a minimum
                      children: [
                        Image.asset(
                          'assets/google.png',
                          height: 40, // Adjust the size as needed
                        ),
                        const SizedBox(
                            width: 10), // for spacing between image and text
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                              fontSize: 16, // Adjust the font size as needed
                              fontWeight:
                                  FontWeight.bold, // optional, for emphasis
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )),

              Center(
                  child: Card(
                color: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: InkWell(
                  onTap: () async {
                    // Your apple sign-in logic
                    _signInWithApple();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // to keep the row size to a minimum
                      children: [
                        Image.asset(
                          'assets/apple.png',
                          height: 40, // Adjust the size as needed
                        ),
                        const SizedBox(
                            width: 10), // for spacing between image and text
                        const Text(
                          'Sign in with Apple',
                          style: TextStyle(
                              fontSize: 16, // Adjust the font size as needed
                              fontWeight:
                                  FontWeight.bold, // optional, for emphasis
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(
                height: 24, // Spacing between widgets.
              ),
              // Text field for entering the email.
              TextFieldInput(
                hintText: 'Enter your email',
                textInputType: TextInputType.emailAddress,
                textEditingController: _emailController,
              ),
              const SizedBox(
                height: 24, // Spacing between widgets.
              ),
              // Text field for entering the password.
              TextFieldInput(
                hintText: 'Enter your password',
                textInputType: TextInputType.text,
                textEditingController: _passwordController,
                isPass: true, // Indicates it's a password field.
              ),
              const SizedBox(
                height: 24, // Spacing between widgets.
              ),
              // InkWell for the sign-up button.
              InkWell(
                onTap: signUpUser, // Calls signUpUser function when tapped.
                child: Container(
                  width: double
                      .infinity, // Container takes the full width of the screen.
                  alignment: Alignment
                      .center, // Centers the text inside the container.
                  padding: const EdgeInsets.symmetric(
                      vertical: 12), // Padding inside the container.
                  decoration: const ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                          Radius.circular(2)), // Rounded corners.
                    ),
                    color: Colors.brown, // Background color of the button.
                  ),
                  child: !_isLoading
                      ? const Text(
                          'Sign up',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      : const CircularProgressIndicator(
                          color:
                              primaryColor, // Loading indicator when signing up.
                        ),
                ),
              ),
              const SizedBox(
                height: 1, // Spacing between widgets.
              ),
              Flexible(
                flex: 2,
                child:
                    Container(), // Flexible space at the bottom of the screen.
              ),
              // Row for navigating to the login screen.
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Centers the row items horizontally.
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 2), // Padding for the text.
                    child: const Text(
                      'Already have an account?',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      mainNavigatorKey.currentState
                          ?.popUntil((route) => route.isFirst);

                      mainNavigatorKey.currentState
                          ?.pushReplacement(MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2), // Padding for the text.
                      child: const Text(
                        ' Login.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Makes the text bold.
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
