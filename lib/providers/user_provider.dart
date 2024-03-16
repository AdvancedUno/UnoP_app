import 'package:flutter/widgets.dart';
import 'package:unop/models/user.dart' as model;
import 'package:unop/resources/auth_methods.dart';

class UserProvider with ChangeNotifier {
  model.User? _user;
  final AuthMethods _authMethods = AuthMethods();

  model.User? get getUser => _user;

  Future<void> refreshUser() async {
    try {
      model.User user = await _authMethods.getUserDetails();

      _user = user;
      notifyListeners();
    } catch (e) {
      // Handle error fetching user details
      print('Error fetching user details: $e');
    }
  }
}
