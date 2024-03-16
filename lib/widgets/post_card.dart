import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unop/models/group.dart';
import 'package:unop/models/user.dart' as model;
import 'package:unop/providers/group_provider.dart';
import 'package:unop/providers/user_provider.dart';
import 'package:unop/resources/firestore_methods.dart';
import 'package:unop/screens/comments_screen.dart';
import 'package:unop/utils/colors.dart';
import 'package:unop/utils/global_variable.dart';
import 'package:unop/utils/utils.dart';
import 'package:unop/widgets/custom_box.dart';
import 'package:unop/widgets/like_animation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostCard extends StatefulWidget {
  final snap; // Snapshot containing post data
  final bool isFeed; // Flag to determine if it's in the feed

  const PostCard({Key? key, required this.snap, required this.isFeed})
      : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int commentLen = 0;
  bool isLikeAnimating = false;
  int activePage = 0;
  late PageController _pageController;
  late Size imageSizes; // Size of the image
  bool isLoading = true; // Loading state
  final TextEditingController _reportReasonController =
      TextEditingController(); // Controller for report reason input

  @override
  void initState() {
    super.initState();
    initializeAsyncData(); // Initializing data asynchronously
    _pageController = PageController(
        viewportFraction: 1, initialPage: 0); // Page controller for images
  }

  Future<void> initializeAsyncData() async {
    await fetchImageSizes(); // Fetching image sizes
    fetchCommentLen(); // Fetching comment length
    if (mounted) {
      setState(() {
        isLoading = false; // Set loading to false once data is fetched
      });
    }
  }

  AnimatedContainer slider(images, pagePosition, active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(images[pagePosition]),
          fit: BoxFit.fill, // Image covers the whole available space
        ),
      ),
    );
  }

  List<Widget> indicators(imagesLength, currentIndex) {
    return List<Widget>.generate(imagesLength, (index) {
      return Container(
        margin: const EdgeInsets.all(3),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: currentIndex == index ? Colors.white : Colors.black26,
            shape: BoxShape.circle),
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reportReasonController.dispose();
    super.dispose();
  }

  fetchCommentLen() async {
    // Fetch the number of comments for a post
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();
      commentLen = snap.docs.length;
      if (!mounted) return;
      setState(() {});
    } catch (err) {
      if (!mounted) return;
      showSnackBar(context, err.toString());
    }
  }

  fetchImageSizes() async {
    // Fetch the size of the first image in the post
    String imageUrl = widget.snap['postUrl'][0];
    Size size = await _getImageSize(imageUrl);
    if (!mounted) return;
    setState(() => imageSizes = size);
  }

  void reportPost(String userId, String postId, String reason) {
    // Logic to handle post reporting
    FireStoreMethods().reportPost(userId, postId, reason);
    print('Reported by user: $userId for post: $postId for reason: $reason');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'User reported successfully and we will act on objectionable content reports within 24 hours '),
      ),
    );
  }

  void showReportDialog(BuildContext context, String userId, String postId) {
    // Dialog for reporting a post
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Post'),
          content: TextField(
            controller: _reportReasonController,
            decoration:
                const InputDecoration(hintText: "Enter your reason here"),
            maxLines: null,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Report'),
              onPressed: () {
                final reason = _reportReasonController.text;
                Navigator.pop(context);
                reportPost(userId, postId, reason);
                _reportReasonController.clear();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _reportReasonController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopupMenu(BuildContext context, String userId, String postId) {
    // Popup menu for report and delete options
    return PopupMenuButton<String>(
      icon: Container(
        width: 40.0, // Set the desired width
        height: 40.0, // Set the desired height
        child: const Icon(
          Icons.report,
          color: Color.fromRGBO(255, 255, 255, 1),
          size: 30.0, // Set the desired icon size
        ),
      ),
      onSelected: (String result) {
        if (result == 'report') {
          showReportDialog(context, userId, postId);
        } else if (result == 'delete') {
          FireStoreMethods().deletePost(postId);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'report',
          child: Text('Report'),
        ),
        if (userId ==
            widget.snap[
                'uid']) // Show delete option only if the user is the post creator
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('Delete Post'),
          ),
      ],
    );
  }

  Future<Size> _getImageSize(String imageUrl) async {
    // Get size of an image from URL
    final ImageStream stream = CachedNetworkImageProvider(imageUrl)
        .resolve(const ImageConfiguration());
    final Completer<Size> completer = Completer<Size>();
    void listener(ImageInfo info, bool _) {
      completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble()));
    }

    stream.addListener(ImageStreamListener(listener));
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    UserProvider().refreshUser();
    final model.User? user = Provider.of<UserProvider>(context).getUser;

    final Group? currentGroup = Provider.of<GroupProvider>(context).getGroup;
    final String currentGroupId =
        Provider.of<GroupProvider>(context).getGroupId;

    final width = MediaQuery.of(context).size.width;
    if (widget.isFeed) {
      if (currentGroupId == "All") {
        if (widget.snap['groupId'] is List &&
            user?.group != null &&
            user!.group.isNotEmpty) {
          bool hasCommonElement = widget.snap['groupId']
              .any((aElement) => user!.group.contains(aElement));
          if (!hasCommonElement) {
            return Container();
          }
        }
      } else {
        if (!widget.snap['groupId']?.contains(currentGroup?.groupid)) {
          return Container();
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: width > webScreenSize ? secondaryColor : mobileBackgroundColor,
        ),
        color: mobileBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // IMAGE SECTION OF THE POST
          GestureDetector(
              onDoubleTap: () {
                if (user != null) {
                  FireStoreMethods().likePost(
                    widget.snap['postId'].toString(),
                    user.uid,
                    widget.snap['likes'],
                  );
                  setState(() {
                    isLikeAnimating = true;
                  });
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomBox(
                    child: Column(
                      children: [
                        // Report Button
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: imageSizes != null
                                ? MediaQuery.of(context).size.width *
                                    (imageSizes.height / imageSizes.width)
                                : 200, // Set a default height or adjust as needed // Fallback height if imageSizes is null, // Calculate the height keeping the aspect ratio,
                            child: PageView.builder(
                                itemCount: widget.snap['postUrl'].length,
                                pageSnapping: true,
                                controller: _pageController,
                                onPageChanged: (page) {
                                  setState(() {
                                    activePage = page;
                                  });
                                },
                                itemBuilder: (context, pagePosition) {
                                  bool active = pagePosition == activePage;
                                  return slider(widget.snap['postUrl'],
                                      pagePosition, active);
                                }),
                          ),
                        ),

                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: indicators(
                                widget.snap['postUrl'].length, activePage)),
                        Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center, // Aligns children vertically to the center
                                    children: <Widget>[
                                      Container(
                                        width: 32, // Width of the square
                                        height: 32, // Height of the square
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: CachedNetworkImageProvider(
                                              widget.snap['profImage']
                                                  .toString(), // The image URL
                                              // You can add errorListener if you want to handle errors
                                            ),
                                            fit: BoxFit
                                                .cover, // Ensures the image covers the container
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              4), // Optional: if you want rounded corners
                                          // You can add more styling as needed
                                        ),
                                      ),
                                      const SizedBox(
                                          width:
                                              8), // Add space between the avatar and the text
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            widget.snap['username'].toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          // You can add more widgets here if needed
                                        ],
                                      ),
                                    ],
                                  ),

                                  //const SizedBox(height: 5),
                                ],
                              ),

                              // LIKE, COMMENT SECTION OF THE POST
                              Row(
                                children: <Widget>[
                                  // Comment Icon and Text
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // Aligns children to the center of the column

                                    children: [
                                      IconButton(
                                        icon:
                                            const Icon(Icons.comment_outlined),
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CommentsScreen(
                                              postId: widget.snap['postId']
                                                  .toString(),
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                            15,
                                            0,
                                            15,
                                            0), // Remove padding inside IconButton
                                        constraints:
                                            const BoxConstraints(), // Remove additional constraints
                                      ),
                                      Text('$commentLen '),
                                    ],
                                  ),

                                  // Like Icon and Text
                                  Column(
                                    children: [
                                      LikeAnimation(
                                        isAnimating: user != null &&
                                                widget.snap['likes']
                                                    .contains(user.uid)
                                            ? true
                                            : false,
                                        smallLike: true,
                                        child: IconButton(
                                          icon: widget.snap['likes']
                                                  .contains(user?.uid)
                                              ? const Icon(Icons.favorite,
                                                  color: Colors.red)
                                              : const Icon(
                                                  Icons.favorite_border),
                                          onPressed: () {
                                            if (user != null) {
                                              FireStoreMethods().likePost(
                                                widget.snap['postId']
                                                    .toString(),
                                                user.uid,
                                                widget.snap['likes'],
                                              );
                                            }
                                          },
                                          padding: const EdgeInsets.fromLTRB(
                                              0,
                                              0,
                                              0,
                                              0), // Remove padding inside IconButton
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                      Text('${widget.snap['likes'].length} '),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.04, // Adjust the height as needed
                          width: MediaQuery.of(context).size.width * 0.6,

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Align children to the start of the cross axis
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment
                                      .centerLeft, // Align text to the left
                                  child: Text(
                                    ' ${widget.snap['description']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: null,
                                    overflow: TextOverflow.clip,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildPopupMenu(
                      context,
                      user?.uid ??
                          "", // Provide a default value when user?.uid is null
                      widget.snap['postId'],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isLikeAnimating ? 1 : 0,
                    child: LikeAnimation(
                      isAnimating: isLikeAnimating,
                      duration: const Duration(
                        milliseconds: 400,
                      ),
                      onEnd: () {
                        setState(() {
                          isLikeAnimating = false;
                        });
                      },
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                  ),
                ],
              )),

          //DESCRIPTION AND NUMBER OF COMMENTS
          Container(
            // Apply padding as needed
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // This spreads out the children across the horizontal axis
              children: <Widget>[
                // Left-aligned child (View all comments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    DateFormat.yMMMd()
                        .format(widget.snap['datePublished'].toDate()),
                    style: const TextStyle(
                      color: secondaryColor,
                    ),
                  ),
                ),

                // Right-aligned child (Date Published)
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CommentsScreen(
                        postId: widget.snap['postId'].toString(),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'View all $commentLen comments',
                      style: const TextStyle(
                        fontSize: 16,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
