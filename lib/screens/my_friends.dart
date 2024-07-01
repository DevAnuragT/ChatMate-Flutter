import 'package:chatmate/screens/profile.dart';
import 'package:chatmate/screens/settings.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'package:chatmate/screens/friend_requests.dart';
import 'package:chatmate/screens/chat_screen.dart';
import 'package:chatmate/screens/people.dart';

class FriendsScreen extends StatefulWidget {
  static const String id = 'friends_screen';
  static List<String> _screens = [
    ProfileScreen.id,
    PeopleScreen.id,
    FriendsScreen.id,
    FriendRequestScreen.id,
  ];

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User loggedInUser;
  String? username;
  late String profilePicUrl;
  String? email;
  List<String> blocked = [];

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    getUserDetails();
  }

  Future<int> fetchUnreadMessages(String friendId) async {
    try {
      // Fetch the document snapshot for the friend
      DocumentSnapshot friendDoc = await _firestore
          .collection('users')
          .doc(loggedInUser.uid)
          .collection('friends')
          .doc(friendId)
          .get();

      // Check if the document exists and fetch the unreadMessages field
      if (friendDoc.exists) {
        final data = friendDoc.data()
        as Map<String, dynamic>?; // Cast to Map<String, dynamic>
        final unreadMessages = data?['unreadMessages'] ?? 0;
        return unreadMessages;
      } else {
        return 0;
        print('Friend document does not exist.');
      }
    } catch (e) {
      print('Error fetching unread messages: $e');
      return 0;
    }
  }

  Future<void> getUserDetails() async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(loggedInUser.uid).get();
      setState(() {
        username = userDoc['username'];
        email = loggedInUser.email!;
        profilePicUrl =
            userDoc['profilePicUrl'] ?? 'images/default_profile_pic.jpg';
        blocked = List<String>.from(userDoc['blockedUsers'] ?? []);
      });
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Friends'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                //dialog to confirm
                AlertDialog alertDialog = AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text('Logout'),
                      onPressed: () async {
                        // Sign out from Firebase
                        await _auth.signOut();
                        SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                        await prefs.setBool('loggedIn', false);
                        // Clear all routes and push WelcomeScreen
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          WelcomeScreen.id,
                              (route) => false, // Removes all routes in the stack
                        );
                      },
                    ),
                  ],
                );
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return alertDialog;
                  },
                );
                // Sign out from Firebase
              },
            ),
          ],
        ),
        body: loggedInUser == null
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: () async {
            Navigator.pushNamedAndRemoveUntil(
                (context), FriendsScreen.id, (route) => false); // Removes all routes)
          },
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(loggedInUser.uid)
                .collection('friends')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              final friends = snapshot.data!.docs;
              List<Future<Map<String, dynamic>>> friendDataFutures = friends.map((friend) async {
                final friendId = friend.id;
                final friendDoc = await _firestore.collection('users').doc(friendId).get();
                final unreadMessages = await fetchUnreadMessages(friendId);

                return {
                  'friendId': friendId,
                  'username': friendDoc['username'],
                  'profilePicUrl': friendDoc['profilePicUrl'] ?? 'images/default_profile_pic.jpg',
                  'unreadMessages': unreadMessages,
                };
              }).toList();

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: Future.wait(friendDataFutures),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  List<Map<String, dynamic>> friendData = snapshot.data!;
                  friendData.sort((a, b) => b['unreadMessages'].compareTo(a['unreadMessages']));

                  List<Widget> friendWidgets = friendData.map((data) {
                    final friendId = data['friendId'];
                    final friendUsername = data['username'];
                    final profilePic = data['profilePicUrl'];
                    final unreadMessages = data['unreadMessages'];

                    // Check if friend is blocked
                    if (blocked.contains(friendId)) {
                      // Don't display blocked users
                      return SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        SizedBox(height: 5),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : AssetImage('images/default_profile_pic.jpg') as ImageProvider,
                          ),
                          title: Text(friendUsername,style: TextStyle(color: Colors.white,fontSize: 17,fontWeight: FontWeight.w400),),
                          trailing: unreadMessages > 0
                              ? ClipOval(
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Colors.teal,
                              child: Center(
                                child: Text(
                                  '$unreadMessages',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          )
                              : null,
                          onTap: () async {
                            // Update Firestore to mark as chatting
                            await _firestore.collection('users').doc(loggedInUser.uid).update({
                              'chattingWith': friendUsername,
                            });

                            // Reset unread messages count
                            await _firestore
                                .collection('users')
                                .doc(loggedInUser.uid)
                                .collection('friends')
                                .doc(friendId)
                                .update({'unreadMessages': 0});

                            // Navigate to ChatScreen
                            var block = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  recipientId: friendId,
                                  recipientName: friendUsername,
                                  profilePic: profilePic,
                                ),
                              ),
                            );

                            // If block is true, add user to blocked list
                            if (block != null && block == true) {
                              setState(() {
                                blocked.add(friendId);
                              });
                              await _firestore.collection('users').doc(loggedInUser.uid).update({'blockedUsers': blocked});
                            }
                          },
                        ),
                        SizedBox(
                          height: 20,
                          width: 300,
                          child: Divider(
                            color: Colors.white54,
                            thickness: 0.3,
                          ),
                        ),
                      ],
                    );
                  }).toList();

                  return ListView(
                    children: friendWidgets,
                  );
                },
              );
            },
          ),
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
          initialActiveIndex: 1,
          backgroundColor: Colors.black38,
          activeColor: Color(0xFF1EDAF8),
          style: TabStyle.react,
        ),
      ),
    );
  }
}
