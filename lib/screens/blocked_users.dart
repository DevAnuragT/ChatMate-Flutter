import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUsersScreen extends StatefulWidget {
  static const String id = 'blocked_users_screen';

  @override
  _BlockedUsersScreenState createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User loggedInUser;
  List<String> blockedUsers = [];

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    fetchBlockedUsers();
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
    }
  }

  Future<void> fetchBlockedUsers() async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(loggedInUser.uid).get();
      setState(() {
        blockedUsers = List<String>.from(userDoc['blockedUsers'] ?? []);
      });
    } catch (e) {
      print('Error fetching blocked users: $e');
    }
  }

  Future<void> unblockUser(String userId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Unblock'),
          content: Text('Are you sure you want to unblock this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        setState(() {
          blockedUsers.remove(userId);
        });
        await _firestore
            .collection('users')
            .doc(loggedInUser.uid)
            .update({'blockedUsers': blockedUsers});

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User unblocked'),
        ));
      } catch (e) {
        print('Error unblocking user: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to unblock user'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Users'),
      ),
      body: blockedUsers.isEmpty
          ? Center(child: Text('No blocked users'))
          : ListView.builder(
        itemCount: blockedUsers.length,
        itemBuilder: (context, index) {
          String userId = blockedUsers[index];
          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var userData = snapshot.data!;
              String username = userData['username'];
              String profilePic = userData['profilePicUrl'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: profilePic.isNotEmpty
                      ? NetworkImage(profilePic)
                      : AssetImage('images/default_profile_pic.jpg')
                  as ImageProvider,
                ),
                title: Text(username),
                trailing: IconButton(
                  icon: Icon(Icons.lock_open_rounded,size: 28, color: Colors.tealAccent,),
                  onPressed: () => unblockUser(userId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
