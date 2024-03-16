import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unop/resources/firestore_methods.dart';

class ManagePermissionsScreen extends StatefulWidget {
  final String groupId;

  const ManagePermissionsScreen({Key? key, required this.groupId})
      : super(key: key);

  @override
  _ManagePermissionsScreenState createState() =>
      _ManagePermissionsScreenState();
}

class _ManagePermissionsScreenState extends State<ManagePermissionsScreen> {
  Map<String, dynamic>? groupData = {};
  @override
  void initState() {
    super.initState();
    fetchGroupData(); // Fetch group data on init
  }

  // Fetch group data including permissions and member list
  Future<void> fetchGroupData() async {
    try {
      var groupDoc = await FirebaseFirestore.instance
          .collection('group')
          .doc(widget.groupId)
          .get();

      setState(() {
        groupData = groupDoc.data() ?? {};
      });
    } catch (e) {
      print('Error fetching group data: $e');
    }
  }

  // Dialog to edit a member's permissions
  void showEditPermissionsDialog(String memberId, String username) {
    bool canRead = groupData?['canRead']?.contains(memberId) ?? false;
    bool canWrite = groupData?['canWrite']?.contains(memberId) ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Permissions for $username'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Can Read'),
                    value: canRead,
                    onChanged: (value) => setState(() => canRead = value),
                  ),
                  SwitchListTile(
                    title: const Text('Can Write'),
                    value: canWrite,
                    onChanged: (value) => setState(() => canWrite = value),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                String res = await FireStoreMethods().updateMemberPermissions(
                    groupData!, widget.groupId, memberId, canRead, canWrite);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Permissions'),
      ),
      body: groupData!.isNotEmpty
          ? ListView.builder(
              itemCount: groupData?['member']?.length ?? 0,
              itemBuilder: (context, index) {
                String memberId = groupData?['member'][index];
                // Fetching member details from users collection
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(memberId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const ListTile(title: Text('Loading...'));
                    }
                    var memberData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    bool canRead =
                        groupData?['canRead']?.contains(memberId) ?? false;
                    bool canWrite =
                        groupData?['canWrite']?.contains(memberId) ?? false;

                    return ListTile(
                      title: Text(memberData['username'] ?? 'Unknown'),
                      subtitle: Text('Read: $canRead, Write: $canWrite'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => showEditPermissionsDialog(
                            memberId, memberData['username']),
                      ),
                    );
                  },
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
