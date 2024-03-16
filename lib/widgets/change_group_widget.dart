import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unop/main.dart';
import 'package:unop/providers/group_provider.dart';
import 'package:unop/providers/user_provider.dart';
import 'package:unop/responsive/mobile_screen_layout.dart';
import 'package:unop/screens/group_profile_screen.dart';
import 'package:unop/screens/group_signup_screen.dart';
import 'package:unop/screens/profile_screen.dart';

enum Options { create, upload, copy, exit }

class ChangeGroupScreen extends StatefulWidget {
  const ChangeGroupScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChangeGroupScreenState createState() => _ChangeGroupScreenState();
}

class _ChangeGroupScreenState extends State<ChangeGroupScreen> {
  //final CategoriesScroller categoriesScroller = CategoriesScroller();
  ScrollController controller = ScrollController();
  final TextEditingController searchController = TextEditingController();

  bool closeTopContainer = false;
  double topContainer = 0;
  bool isSearching = false;
  bool isShowGroups = false;

  var appBarHeight = AppBar().preferredSize.height;

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
    controller.dispose();
  }

  Widget getPostsData(String groupName, String photoUrl, String bio) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 10.0),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              groupName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CachedNetworkImage(
                    imageUrl: photoUrl,
                    height: 100,
                    width: 100, // Specify the height for the image
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(), // Shown while the image is loading
                    errorWidget: (context, url, error) => const Icon(
                        Icons.error), // Shown if the image fails to load
                    fit: BoxFit.fill, // Adjust as needed
                  ),
                  const SizedBox(width: 10), // Space between image and text
                  Expanded(
                    // To prevent overflow of long text
                    child: Text(
                      "bio : $bio",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ]),
          ],
        ),
      ),
    );
  }

  PopupMenuItem _buildPopupMenuItem(
      String title, IconData iconData, int position) {
    return PopupMenuItem(
      value: position,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(
            iconData,
            color: Colors.black,
          ),
          Text(title),
        ],
      ),
    );
  }

  _onMenuItemSelected(int value) {
    setState(() {});

    if (value == Options.create.index) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const GroupSignupScreen(),
        ),
      );
    } else if (value == Options.upload.index) {
    } else if (value == Options.copy.index) {
    } else {}
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      double value = controller.offset / 119;

      setState(() {
        topContainer = value;
        closeTopContainer = controller.offset > 50;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double categoryHeight = size.height * 0.01;
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            // leading: PopupMenuButton(
            //   icon: const Icon(
            //     Icons.menu,
            //     color: Colors.black,
            //   ),
            //   onSelected: (value) {
            //     _onMenuItemSelected(value as int);
            //   },
            //   offset: Offset(0.0, appBarHeight),
            //   shape: const RoundedRectangleBorder(
            //     borderRadius: BorderRadius.only(
            //       bottomLeft: Radius.circular(8.0),
            //       bottomRight: Radius.circular(8.0),
            //       topLeft: Radius.circular(8.0),
            //       topRight: Radius.circular(8.0),
            //     ),
            //   ),
            //   itemBuilder: (ctx) => [
            //     _buildPopupMenuItem(
            //         'Create', Icons.group_add, Options.create.index),
            //     _buildPopupMenuItem(
            //         'Upload', Icons.group_add, Options.upload.index),
            //     _buildPopupMenuItem('Copy', Icons.copy, Options.copy.index),
            //     _buildPopupMenuItem(
            //         'Exit', Icons.exit_to_app, Options.exit.index),
            //   ],
            // ),
            title: !isSearching
                ? const Center(
                    child: Text(
                    'Search Groups',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ))
                : Form(
                    child: TextFormField(
                      controller: searchController,
                      decoration: InputDecoration(
                        //prefixIcon: const Icon(Icons.person),
                        prefixIconColor: MaterialStateColor.resolveWith(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.focused)) {
                            return Colors.green;
                          }
                          if (states.contains(MaterialState.error)) {
                            return Colors.red;
                          }
                          return Colors.grey;
                        }),
                        hoverColor: Colors.black,
                      ),
                      onFieldSubmitted: (String _) {
                        setState(() {
                          isShowGroups = true;
                        });
                      },
                    ),
                  ),
            actions: <Widget>[
              isSearching
                  ? IconButton(
                      icon: const Icon(Icons.search, color: Colors.black),
                      onPressed: () => {
                        setState(() {
                          isSearching = false;
                        })
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.search, color: Colors.black),
                      onPressed: () => {
                        setState(() {
                          isSearching = true;
                        })
                      },
                    ),
            ],
          ),
          body: isShowGroups
              ? FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('group')
                      .where(
                        'groupName',
                        isGreaterThanOrEqualTo: searchController.text,
                      )
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ListView.builder(
                      itemCount: (snapshot.data! as dynamic).docs.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  uid: (snapshot.data! as dynamic).docs[index]
                                      ['uid'],
                                ),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundImage: CachedNetworkImageProvider(
                                (snapshot.data! as dynamic).docs[index]
                                    ['photoUrl'],
                                // You can add errorListener if you want to handle errors
                              ),
                            ),
                            title: Text(
                              (snapshot.data! as dynamic).docs[index]
                                  ['groupName'],
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
              : FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('group')
                      .where(
                        'groupName',
                        isGreaterThanOrEqualTo: searchController.text,
                      )
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // Filter the documents based on your condition
                    var filteredDocs =
                        (snapshot.data! as dynamic).docs.where((doc) {
                      return (doc['member'] as List<dynamic>)
                          .contains(userProvider.getUser?.uid);
                    }).toList();

                    return SizedBox(
                      height: size.height,
                      child: Column(
                        children: <Widget>[
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              // Text(
                              //   "Groups",
                              //   style: TextStyle(
                              //       color: Colors.grey,
                              //       fontWeight: FontWeight.bold,
                              //       fontSize: 20),
                              // ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: closeTopContainer ? 0 : 1,
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: size.width,
                                alignment: Alignment.topCenter,
                                height: closeTopContainer ? 0 : categoryHeight,
                                child: null),
                          ),
                          Expanded(
                              child: ListView.builder(
                                  controller: controller,
                                  itemCount: filteredDocs.length,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    double scale = 1.0;
                                    // if (topContainer > 0.5) {
                                    //   scale = index + 0.5 - topContainer;
                                    //   if (scale < 0) {
                                    //     scale = 0;
                                    //   } else if (scale > 1) {
                                    //     scale = 1;
                                    //   }
                                    // }

                                    return Stack(
                                      alignment: Alignment
                                          .topCenter, // Adjust this to position your button
                                      children: [
                                        Opacity(
                                            opacity: scale,
                                            child: Transform(
                                              transform: Matrix4.identity()
                                                ..scale(scale, scale),
                                              alignment: Alignment.bottomCenter,
                                              child: Align(
                                                heightFactor: 0.7,
                                                alignment: Alignment.topCenter,
                                                child: InkWell(
                                                    onTap: () {
                                                      Future.delayed(
                                                          Duration.zero,
                                                          () async {
                                                        // Run your function or perform logic when the widget is initialized
                                                        GroupProvider
                                                            groupProvider =
                                                            Provider.of<
                                                                    GroupProvider>(
                                                                context,
                                                                listen: false);
                                                        await groupProvider
                                                            .setCurrnetGroupId(
                                                                filteredDocs[
                                                                        index][
                                                                    'groupid']);
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: getPostsData(
                                                        filteredDocs[index]
                                                            ['groupName'],
                                                        filteredDocs[index]
                                                            ['photoUrl'],
                                                        filteredDocs[index]
                                                            ['bio'])),
                                              ),
                                            )),
                                        Positioned(
                                          top:
                                              20, // Vertical position from the top
                                          right:
                                              20, // Horizontal position from the right
                                          child: IconButton(
                                            icon: const Icon(Icons
                                                .speaker_group_outlined), // Replace with your desired icon
                                            iconSize:
                                                30, // Adjust the icon size as needed
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      GroupProfileScreen(
                                                    groupid: filteredDocs[index]
                                                        ['groupid'],
                                                  ),
                                                ),
                                              );
                                              // mainNavigatorKey.currentState
                                              //     ?.popUntil(
                                              //         (route) => route.isFirst);
                                              // mainNavigatorKey.currentState!
                                              //     .push(MaterialPageRoute(
                                              //   builder: (context) =>
                                              //       GroupProfileScreen(
                                              //           groupid:
                                              //               filteredDocs[index]
                                              //                   ['groupid']),
                                              // ));
                                              // mainNavigatorKey.currentState!
                                              //     .pop();
                                              //Navigator.of(context).pop();
                                            },
                                            color: Colors.black, // Icon color
                                            tooltip:
                                                'Your Tooltip Text', // Optional tooltip text
                                          ),
                                        ),
                                      ],
                                    );
                                  })),
                        ],
                      ),
                    );
                  },
                )),
    );
  }
}
