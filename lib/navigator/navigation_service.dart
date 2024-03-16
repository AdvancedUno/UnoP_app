import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unop/providers/group_provider.dart';
import 'package:unop/providers/user_provider.dart';
import 'package:unop/responsive/mobile_screen_layout.dart';
import 'package:unop/responsive/responsive_layout.dart';
import 'package:unop/responsive/web_screen_layout.dart';
import 'package:unop/screens/login_screen.dart';
import 'package:provider/provider.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();
  Future<dynamic>? navigateTo(String routeName) {
    return navigatorKey.currentState?.pushNamed(routeName);
  }
}
