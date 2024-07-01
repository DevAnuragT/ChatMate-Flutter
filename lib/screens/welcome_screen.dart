import 'package:chatmate/screens/login_screen.dart';
import 'package:chatmate/screens/registration_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatmate/constants.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'my_friends.dart';

class WelcomeScreen extends StatefulWidget {
  static const String id = 'welcome_screen';
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  late AnimationController controller;
  late Animation<double> curvedAnimation;
  late Animation<Color?> tweenAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    // Define a curved animation
    curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.decelerate,
    );

    // Define a tween animation
    tweenAnimation = ColorTween(begin: Colors.transparent, end: Colors.teal)
        .animate(controller);

    controller.forward();
    controller.addListener(() {
      setState(
          () {}); // Rebuild the widget tree when the animation value changes
    });
  }

  Future<bool> isUsernameUnique(String username) async {
    final result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isEmpty;
  }

  Future<void> _showUsernameDialog(User user) async {
    String? newUsername;
    bool isUnique = false;
    while (!isUnique) {
      newUsername = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          String tempUsername = '';
          return AlertDialog(
            title: Text('Enter Username'),
            content: TextField(
              onChanged: (value) {
                tempUsername = value;
              },
              decoration: kTextFieldDecoration.copyWith(
                hintText: 'Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(tempUsername);
                },
              ),
            ],
          );
        },
      );

      if (newUsername == null || newUsername.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username cannot be empty')),
        );
        continue;
      }

      isUnique = await isUsernameUnique(newUsername);
      if (!isUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username already exists')),
        );
      }
    }

    if (newUsername != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'username': newUsername,
        'email': user.email,
        'profilePicUrl': '', // Set your default profile pic URL
        'chattingWith': '',
        'blockedUsers': [],
        'status': 'online',
      });
    }
  }

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _showUsernameDialog(user);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account already exists. Logged In'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Hero(
                  tag: 'logo',
                  child: Container(
                    child: Image.asset('images/logo2.png'),
                    height: curvedAnimation.value * 80.0,
                  ),
                ),
                SizedBox(width: 10),
                Row(
                  children: [
                    Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 45.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: Text(
                        'M',
                        style: TextStyle(
                          fontSize: 45.0,
                          fontWeight: FontWeight.w900,
                          color: tweenAnimation.value,
                        ),
                      ),
                    ),
                    Text(
                      'ate',
                      style: TextStyle(
                        fontSize: 45.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 48.0,
            ),
            Button(
              color: Color(0xFF088395),
              text: 'Log In',
              onPress: () {
                Navigator.pushNamed(context, LoginScreen.id);
              },
            ),
            Button(
              color: Colors.white,
              text: 'Register',
              onPress: () {
                Navigator.pushNamed(context, RegistrationScreen.id);
              },
            ),
            SizedBox(
              height: 10,
            ),
            SizedBox(
                height: 40,
                child: Text(
                  'Or continue with',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w400,
                      fontSize: 15),
                )),
            isLoading
                ? CircularProgressIndicator(
                    color: Colors.white,
                  )
                : TextButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      User? user = await _signInWithGoogle();
                      if (user != null) {
                        setState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Registration successful'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setBool('loggedIn', true);
                        Navigator.pushNamedAndRemoveUntil(context, FriendsScreen.id,(route)=> false);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Registration failed'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
                    child: Container(
                      width: 60,
                      child: Image.asset('images/google.webp'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class Button extends StatelessWidget {
  final Color color;
  final String text;
  final VoidCallback onPress;

  Button({required this.text, required this.onPress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 50),
      child: Material(
        elevation: 5.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18))),
        color: color,
        child: MaterialButton(
          padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 20),
          onPressed: onPress,
          child: Text(
            text,
            style: TextStyle(
                color: color == Colors.white ? Color(0xFF0F2631) : Colors.white,
                fontSize: 15),
          ),
        ),
      ),
    );
  }
}
