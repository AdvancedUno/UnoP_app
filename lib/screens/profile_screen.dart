import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unop/main.dart';
import 'package:unop/resources/auth_methods.dart';
import 'package:unop/resources/firestore_methods.dart';
import 'package:unop/responsive/mobile_screen_layout.dart';
import 'package:unop/screens/edit_profile_screen.dart';
import 'package:unop/screens/group_signup_screen.dart';
import 'package:unop/screens/login_screen.dart';
import 'package:unop/utils/colors.dart';
import 'package:unop/utils/utils.dart';
import 'package:unop/widgets/follow_button.dart';
import 'package:unop/widgets/group_card.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Variables to store user data and statistics.
  var userData = {}; // Holds user data fetched from Firestore.
  int postLen = 0; // Tracks the number of posts by the user.
  int followers = 0; // Tracks the number of followers.
  int following = 0; // Tracks the number of following.
  int groups = 0; // Tracks the number of groups.
  bool isFollowing =
      false; // Flag to check if the current user is following the profile user.
  bool isLoading = false; // Flag for loading state when data is being fetched.
  bool isFavorite = true;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    getData();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Method to fetch user data and post statistics from Firebase Firestore.
  getData() async {
    setState(() {
      isLoading =
          true; // Set to true to show a loading indicator on the screen.
    });
    try {
      // Fetch user data from Firestore.
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      // Fetch user's posts to calculate the total number of posts.
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      // Extracting and updating the state with user data and post statistics.
      postLen = postSnap.docs.length; // Number of posts.
      userData = userSnap.data()!; // User's profile data.
      followers = userSnap.data()!['followers'].length; // Number of followers.
      following = userSnap.data()!['following'].length; // Number of following.
      groups = userSnap.data()!['group'].length;
      isFollowing = userSnap.data()!['followers'].contains(FirebaseAuth
          .instance.currentUser!.uid); // Check if current user is a follower.

      setState(() {}); // Trigger a rebuild with updated data.
    } catch (e) {
      // Error handling: display an error message in a snackbar.
      showSnackBar(
        context,
        e.toString(),
      );
    }
    setState(() {
      isLoading = false; // Reset loading state after data fetching is complete.
    });
  }

  /// Function to build a card widget with onPress functionality followed by a text section.
  Widget buildCard(DocumentSnapshot snap) {
    // Column widget to arrange elements vertically.
    return GroupCard(
      snap: snap,
      userData: userData,
      onLikePressed: () async {
        String groupId = snap["groupid"].toString();
        List<dynamic> likeGroup = List<dynamic>.from(userData["likeGroup"]);

        if (likeGroup.contains(groupId)) {
          likeGroup.remove(groupId);
        } else {
          likeGroup.add(groupId);
        }

        // Update Firestore and local state
        await FireStoreMethods().likeGroup(groupId, widget.uid, likeGroup);
        userData["likeGroup"] = likeGroup;
      },
    );
  }

  Widget _buildGroupTab() {
    return FutureBuilder(
      // FutureBuilder to asynchronously build the grid of posts.
      future: FirebaseFirestore.instance
          .collection('group')
          .where('member', arrayContains: widget.uid)
          .get(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(), // Shows a spinner while posts are loading.
          );
        }

        // GridView.builder to create a grid layout of posts.
        return GridView.builder(
          shrinkWrap: true,
          itemCount: (snapshot.data! as dynamic).docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Number of items in a row.
            crossAxisSpacing: 6, // Horizontal space between items.
            mainAxisSpacing: 2, // Vertical space between items.
            childAspectRatio: 0.8, // Aspect ratio for items.
          ),
          itemBuilder: (context, index) {
            DocumentSnapshot snap = (snapshot.data! as dynamic).docs[index];
            // Building each item in the grid.
            return buildCard(snap);
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    // For the Settings tab, let's create a simple list of settings options.
    // You can add more settings options as per your app's functionality.
    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.edit),
          title: Text('Edit Profile'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                    userData: userData as Map<String, dynamic>),
              ),
            );
          },
        ),

        ListTile(
          leading: Icon(Icons.report),
          title: Text('Report User'),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Report User'),
                content: TextField(
                  controller:
                      TextEditingController(), // Controller to capture reason input
                  onChanged: (value) {
                    // Store the reason input
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter reason for reporting',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      try {
                        String reason =
                            ''; // Retrieve the reason from the text field
                        // Perform reporting action

                        await FireStoreMethods().reportPost(userData['uid'],
                            FirebaseAuth.instance.currentUser!.uid, reason);
                        Navigator.of(context).pop(); // Close the dialog
                        // Show a confirmation message to the user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'User reported successfully and we will act on objectionable content reports within 24 hours '),
                          ),
                        );
                      } catch (e) {
                        // Handle/report error
                      }
                    },
                    child: Text('Report'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.block),
          title: Text('Block User'),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Block User'),
                content: Text('Are you sure you want to block this user?'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      try {
                        // Perform block user action
                        await FireStoreMethods().blockUser(
                          userData['uid'],
                          FirebaseAuth.instance.currentUser!.uid,
                        );
                        Navigator.of(context).pop(); // Close the dialog
                        // Show a confirmation message to the user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User blocked successfully'),
                          ),
                        );
                      } catch (e) {
                        // Handle/block error
                      }
                    },
                    child: Text('Block'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        ),

        /////////////////////////////////////////////////////
        //Implement future

        // ListTile(
        //   leading: Icon(Icons.security),
        //   title: Text('Privacy Settings'),
        //   onTap: () {
        //     // Navigate to privacy settings screen or perform other actions
        //   },
        // ),
        // ListTile(
        //   leading: Icon(Icons.notifications),
        //   title: Text('Notifications'),
        //   onTap: () {
        //     // Navigate to notifications settings screen or perform other actions
        //   },
        // ),
        /////////////////////////////////////////////////////

        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Log Out'),
          onTap: () async {
            try {
              // Perform logout operation
              await FirebaseAuth.instance.signOut();

              // Navigator.of(context).popUntil((route) => route.isFirst);
              // // Navigate to LoginScreen and remove all routes from the stack
              // Navigator.of(context).pushAndRemoveUntil(
              //     MaterialPageRoute(builder: (context) => const LoginScreen()),
              //     (route) => false);

              mainNavigatorKey.currentState?.popUntil((route) => route.isFirst);
              mainNavigatorKey.currentState?.push(
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            } catch (e) {
              // If an error occurs, show an AlertDialog or a SnackBar
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to log out: $e'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                  ],
                ),
              );
            }
          },
        ),

        ListTile(
          leading: Icon(Icons.delete),
          title: Text('Delete account'),
          onTap: () {
            AuthMethods().deleteUserAccount();
            mainNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            mainNavigatorKey.currentState?.push(
                MaterialPageRoute(builder: (context) => const LoginScreen()));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Building the UI for the ProfileScreen.
    return isLoading
        ? const Center(
            child:
                CircularProgressIndicator(), // Shows a loading indicator while data is loading.
          )
        : Scaffold(
            // Setting the background color based on screen size (responsive design)
            backgroundColor: mobileBackgroundColor,
            // Main UI for the profile screen, displayed only when the data is not loading.
            appBar: AppBar(
              backgroundColor:
                  appbarColor, // Sets the background color of the AppBar.
              title: SizedBox(
                height: 130,
                width: 200,
                child: Image.asset(
                  'assets/UnoP.png',
                  fit: BoxFit.contain,
                ),
              ),
              centerTitle: true, // Aligns the title to the start (left).
            ),
            body: RefreshIndicator(
                onRefresh: () async {
                  await getData(); // Refresh your data
                },
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(
                          16), // Adds padding around the column.
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width:
                                    80, // Width of the square, double the radius
                                height:
                                    80, // Height of the square, double the radius
                                decoration: BoxDecoration(
                                  image: userData['photoUrl'] != null
                                      ? DecorationImage(
                                          image: CachedNetworkImageProvider(
                                              userData['photoUrl']),
                                          fit: BoxFit
                                              .cover, // Ensures the image covers the container
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: userData['photoUrl'] == null
                                    ? const CircularProgressIndicator() // Shows a spinner if the image is not loaded
                                    : null,
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        buildStatColumn(postLen,
                                            "posts"), // Displays the number of posts.
                                        // buildStatColumn(followers,
                                        //     "followers"), // Displays the number of followers.
                                        buildStatColumn(groups,
                                            "groups"), // Displays the number of following.
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Conditional rendering of Follow/Unfollow or Sign Out button.
                                        FirebaseAuth.instance.currentUser!
                                                    .uid ==
                                                widget.uid
                                            ? Container()
                                            : isFollowing
                                                ? FollowButton(
                                                    // Unfollow button if the current user is following this profile.
                                                    text: 'Unfollow',
                                                    backgroundColor:
                                                        Colors.white,
                                                    textColor: Colors.black,
                                                    borderColor: Colors.grey,
                                                    function: () async {
                                                      await FireStoreMethods()
                                                          .followUser(
                                                        FirebaseAuth.instance
                                                            .currentUser!.uid,
                                                        userData['uid'],
                                                      );

                                                      setState(() {
                                                        isFollowing = false;
                                                        followers--;
                                                      });
                                                    },
                                                  )
                                                : FollowButton(
                                                    // Follow button if the current user is not following this profile.
                                                    text: 'Follow',
                                                    backgroundColor:
                                                        Colors.blue,
                                                    textColor: Colors.white,
                                                    borderColor: Colors.blue,
                                                    function: () async {
                                                      await FireStoreMethods()
                                                          .followUser(
                                                        FirebaseAuth.instance
                                                            .currentUser!.uid,
                                                        userData['uid'],
                                                      );

                                                      setState(() {
                                                        isFollowing = true;
                                                        followers++;
                                                      });
                                                    },
                                                  )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(top: 15),
                            child: Text(
                              userData['username'], // Displays the username.
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              userData['bio'],
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ), // Displays the user's bio.
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.grey
                          .shade200, // Sets the background color of the tab bar
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors
                            .grey.shade700, // Sets the color of the text labels
                        indicatorColor: Colors.grey
                            .shade700, // Optional: Sets the color of the indicator line
                        tabs: const [
                          Tab(text: 'Group'),
                          Tab(text: 'Settings'),
                        ],
                      ),
                    ),
                    //const Divider(), // A divider for visual separation.

                    Container(
                      height: 420, // Adjust the height as needed
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGroupTab(),
                          _buildSettingsTab(),
                        ],
                      ),
                    ),
                  ],
                )),
            floatingActionButton: SizedBox(
              width: 50, // Set the width of the FAB
              height: 50, // Set the height of the FAB
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GroupSignupScreen(),
                    ),
                  );
                }, // Example icon, change as needed
                backgroundColor: Colors.grey,

                child: const Icon(Icons.add, size: 40), // White color for FAB
                // You can adjust padding if needed
              ),
            ),

            floatingActionButtonLocation: FloatingActionButtonLocation
                .endFloat, // Position at bottom left
          );
  }

  // Helper method to build columns for user statistics.
  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
