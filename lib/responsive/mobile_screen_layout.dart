import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:unop/main.dart';
import 'package:unop/providers/user_provider.dart';
import 'package:unop/screens/add_post_screen.dart';
import 'package:unop/screens/bottom_sheet_screen.dart';
import 'package:unop/screens/feed_screen.dart';
import 'package:unop/screens/profile_screen.dart';
import 'package:unop/screens/search_screen.dart';
import 'package:unop/widgets/change_group_widget.dart';
import 'package:unop/utils/colors.dart';

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({Key? key}) : super(key: key);

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  List<Widget> homeScreenItems = [
    const FeedScreen(),
    const SearchScreen(),
    ProfileScreen(
      uid: FirebaseAuth.instance.currentUser!.uid,
    ),
    AddPostScreen(),
    ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)
    //GroupProfileScreen(groupid: FirebaseAuth.instance.currentUser!.uid)
  ];

  int _page = 0;
  PageController? pageController; // for tabs animation

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController?.dispose();
    // Do not manually dispose mainNavigatorKey.currentState
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    if (page == 3) {
      showModalBottomSheet<int>(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) {
          return const BottomSheetScreen(child: ChangeGroupScreen());
        },
      );
      return;
    } else if (page == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(
          //builder: (context) => const AddPostScreen(),
          builder: (context) => AddPostScreen(),
        ),
      );
    } else {
      // Check if there are screens above the main screen in the navigation stack
      if (mainNavigatorKey.currentState?.canPop() ?? false) {
        mainNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }

      // Then, navigate to the selected page with null-aware operation
      pageController?.jumpToPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            builder: (BuildContext context) {
              return PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: pageController,
                onPageChanged: (int page) {
                  if (page != 2) {
                    setState(() => _page = page);
                    UserProvider().refreshUser();
                  }
                },
                children: homeScreenItems,
              );
            },
          );
        },
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: mobileBackgroundColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: (_page == 0) ? primaryColor : secondaryColor,
            ),
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.search,
                color: (_page == 1) ? primaryColor : secondaryColor,
              ),
              backgroundColor: primaryColor),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_box,
              color: (_page == 2) ? primaryColor : secondaryColor,
            ),
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.groups_2_rounded,
                color: (_page == 3) ? primaryColor : secondaryColor,
              ),
              backgroundColor: primaryColor),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: (_page == 4) ? primaryColor : secondaryColor,
            ),
            backgroundColor: primaryColor,
          ),
        ],
        onTap: navigationTapped,
        currentIndex: _page,
      ),
    );
  }
}
