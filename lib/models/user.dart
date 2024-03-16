import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String uid;
  final String photoUrl;
  final String username;
  final String usernameLowerCase;
  final String userSearchId;

  final String bio;
  final List followers;
  final List following;
  final List group;
  final List likeGroup;

  const User({
    required this.username,
    required this.usernameLowerCase,
    required this.uid,
    required this.userSearchId,
    required this.photoUrl,
    required this.email,
    required this.bio,
    required this.followers,
    required this.following,
    required this.group,
    required this.likeGroup,
  });

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      username: snapshot["username"],
      usernameLowerCase: snapshot["usernameLowerCase"],
      uid: snapshot["uid"],
      userSearchId: snapshot["userSearchId"],
      email: snapshot["email"],
      photoUrl: snapshot["photoUrl"],
      bio: snapshot["bio"],
      followers: snapshot["followers"],
      following: snapshot["following"],
      group: snapshot["group"],
      likeGroup: snapshot["likeGroup"],
    );
  }

  Map<String, dynamic> toJson() => {
        "username": username,
        "usernameLowerCase": usernameLowerCase,
        "uid": uid,
        "userSearchId": userSearchId,
        "email": email,
        "photoUrl": photoUrl,
        "bio": bio,
        "followers": followers,
        "following": following,
        "group": group,
        "likeGroup": likeGroup,
      };
}
