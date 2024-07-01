import 'package:chatmate/screens/profile.dart';
import 'package:chatmate/screens/settings.dart';
import 'package:chatmate/screens/welcome_screen.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'friend_requests.dart';
import 'my_friends.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PeopleScreen extends StatefulWidget {
  static const String id = 'people_screen';

  @override
  _PeopleScreenState createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User loggedInUser;
  List<String> friendIds = [];
  List<String> pendingRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
      await fetchFriendsAndRequests();
      setState(() {
        isLoading = false;
      });
    }
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

  Future<void> fetchFriendsAndRequests() async {
    final friendsSnapshot = await _firestore
        .collection('users')
        .doc(loggedInUser.uid)
        .collection('friends')
        .get();
    final requestsSnapshot = await _firestore
        .collection('users')
        .doc(loggedInUser.uid)
        .collection('friendRequests')
        .get();

    setState(() {
      friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();
      pendingRequests = requestsSnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<Map<String, String>> getUserData(String userId) async {
    try {
      final DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return {
          'username': userDoc.get('username'),
          'profilePicUrl': userDoc.get('profilePicUrl') ?? ''
        };
      }
      return {'username': '', 'profilePicUrl': ''};
    } catch (e) {
      print('Error fetching user data: $e');
      return {'username': '', 'profilePicUrl': ''};
    }
  }

  void sendFriendRequest(
      String recipientUserId, String recipientUsername) async {
    final senderData = await getUserData(loggedInUser.uid);
    final senderUsername = senderData['username'];
    final senderProfilePicUrl = senderData['profilePicUrl'];

    if (senderUsername != null && senderUsername.isNotEmpty) {
      _firestore
          .collection('users')
          .doc(recipientUserId)
          .collection('friendRequests')
          .doc(loggedInUser.uid)
          .set({
        'username': senderUsername,
        'profilePicUrl': senderProfilePicUrl,
        'time': FieldValue.serverTimestamp(),
      }).then((_) {
        setState(() {
          pendingRequests.add(recipientUserId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to $recipientUsername'),
            duration: Duration(seconds: 1),
          ),
        );
      }).catchError((error) {
        print('Error sending friend request: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send friend request'),
            duration: Duration(seconds: 1),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send friend request: Sender username not found'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('People'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!.docs;
          List<Widget> userWidgets = [];
          for (var user in users) {
            if (user.id == loggedInUser.uid ||
                friendIds.contains(user.id))
              continue; // Skip current user and friends

            final username = user['username'] ?? ''; // Ensure username is not null
            final dp = user['profilePicUrl'];
            final userId = user.id;

            final userWidget = Column(
              children: [
                SizedBox(height: 5,),
                ListTile(
                leading: CircleAvatar(
                  backgroundImage: dp.isNotEmpty
                      ? NetworkImage(dp)
                      : AssetImage('images/default_profile_pic.jpg') as ImageProvider,
                ),
                title: Text(username),
                trailing: IconButton(
                  icon: pendingRequests.contains(userId)
                      ? Icon(Icons.hourglass_empty)
                      : Icon(Icons.person_add),
                  onPressed: pendingRequests.contains(userId)
                      ? null
                      : () => sendFriendRequest(userId, username),
                ),
              ),
                SizedBox(height: 20,width:300 ,child: Divider(color: Colors.white54,thickness: 0.3,),),
                //Divider(color: Colors.white54,thickness: 0.2,)
          ],
            );

            userWidgets.add(userWidget);
          }

          return ListView(
            children: userWidgets,
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
        initialActiveIndex: 0,
        backgroundColor: Colors.black38,
        activeColor: Color(0xFF1EDAF8),
        style: TabStyle.react,
      ),
    );
  }
}
