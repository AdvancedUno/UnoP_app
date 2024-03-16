import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unop/models/group.dart';
import 'package:unop/resources/firestore_methods.dart';

class GroupProvider with ChangeNotifier {
  String? _currentGroupId;
  List? _selectedGroups;

  Group? _currentGroup;

  String get getGroupId => _currentGroupId!;

  Group? get getGroup => _currentGroup;
  List? get getSelectedGroups => _selectedGroups;

  Future<void> setCurrnetGroupId(String? selectedGroupId) async {
    if (selectedGroupId == "All") {
      _currentGroupId = selectedGroupId;
    } else {
      Group group = await FireStoreMethods().getGroupDetails(selectedGroupId);
      _currentGroup = group;
      _currentGroupId = group.groupid;
    }

    notifyListeners();
  }

  List<Group> _allGroups = []; // List to store all groups

  // Getter to access all groups
  List<Group> get allGroups => _allGroups;

  // Method to fetch all groups from Firestore
  Future<void> fetchAllGroups() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('group').get();

      _allGroups = snapshot.docs
          .map((doc) => Group.fromSnap(doc))
          .toList(); // Convert each document to a Group object

      notifyListeners(); // Notify listeners about the change
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching groups: $e");
      }
      // Handle exceptions
    }
  }
}
