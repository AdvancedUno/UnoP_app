import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unop/main.dart';
import 'package:unop/responsive/mobile_screen_layout.dart';
import 'package:unop/screens/group_profile_screen.dart';
import 'package:unop/widgets/like_animation.dart';

// A StatefulWidget that represents an individual group card.
class GroupCard extends StatefulWidget {
  final DocumentSnapshot snap; // The Firestore document snapshot for the group.
  final Map<dynamic, dynamic> userData; // The current user's data.
  final VoidCallback
      onLikePressed; // Callback to execute when the like button is pressed.

  // Constructor requiring the document snapshot, user data, and the like button callback.
  const GroupCard({
    Key? key,
    required this.snap,
    required this.userData,
    required this.onLikePressed,
  }) : super(key: key);

  @override
  _GroupCardState createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  late bool
      isLiked; // Local state to track if the current user has liked this group.

  @override
  void initState() {
    super.initState();
    // Initialize the isLiked state based on whether the group ID is in the user's likeGroup list.
    isLiked = !widget.userData["likeGroup"].contains(widget.snap["groupid"]);
  }

  void navigateToGroupProfile(DocumentSnapshot snap) {
    // mainNavigatorKey.push(MaterialPageRoute(
    //   builder: (context) => GroupProfileScreen(groupid: snap["groupid"]),
    // ));
  }

  @override
  Widget build(BuildContext context) {
    // Building the card widget.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // GestureDetector to handle taps on the card.
        GestureDetector(
          onTap: () {
            navigateToGroupProfile(widget.snap);
          },
          child: Card(
            // Styling the card with rounded corners and shadow effect.
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            child: Stack(
              children: [
                // ClipRRect to clip the child widget with rounded corners.
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  // AspectRatio to maintain the aspect ratio of the child widget.
                  child: AspectRatio(
                    aspectRatio: 15 / 11,
                    // CachedNetworkImage for efficient loading and caching of the image.
                    child: CachedNetworkImage(
                      imageUrl: widget.snap[
                          'photoUrl'], // URL of the image from Firestore document.
                      placeholder: (context, url) => const Center(
                          child:
                              CircularProgressIndicator()), // Placeholder widget displayed while the image is loading.
                      errorWidget: (context, url, error) => const Icon(
                          Icons.error), // Widget displayed in case of an error.
                      fit: BoxFit
                          .cover, // BoxFit.cover ensures the image covers the space without distortion.
                    ),
                  ),
                ),

                // Positioned widget to overlay the like button on top of the card content.
                Positioned(
                  top: -5,
                  right: -5,
                  child: LikeAnimation(
                    isAnimating:
                        isLiked, // Animation triggered based on the isLiked state.
                    smallLike: true, // Configuration for the like animation.
                    child: IconButton(
                      // The like button icon, changing based on the isLiked state.
                      icon: isLiked
                          ? const Icon(Icons.favorite, color: Colors.red)
                          : const Icon(Icons.favorite_border),
                      onPressed: () {
                        // Toggle the isLiked state when the button is pressed.
                        setState(() {
                          isLiked = !isLiked;
                        });
                        // Call the provided onLikePressed callback.
                        widget.onLikePressed();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Padding widget for the text below the card.
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            // Display the group's name.
            widget.snap['groupName'],
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
