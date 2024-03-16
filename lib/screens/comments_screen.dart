import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unop/models/user.dart';
import 'package:unop/providers/user_provider.dart';
import 'package:unop/resources/firestore_methods.dart';
import 'package:unop/utils/colors.dart';
import 'package:unop/utils/utils.dart';
import 'package:unop/widgets/comment_card.dart';
import 'package:provider/provider.dart';

/// A stateful widget to display and manage comments on a post.
class CommentsScreen extends StatefulWidget {
  final String postId; // Unique identifier for the post

  const CommentsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController commentEditingController =
      TextEditingController(); // Controller for the comment input field

  /// Method to post a comment.
  void postComment(String uid, String name, String profilePic) async {
    try {
      String res = await FireStoreMethods().postComment(
        widget.postId, // ID of the post to which the comment is being added
        commentEditingController.text, // Text of the comment
        uid, // User ID of the commenter
        name, // Name of the commenter
        profilePic, // Profile picture URL of the commenter
      );

      if (res != 'success') {
        if (context.mounted)
          showSnackBar(context, res); // Showing error message if not successful
      }
      setState(() {
        commentEditingController.text =
            ""; // Clear the text field upon successful comment
      });
    } catch (err) {
      showSnackBar(context,
          err.toString()); // Showing error message in case of exception
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<UserProvider>(context)
        .getUser; // Getting the current user from the provider

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor, // Setting the app bar color
        title: const Text('Comments'), // App bar title
        centerTitle: false,
      ),
      body: StreamBuilder(
        // StreamBuilder to listen to comment changes in real-time
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId) // Specifying the post ID
            .collection('comments')
            .snapshots(), // Fetching comment snapshots
        builder: (context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator()); // Showing a loader while data is being fetched
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length, // Count of comments
            itemBuilder: (ctx, index) {
              var commentData =
                  snapshot.data!.docs[index]; // Get the comment data as a Map

              return CommentCard(
                  snap: commentData); // Pass this Map to the CommentCard
            },
          );
        },
      ),
      // Bottom navigation bar for text input
      bottomNavigationBar: SafeArea(
        child: Container(
          height: kToolbarHeight,
          margin: EdgeInsets.only(
              bottom: MediaQuery.of(context)
                  .viewInsets
                  .bottom), // Adjusting margin for the keyboard
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                    user!.photoUrl), // Displaying user's profile picture
                radius: 18,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: TextField(
                    controller:
                        commentEditingController, // TextField for writing a comment
                    decoration: InputDecoration(
                      hintText:
                          'Comment as ${user.username}', // Hint text displaying the username
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () => postComment(
                  user.uid,
                  user.username,
                  user.photoUrl,
                ), // Posting the comment on tap
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: const Text(
                    'Post', // Button to post the comment
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
