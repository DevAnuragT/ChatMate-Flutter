import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String profilePic;

  FriendProfileScreen({
    required this.friendId,
    required this.friendName,
    required this.profilePic,
  });

  @override
  _FriendProfileScreenState createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User loggedInUser;
  String? friendEmail;
  List<Map<String, dynamic>> mutualFriends = [];

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    fetchFriendDetails();
    fetchMutualFriends();
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
    }
  }

  Future<void> fetchFriendDetails() async {
    try {
      DocumentSnapshot friendDoc =
      await _firestore.collection('users').doc(widget.friendId).get();
      setState(() {
        friendEmail = friendDoc['email'];
      });
    } catch (e) {
      print('Error fetching friend details: $e');
    }
  }

  Future<void> fetchMutualFriends() async {
    try {
      QuerySnapshot friendsSnapshot = await _firestore
          .collection('users')
          .doc(widget.friendId)
          .collection('friends')
          .get();

      for (var doc in friendsSnapshot.docs) {
        if (doc.id == loggedInUser.uid) continue; // Skip the logged-in user

        DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(doc.id).get();
        setState(() {
          mutualFriends.add({
            'id': doc.id,
            'username': userSnapshot['username'],
            'profilePicUrl': userSnapshot['profilePicUrl'] ?? '',
          });
        });
      }
    } catch (e) {
      print('Error fetching mutual friends: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 100.0,
              backgroundImage: widget.profilePic.isNotEmpty
                  ? NetworkImage(widget.profilePic)
                  : AssetImage('images/default_profile_pic.jpg') as ImageProvider,
            ),
            SizedBox(height: 20.0),
            Text(
              widget.friendName,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.0),
            friendEmail != null
                ? Text(
              friendEmail!,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.teal.shade400,
              ),
            )
                : CircularProgressIndicator(),
            SizedBox(height: 40.0,child: Divider(color: Colors.white54,),),
            Text(
              'Mutual Friends',
              style: TextStyle(
                fontSize: 23.0,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: mutualFriends.isNotEmpty
                  ? ListView.builder(
                itemCount: mutualFriends.length,
                itemBuilder: (context, index) {
                  var friend = mutualFriends[index];
                  return Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FriendProfileScreen(
                              friendId: friend['id'],
                              friendName: friend['username'],
                              profilePic: friend['profilePicUrl'] ?? '',
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundImage: friend['profilePicUrl'].isNotEmpty
                            ? NetworkImage(friend['profilePicUrl'])
                            : AssetImage('images/default_profile_pic.jpg')
                        as ImageProvider,
                      ),
                      title: Text(friend['username']),
                    ),
                  );
                },
              )
                  : Center(child: CircularProgressIndicator(color: Colors.transparent,)),
            ),
            SizedBox(height: 40.0,child: Divider(color: Colors.white54,),),
          ],
        ),
      ),
    );
  }
}
