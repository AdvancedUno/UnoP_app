import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unop/providers/user_provider.dart';
import 'package:unop/screens/add_post_screen.dart';
import 'package:unop/screens/feed_screen.dart';
import 'package:unop/screens/profile_screen.dart';
import 'package:unop/screens/search_screen.dart';

const webScreenSize = 600;

List<Widget> homeScreenItems = [
  const FeedScreen(),
  const SearchScreen(),
  ProfileScreen(
    uid: UserProvider().getUser!.uid,
  ),
  AddPostScreen(),
  ProfileScreen(uid: UserProvider().getUser!.uid)
  //GroupProfileScreen(groupid: FirebaseAuth.instance.currentUser!.uid)
];
