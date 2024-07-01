import 'package:chatmate/constants.dart';
import 'package:chatmate/screens/people.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chatmate/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'blocked_users.dart';
import 'friend_requests.dart';
import 'my_friends.dart';

class ProfileScreen extends StatefulWidget {
  static const String id = 'profile_screen';

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  late User loggedInUser;
  String username = "";
  String email = "";
  String profilePicUrl = '';
  bool edit = false;
  bool isLoading = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    getUserDetails();
  }

  void _onIndexTap(int index) {
    switch (index) {
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, ProfileScreen.id, (route) => false);
        break;
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, PeopleScreen.id, (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, FriendsScreen.id, (route) => false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, FriendRequestScreen.id, (route) => false);
        break;
    // case 4:
    //   Navigator.pushNamedAndRemoveUntil(context, SettingsScreen.id, (route) => false);
    //   break;
    }
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
    }
  }

  Future<void> getUserDetails() async {
    DocumentSnapshot userDoc =
    await _firestore.collection('users').doc(loggedInUser.uid).get();
    setState(() {
      username = userDoc['username'];
      email = loggedInUser.email!;
      profilePicUrl = userDoc['profilePicUrl'] ?? 'images/default_profile_pic.jpg';
    });
  }

  void logout() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('loggedIn', false);
    Navigator.pushNamedAndRemoveUntil(
      context,
      WelcomeScreen.id,
          (route) => false,
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final ref = _storage.ref().child('profile_pictures').child(loggedInUser.uid + '.jpg');
      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      // Check if username is unique
      final result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (result.docs.isNotEmpty && result.docs.first.id != loggedInUser.uid) {
        // Username already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username already taken')),
        );
      } else {
        String? imageUrl;
        if (_image != null) {
          imageUrl = await _uploadImage(_image!);
        }

        // Update username and profile picture URL in Firestore
        await _firestore.collection('users').doc(loggedInUser.uid).update({
          'username': username,
          'profilePicUrl': imageUrl ?? profilePicUrl,
        });

        setState(() {
          profilePicUrl = imageUrl ?? profilePicUrl;
          edit = false;
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: edit
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CircleAvatar(
                        radius: 120.0,
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : profilePicUrl.isNotEmpty
                            ? NetworkImage(profilePicUrl)
                            : AssetImage('images/default_profile_pic.jpg')
                        as ImageProvider,
                      ),
                      if (edit)
                        Icon(
                          Icons.edit,
                          color: Colors.grey,
                          size: 40.0,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 40.0),
                TextFormField(
                  initialValue: username,
                  decoration: kTextFieldDecoration.copyWith(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.white, fontSize: 18)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    username = value;
                  },
                ),
                SizedBox(height: 20.0),
                if (isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                    ),
                    onPressed: _saveProfile,
                    child: Text(
                      'Save',
                      style: TextStyle(color: Color(0xFF0F2631)),
                    ),
                  ),
                SizedBox(height: 12.0),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF088395)),
                  ),
                  onPressed: () {
                    setState(() {
                      edit = false;
                    });
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          : Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 120.0,
                backgroundImage: profilePicUrl.isNotEmpty
                    ? NetworkImage(profilePicUrl)
                    : AssetImage('images/default_profile_pic.jpg') as ImageProvider,
              ),
              SizedBox(height: 40.0),
              Text(
                username,
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                email,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20.0),
              TextButton(
                onPressed: () {
                  setState(() {
                    edit = true;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                style: ButtonStyle().copyWith(
                  backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF088395)),
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.block,
                  color: Colors.red,
                ),
                title: TextButton(
                  child: Text(
                    'Blocked Users',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.normal),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, BlockedUsersScreen.id);
                  },
                ),
                trailing: SizedBox(),
              ),
              ListTile(
                leading: Icon(Icons.logout_rounded),
                title: TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, WelcomeScreen.id, (route) => false);
                  },
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                trailing: SizedBox(),
              ),
            ],
          ),
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
        initialActiveIndex: 3,
        backgroundColor: Colors.black38,
        activeColor: Color(0xFF1EDAF8),
        style: TabStyle.react,
      ),
    );
  }
}
