import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:provider/provider.dart';
import 'package:unop/models/group.dart';
import 'package:unop/providers/group_provider.dart';
import 'package:unop/providers/user_provider.dart';
import 'package:unop/resources/firestore_methods.dart';
import 'package:unop/screens/crop_result_view_screen.dart';
import 'package:unop/utils/colors.dart';

class AddPostScreen extends StatefulWidget {
  AddPostScreen({super.key});

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  bool isLoading = false; // Indicates if the post is being uploaded
  final TextEditingController _descriptionController =
      TextEditingController(); // Controller for post description
  List<String> selectedGroups = []; // List of selected groups for the post
  //final picker = ImagePicker(); // Image picker instance
  List<File> selectedImages = []; // List of selected images for the post
  bool _isMediaFetched = false; // To prevent multiple calls

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isMediaFetched) {
      _fetchNewMedia();
      _isMediaFetched = true; // Set flag to true after fetching media
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _descriptionController.dispose();
    selectedImages.clear();
    selectedGroups.clear();
  }

  Future<void> _fetchNewMedia() async {
    await InstaAssetPicker.pickAssets(
      context,
      onCompleted: (Stream<InstaAssetsExportDetails> cropStream) async {
        // Navigate to PickerCropResultScreen and wait for the result

        List<File> result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PickerCropResultScreen(cropStream: cropStream),
          ),
        );

        // Update selectedImages with the cropped files
        setState(() {
          if (result.isNotEmpty) {
            selectedImages = result;
          }
        });
        Navigator.pop(context);
      },
    );
    if (selectedImages.isEmpty) {
      Navigator.pop(context);
    }
  }

  // This function will return a list of group IDs where the user has write permission
  List<String> getWritableGroups(
      UserProvider userProvider, List<Group> allGroups) {
    String userId = userProvider.getUser!.uid;
    return allGroups
        .where((group) => group.canWrite.contains(userId))
        .map((group) => group.groupid)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    final GroupProvider groupProvider = Provider.of<GroupProvider>(context);

    // Get all groups from GroupProvider
    groupProvider.fetchAllGroups();
    List<Group> allGroups = groupProvider.allGroups;

    // Get writable groups for the user
    List<String> writableGroups = getWritableGroups(userProvider, allGroups);

    userProvider.refreshUser();
    if (selectedImages.isNotEmpty) {
      return _buildPostScreen(userProvider, writableGroups);
    } else {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  Widget _buildPostScreen(
      UserProvider userProvider, List<String> writableGroups) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: appbarColor,
          title: const Text(
            'New Post',
          ),
        ),
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          isLoading ? const LinearProgressIndicator() : Container(),
          const SizedBox(
            height: 10,
          ),
          Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                SizedBox(
                    height: 250,
                    child: (selectedImages.length > 1)
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.file(selectedImages[index]));
                            })
                        : Image.file(selectedImages[0]))
              ])),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      hintText: "Write a caption...", border: InputBorder.none),
                  maxLines: 6,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
          const Divider(color: secondaryColor),
          Row(children: [
            Expanded(
                child: Column(children: [
              const Row(
                children: [
                  Padding(
                      padding: EdgeInsets.only(left: 15, right: 10),
                      child: Icon(Icons.group_add, size: 30)),
                  Text(
                    'Add Groups',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: DropdownSearch<String>.multiSelection(
                      items: writableGroups,
                      dropdownButtonProps:
                          const DropdownButtonProps(icon: Icon(Icons.add)),
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        textAlignVertical: TextAlignVertical.center,
                        dropdownSearchDecoration: InputDecoration(
                            border: InputBorder.none, hintText: "Empty"),
                      ),
                      onChanged: (List<String> selectedItems) {
                        setState(() {
                          selectedGroups = selectedItems;
                        });
                      }))
            ]))
          ]),
        ])),
        bottomNavigationBar: Padding(
            padding:
                const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 60),
            child: ElevatedButton(
              onPressed: selectedGroups.isNotEmpty
                  ? () async {
                      setState(() {
                        isLoading = true;
                      });
                      String res = await postImage(
                        userProvider.getUser!.uid,
                        userProvider.getUser!.username,
                        userProvider.getUser!.photoUrl,
                        selectedGroups,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: (res == 'success')
                                ? const Text('Posted')
                                : Text(res)),
                      );
                      if (res == 'success') {
                        Navigator.pop(context);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Post'),
            )));
  }

  Future<String> postImage(
      String uid, String username, String profImage, List postGroupId) async {
    try {
      String res = await FireStoreMethods().uploadPost(
          _descriptionController.text,
          selectedImages,
          uid,
          username,
          profImage,
          postGroupId);
      return res;
    } catch (err) {
      return err.toString();
    }
  }
}
