import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:unop/providers/group_provider.dart';

import 'package:unop/utils/colors.dart';
import 'package:unop/utils/global_variable.dart';
import 'package:unop/widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      GroupProvider groupProvider =
          Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.setCurrnetGroupId("All");
    });

    // // Initializing state and fetching data
    // Future.delayed(Duration.zero, () async {
    //   // Delayed execution to interact with the context after the widget build is complete
    //   GroupProvider groupProvider =
    //       Provider.of<GroupProvider>(context, listen: false);
    //   await groupProvider.setCurrnetGroupId(
    //       "All"); // Resetting or setting the current group ID
    // });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width; // Getting screen width

    // Building the UI of the screen
    return Scaffold(
      // Setting the background color based on screen size (responsive design)
      backgroundColor:
          width > webScreenSize ? webBackgroundColor : mobileBackgroundColor,

      // Conditional AppBar: Displayed only for narrower (mobile) screens
      appBar: width > webScreenSize
          ? null
          : AppBar(
              toolbarHeight: 50,
              backgroundColor: appbarColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Invisible button to balance the AppBar design
                  Opacity(
                    opacity: 0.0,
                    child: IconButton(
                      icon: const Icon(Icons.messenger_outline),
                      onPressed: () {},
                    ),
                  ),
                  // App logo or title image
                  SizedBox(
                    height: 68,
                    width: 68,
                    child: Image.asset(
                      'assets/UnoP_logo.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  // Action button on the AppBar
                  Opacity(
                    opacity: 0.0,
                    child: IconButton(
                      icon: const Icon(Icons.messenger_outline),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),

      // Main content of the screen: a list of posts
      body: StreamBuilder(
        // Fetching posts data in real-time
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            ); // Showing a loading indicator while data is being fetched
          } else {}

          // Building a list of post widgets
          return ListView.builder(
            itemCount: snapshot.data!.docs.length, // Number of posts
            itemBuilder: (ctx, index) => Container(
              // Styling each post
              margin: EdgeInsets.symmetric(
                horizontal: width > webScreenSize ? width * 0.3 : 0,
                vertical: width > webScreenSize ? 15 : 0,
              ),
              child: PostCard(
                isFeed: true,
                snap: snapshot.data!.docs[index].data(), // Data for each post
              ),
            ),
          );
        },
      ),
    );
  }
}
