import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unop/models/group.dart' as model;
import 'package:unop/models/group.dart';
import 'package:unop/models/post.dart';
import 'package:unop/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadPost(String description, List<File> files, String uid,
      String username, String profImage, List postGroupId) async {
    // asking uid here because we dont want to make extra calls to firebase auth when we can just get from our state management
    String res = "Some error occurred";
    try {
      List<String> photoUrl =
          await StorageMethods().uploadPostToStorage('posts', files, true);
      String postId = const Uuid().v1(); // creates unique id based on time
      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
        groupId: postGroupId,
      );
      _firestore.collection('posts').doc(postId).set(post.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> likePost(String postId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        // if the likes list contains the user uid, we need to remove it
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        // else we need to add uid to the likes array
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Post comment
  Future<String> postComment(String postId, String text, String uid,
      String name, String profilePic) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        // if the likes list contains the user uid, we need to remove it
        String commentId = const Uuid().v1();
        _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Delete Post
  Future<String> deletePost(String postId) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('posts').doc(postId).delete();
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(uid).get();
      List following = (snap.data()! as dynamic)['following'];

      if (following.contains(followId)) {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      } else {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId])
        });
      }
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }

  Future<void> followGroup(String uid, String groupID) async {
    try {
      // Get User data
      DocumentSnapshot snapUser =
          await _firestore.collection('users').doc(uid).get();
      List groupUser = (snapUser.data()! as dynamic)['group'];

      // Get Group data

      // Logic to follow or unfollow the group
      if (groupUser.contains(groupID)) {
        print("contina");
        // Unfollow the group
        await _firestore.collection('users').doc(uid).update({
          'group': FieldValue.arrayRemove([groupID])
        });

        // Remove user from the group's member list
        await _firestore.collection('group').doc(groupID).update({
          'member': FieldValue.arrayRemove([uid]),
          // Remove 'canRead' permission
          'canRead': FieldValue.arrayRemove([uid]),
        });
      } else {
        print("not contina");

        // Follow the group
        await _firestore.collection('users').doc(uid).update({
          'group': FieldValue.arrayUnion([groupID])
        });

        // Add user to the group's member list
        await _firestore.collection('group').doc(groupID).update({
          'member': FieldValue.arrayUnion([uid]),
          // Add 'canRead' permission
          'canRead': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }

  Future<String> addGroup(
      {required String groupName,
      required String bio,
      required Uint8List file,
      required String groupId,
      required String uid}) async {
    String res = "Some error Occurred";

    try {
      if (groupName.isNotEmpty && groupId.isNotEmpty && bio.isNotEmpty) {
        // registering user in auth with email and password

        String photoUrl = await StorageMethods()
            .uploadGroupImageToStorage('groupProfilePics', file, false);
        model.Group group = model.Group(
          groupName: groupName,
          groupNameLowerCase: groupName.toLowerCase(),
          photoUrl: photoUrl,
          bio: bio,
          admin: [uid],
          member: [],
          groupid: groupId,
          privacy: 0,
          canWrite: [uid],
          canRead: [uid],
        );

        // adding group in our database
        await _firestore.collection("group").doc(groupId).set(group.toJson());
        followGroup(uid, groupId);

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // get group details
  Future<Group> getGroupDetails(String? groupId) async {
    //User currentUser = _auth.currentUser!;
    //groupId ??= currentUser.uid;
    DocumentSnapshot documentSnapshot =
        await _firestore.collection('group').doc(groupId).get();
    return Group.fromSnap(documentSnapshot);
  }

  Future<String> likeGroup(String groupid, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(groupid)) {
        // if the likes list contains the user uid, we need to remove it
        _firestore.collection('users').doc(uid).update({
          'likeGroup': FieldValue.arrayRemove([groupid])
        });
      } else {
        // else we need to add uid to the likes array
        _firestore.collection('users').doc(uid).update({
          'likeGroup': FieldValue.arrayUnion([groupid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<bool> checkIfGroupExists(String groupSearchId) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('group') // Assuming 'users' is your collection
        .where('groupid', isEqualTo: groupSearchId)
        .limit(1) // Limit to 1 since you only need to know if it exists
        .get();

    final List<DocumentSnapshot> documents = result.docs;
    return documents.isNotEmpty; // Returns true if uid exists, false otherwise
  }

  // Update permissions for a single member
  Future<String> updateMemberPermissions(Map<String, dynamic> groupData,
      String groupId, String memberId, bool canRead, bool canWrite) async {
    String res = "sucess";
    try {
      // Fetch the group data
      DocumentSnapshot groupSnapshot =
          await _firestore.collection('group').doc(groupId).get();
      Map<String, dynamic> groupData =
          groupSnapshot.data() as Map<String, dynamic>;

      List<String> canReadList = List<String>.from(groupData['canRead'] ?? []);
      List<String> canWriteList =
          List<String>.from(groupData['canWrite'] ?? []);

      // Update canRead and canWrite lists
      if (canRead) {
        if (!canReadList.contains(memberId)) canReadList.add(memberId);
      } else {
        canReadList.remove(memberId);
      }

      if (canWrite) {
        if (!canWriteList.contains(memberId)) canWriteList.add(memberId);
      } else {
        canWriteList.remove(memberId);
      }

      // Update group document in Firestore
      await FirebaseFirestore.instance
          .collection('group')
          .doc(groupId)
          .update({'canRead': canReadList, 'canWrite': canWriteList});
    } catch (e) {
      res = e.toString();
      print('Error updating permissions: $e');
    }
    return res;
  }

  Future<String> reportPost(String userId, String postId, String reason) async {
    String res = "sucess";

    final firestoreInstance = FirebaseFirestore.instance;

    try {
      await firestoreInstance.collection('reports').add({
        'userId': userId,
        'postId': postId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(), // Adds server-side timestamp
      });
      print('Report sent successfully');
      // You can also add code here to show a confirmation message to the user
    } catch (e) {
      res = e.toString();

      print('Error reporting post: $e');
      // Handle any errors here, such as showing an error message to the user
    }
    return res;
  }

  Future<void> blockUser(String blockingUserId, String blockedUserId) async {
    try {
      // Add blocked user's UID to the list of blocked users for the blocking user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(blockingUserId)
          .update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId])
      });
      // Optionally, you can take additional actions like unfollowing the blocked user or hiding their posts
    } catch (e) {
      // Handle/blocking error
      print('Error blocking user: $e');
      throw e; // Rethrow the error for handling in the UI if needed
    }
  }
}
