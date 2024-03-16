import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unop/resources/firestore_methods.dart';
import 'package:unop/screens/manage_member_screen.dart';
import 'package:unop/screens/post_screen.dart';
import 'package:unop/utils/colors.dart';
import 'package:unop/utils/utils.dart';
import 'package:unop/widgets/custom_box.dart';
import 'package:unop/widgets/follow_button.dart';

class GroupProfileScreen extends StatefulWidget {
  final String groupid;
  const GroupProfileScreen({Key? key, required this.groupid}) : super(key: key);

  @override
  State<GroupProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<GroupProfileScreen>
    with SingleTickerProviderStateMixin {
  var groupData = {}; // Map to store group data.
  int postLen = 0; // Stores the number of posts in the group.
  int members =
      1; // Stores the number of members in the group, initialized to 1.
  bool isAdmin = false; // New flag for admin check

  bool isMember = false; // Flag to check if the current user is a member.
  bool isLoading = false; // Indicates whether data is being loaded.
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    getData(); // Calls getData method when the state is initialized.
    //_tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var groupSnap = await FirebaseFirestore.instance
          .collection('group')
          .doc(widget.groupid)
          .get();

      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupId', arrayContains: widget.groupid)
          .get();

      postLen = postSnap.docs.length;
      groupData = groupSnap.data()!;
      members = groupSnap.data()!['member'].length;
      isMember = groupSnap
          .data()!['member']
          .contains(FirebaseAuth.instance.currentUser!.uid);
      isAdmin = groupData['admin']
          .contains(FirebaseAuth.instance.currentUser!.uid); // Check for admin

      // Initialize TabController based on admin status
      _tabController = TabController(length: isAdmin ? 2 : 1, vsync: this);

      setState(() {});
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildGroupPostTab() {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('posts')
          .where('groupId', arrayContains: widget.groupid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData) {
          return const Text('No data available');
        }

        QuerySnapshot querySnapshot = snapshot.data as QuerySnapshot;
        List<Map<String, dynamic>> posts = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // Sort the posts by 'datePublished' in descending order
        posts.sort((a, b) {
          DateTime dateA = (a['datePublished'] as Timestamp).toDate();
          DateTime dateB = (b['datePublished'] as Timestamp).toDate();
          return dateB
              .compareTo(dateA); // Note the swapped order for descending sort
        });

        return GridView.builder(
          shrinkWrap: true,
          itemCount: posts.length, // Use the length of the sorted 'posts' list
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 1.5,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            var post = posts[index]; // Use the sorted 'post' for each index

            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostsScreen(
                      posts: posts,
                      desiredIndex: index,
                    ),
                  ),
                );
              },
              child: CustomBox(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image(
                    image: CachedNetworkImageProvider(
                      post['postUrl'][0], // Use 'post' from the sorted list
                    ),
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                    frameBuilder: (BuildContext context, Widget child,
                        int? frame, bool wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded || frame != null) {
                        return child;
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(
            Icons.edit,
            color: Colors.black,
          ),
          title: const Text('Manage Group'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    ManagePermissionsScreen(groupId: widget.groupid),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.security,
            color: Colors.black,
          ),
          title: const Text('Group Setting'),
          onTap: () {},
        ),
        // ListTile(
        //   leading: Icon(Icons.notifications),
        //   title: Text('Notifications'),
        //   onTap: () {},
        // ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child:
                CircularProgressIndicator(), // Show loading indicator while data is loading.
          )
        : Scaffold(
            backgroundColor: mobileBackgroundColor,
            appBar: AppBar(
              backgroundColor: appbarColor,
              title: const Text(
                'G R O U P', // Group name in the AppBar.
              ),
              centerTitle: false,
            ),
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 80, // Width of the square, double the radius
                            height:
                                80, // Height of the square, double the radius
                            decoration: BoxDecoration(
                              image: groupData['photoUrl'] != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          groupData['photoUrl']),
                                      fit: BoxFit
                                          .cover, // Ensures the image covers the container
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: groupData['photoUrl'] == null
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
                                        "posts"), // Displaying number of posts.
                                    buildStatColumn(members,
                                        "members"), // Displaying number of members.
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Follow/Unfollow button based on the membership status.
                                    isMember
                                        ? FollowButton(
                                            text: 'Unfollow',
                                            backgroundColor: Colors.white,
                                            textColor: Colors.black,
                                            borderColor: Colors.grey,
                                            function: () async {
                                              await FireStoreMethods()
                                                  .followGroup(
                                                      FirebaseAuth.instance
                                                          .currentUser!.uid,
                                                      widget.groupid);

                                              setState(() {
                                                isMember = false;
                                                members--;
                                              });
                                            },
                                          )
                                        : FollowButton(
                                            text: 'Follow',
                                            backgroundColor: Colors.brown,
                                            textColor: Colors.white,
                                            borderColor: Colors.brown,
                                            function: () async {
                                              FireStoreMethods().followGroup(
                                                  FirebaseAuth.instance
                                                      .currentUser!.uid,
                                                  widget.groupid);
                                              setState(() {
                                                isMember = true;
                                                members++;
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
                        padding: const EdgeInsets.only(
                          top: 15,
                        ),
                        child: Text(
                          groupData['groupName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          top: 1,
                        ),
                        child: Text(
                          groupData['bio'],
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.grey.shade200,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.grey.shade700,
                    indicatorColor: Colors.grey.shade700,
                    tabs: [
                      const Tab(text: 'Group'),
                      if (isAdmin)
                        const Tab(text: 'Settings'), // Show if isAdmin is true
                    ],
                  ),
                ),
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGroupPostTab(),
                      if (isAdmin)
                        _buildSettingsTab(), // Show if isAdmin is true
                    ],
                  ),
                ),
              ],
            ),
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
