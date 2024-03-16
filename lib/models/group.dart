import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String groupName;
  final String groupNameLowerCase;
  final String groupid;
  final List<String> admin;
  final String photoUrl;
  final String bio;
  final List<String> member;
  final int privacy;
  final List<String> canRead; // New field for read permissions
  final List<String> canWrite; // New field for write permissions

  const Group({
    required this.groupName,
    required this.groupNameLowerCase,
    required this.groupid,
    required this.admin,
    required this.photoUrl,
    required this.bio,
    required this.member,
    required this.privacy,
    required this.canRead, // Initialize new field
    required this.canWrite, // Initialize new field
  });

  static Group fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Group(
        groupName: snapshot["groupName"],
        groupNameLowerCase: snapshot["groupNameLowerCase"],
        groupid: snapshot["groupid"],
        admin: List<String>.from(snapshot["admin"]),
        photoUrl: snapshot["photoUrl"],
        bio: snapshot["bio"],
        member: List<String>.from(snapshot["member"]),
        privacy: snapshot["privacy"],
        canRead: List<String>.from(
            snapshot["canRead"] ?? []), // Handle possible null
        canWrite: List<String>.from(
            snapshot["canWrite"] ?? []) // Handle possible null
        );
  }

  Map<String, dynamic> toJson() => {
        "groupName": groupName,
        "groupNameLowerCase": groupNameLowerCase,
        "groupid": groupid,
        "admin": admin,
        "photoUrl": photoUrl,
        "bio": bio,
        "member": member,
        "privacy": privacy,
        "canRead": canRead, // Convert to JSON
        "canWrite": canWrite // Convert to JSON
      };
}
