import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unop/utils/utils.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.userData['username'] ?? '';
    _bioController.text = widget.userData['bio'] ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    } catch (e) {
      // Handle exceptions
      showSnackBar(context, 'Failed to pick image: $e');
    }
  }

  void updateProfileData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String photoUrl = widget.userData['photoUrl'];

    if (_imageFile != null) {
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref('profilePics/$uid')
          .putFile(File(_imageFile!.path));

      if (snapshot.state == TaskState.success) {
        photoUrl = await snapshot.ref.getDownloadURL();
      }
    }

    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'username': _usernameController.text,
      'bio': _bioController.text,
      'photoUrl': photoUrl,
    }).then((_) {
      showSnackBar(context, 'Profile updated successfully!');
      Navigator.pop(context);
    }).catchError((error) {
      showSnackBar(context, 'Error updating profile: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: updateProfileData,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(12),
        children: <Widget>[
          Container(
            width: 80, // Width of the square, double the radius
            height: 80, // Height of the square, double the radius
            decoration: BoxDecoration(
              image: widget.userData['photoUrl'] != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                          widget.userData['photoUrl']),
                      fit: BoxFit
                          .fitHeight, // Ensures the image covers the container
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.userData['photoUrl'] == null
                ? const CircularProgressIndicator() // Shows a spinner if the image is not loaded
                : null,
          ),
          TextButton(
            onPressed: pickImage,
            child: Text("Change Profile Photo"),
          ),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _bioController,
            decoration: InputDecoration(labelText: 'Bio'),
          ),
        ],
      ),
    );
  }
}
