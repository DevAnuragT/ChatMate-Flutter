import 'package:chatmate/screens/my_friends.dart';
import 'package:chatmate/screens/people.dart';
import 'package:chatmate/screens/profile.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestScreen extends StatefulWidget {
  static const String id = 'friend_request_screen';

  @override
  _FriendRequestScreenState createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User? loggedInUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    setState(() {
      loggedInUser = user;
    });
  }

  void _onIndexTap(int index) {
    switch (index) {
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, ProfileScreen.id, (route)=> false);
        break;
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, PeopleScreen.id, (route)=> false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, FriendsScreen.id,(route)=> false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, FriendRequestScreen.id,(route)=> false);
        break;
    // case 4:
    //   Navigator.pushNamedAndRemoveUntil(context, SettingsScreen.id,(route)=> false);
    //   break;
    }
  }

  void acceptFriendRequest(String senderUserId) async {
    if (loggedInUser == null) return;

    // Add sender to the current user's friends list
    await _firestore
        .collection('users')
        .doc(loggedInUser!.uid)
        .collection('friends')
        .doc(senderUserId)
        .set({
      'time': FieldValue.serverTimestamp(),
    });

    // Add current user to the sender's friends list
    await _firestore
        .collection('users')
        .doc(senderUserId)
        .collection('friends')
        .doc(loggedInUser!.uid)
        .set({
      'time': FieldValue.serverTimestamp(),
    });

    // Remove the friend request
    await _firestore
        .collection('users')
        .doc(loggedInUser!.uid)
        .collection('friendRequests')
        .doc(senderUserId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Requests'),
      ),
      body: loggedInUser == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(loggedInUser!.uid)
            .collection('friendRequests')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final requests = snapshot.data!.docs;
          List<Widget> requestWidgets = [];
          for (var request in requests) {
            final data = request.data() as Map<String, dynamic>;
            final username = data['username'] ?? 'Unknown';
            final profilePicUrl = data['profilePicUrl'] ?? '';
            final senderUserId = request.id;

            final requestWidget = Column(
              children: [
                SizedBox(height: 10,width:10 ,child: Divider(color: Colors.white54,thickness: 0.2,),),
                ListTile(
                leading: CircleAvatar(
                  backgroundImage: profilePicUrl.isNotEmpty
                      ? NetworkImage(profilePicUrl)
                      : AssetImage('images/default_profile_pic.jpg') as ImageProvider,
                ),
                title: Text(username),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check),
                      color: Colors.green,
                      onPressed: () => acceptFriendRequest(senderUserId),
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel_outlined),
                      color: Colors.red,
                      onPressed: () async {
                        await _firestore
                            .collection('users')
                            .doc(loggedInUser!.uid)
                            .collection('friendRequests')
                            .doc(senderUserId)
                            .delete();
                      },
                    ),
                  ],
                ),
              ),
          ],
            );
            requestWidgets.add(requestWidget);
          }

          return ListView(
            children: requestWidgets,
          );
        },
      ),
      bottomNavigationBar: ConvexAppBar(
        height: 60,
        elevation: 10.0,
        shadowColor: Colors.white38,
        items: [
          TabItem(icon: Icons.person_add),
          TabItem(icon: Icons.group),
          TabItem(icon: Icons.notification_add),
          TabItem(icon: Icons.person),
        ],
        onTap: _onIndexTap,
        initialActiveIndex: 2,
        backgroundColor: Colors.black38,
        activeColor: Color(0xFF1EDAF8),
        style: TabStyle.react,
      ),
    );
  }
}
