import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:unop/providers/user_provider.dart';
import 'package:unop/resources/firestore_methods.dart';
import 'package:unop/utils/colors.dart';
import 'package:unop/utils/image_rotation.dart';
import 'package:unop/utils/utils.dart';
import 'package:unop/widgets/text_field_input.dart';

class GroupSignupScreen extends StatefulWidget {
  const GroupSignupScreen({Key? key}) : super(key: key);

  @override
  State<GroupSignupScreen> createState() => _GroupSignupScreenState();
}

class _GroupSignupScreenState extends State<GroupSignupScreen> {
  // TextEditingControllers to manage the text input for group name and bio.
  final TextEditingController _groupnameController = TextEditingController();
  final TextEditingController _groupIdController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Boolean to manage loading state.
  bool _isLoading = false;

  // Variable to store the selected image as Uint8List.
  Uint8List? _image;

  // Dispose method to clean up the controllers when the widget is disposed.
  @override
  void dispose() {
    super.dispose();
    _groupnameController.dispose();
    _groupIdController.dispose();
  }

  // Function to handle group creation logic.
  void addGroup(String uid) async {
    setState(() {
      _isLoading = true; // Setting loading state to true.
    });
    if (_image == null) {
      // Load a default image if none is selected.
      ByteData bytes = await rootBundle.load('assets/basic.png');
      _image = bytes.buffer.asUint8List();
    }

    // Calling a method to add a group to Firestore and storing the response.
    String res = await FireStoreMethods().addGroup(
      groupName: _groupnameController.text,
      bio: _bioController.text,
      file: _image!,
      groupId: _groupIdController.text,
      uid: uid,
    );

    // Handling the response.
    if (res == "success") {
      setState(() {
        _isLoading = false; // Reset loading state.
      });
      // Navigate back if the context is still mounted.
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _isLoading = false; // Reset loading state.
      });
      // Show error message if the context is still mounted.
      if (context.mounted) {
        showSnackBar(context, res);
      }
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

  // Building the UI for the GroupSignupScreen.
  @override
  Widget build(BuildContext context) {
    // Getting the UserProvider instance from the context.
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    userProvider.refreshUser(); // Refresh user data.

    return Scaffold(
      // AppBar definition with back button.
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: mobileBackgroundColor,
        title: const Text('Create Group'),
      ),
      // Prevent the widget from resizing when the keyboard is displayed.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          // Setting up the layout.
          padding: const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stack to overlay the add photo icon over the avatar.
              Stack(
                children: [
                  // Display selected image or default avatar.
                  _image != null
                      ? CircleAvatar(
                          radius: 64,
                          backgroundImage: MemoryImage(_image!),
                          backgroundColor: Colors.red,
                        )
                      : const CircleAvatar(
                          radius: 64,
                          backgroundImage: AssetImage('assets/basic.png'),
                          backgroundColor: Colors.red,
                        ),
                  // Positioned widget to place the add photo icon.
                  Positioned(
                    bottom: -10,
                    left: 80,
                    child: IconButton(
                      onPressed: selectImage,
                      icon: const Icon(Icons.add_a_photo),
                    ),
                  )
                ],
              ),
              // Spacing between widgets.
              const SizedBox(
                height: 24,
              ),
              // Text field for entering group name.
              TextFieldInput(
                hintText: 'Enter your group name',
                textInputType: TextInputType.text,
                textEditingController: _groupnameController,
              ),
              const SizedBox(
                height: 24,
              ),
              TextFieldInput(
                hintText: 'Enter your group id',
                textInputType: TextInputType.text,
                textEditingController: _groupIdController,
              ),
              // Spacing between widgets.
              const SizedBox(
                height: 24,
              ),
              // Text field for entering group bio.
              TextFieldInput(
                hintText: 'Enter group bio',
                textInputType: TextInputType.text,
                textEditingController: _bioController,
              ),
              // Spacing between widgets.
              const SizedBox(
                height: 24,
              ),
              // Button to create group.
              InkWell(
                onTap: () => {addGroup(userProvider.getUser!.uid)},
                child: Container(
                  // Button styling.
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    color: blueColor,
                  ),
                  child: !_isLoading
                      ? const Text(
                          'Create Group',
                        )
                      : const CircularProgressIndicator(
                          color: primaryColor,
                        ),
                ),
              ),
              // Spacing at the bottom.
              const SizedBox(
                height: 12,
              ),
              // Flexible container to absorb remaining space.
              Flexible(
                flex: 2,
                child: Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
