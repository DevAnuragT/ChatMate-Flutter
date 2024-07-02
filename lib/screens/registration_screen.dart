// ignore_for_file: unnecessary_null_comparison

import 'package:chatmate/screens/email_verification.dart';
import 'package:chatmate/screens/my_friends.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmate/screens/login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants.dart';
import 'welcome_screen.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = "registration_screen";

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String email = '', password = '', username = '';
  bool _isLoading = false;
  bool _obscureText = true;

  Future<bool> isUsernameUnique(String username) async {
    final result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isEmpty;
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

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
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
        'status': 'offline',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    height: 180.0,
                    child: Image.asset('images/logo2.png'),
                  ),
                ),
              ),
              SizedBox(height: 25.0),
              TextField(
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  email = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Email',
                  prefixIcon: Icon(
                    Icons.email,
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              TextField(
                keyboardType: TextInputType.text,
                obscureText: _obscureText,
                onChanged: (value) {
                  password = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                    hintText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock,
                    ),
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        icon: _obscureText
                            ? Icon(Icons.visibility_off)
                            : Icon(Icons.visibility))),
              ),
              SizedBox(height: 20.0),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Button(
                color: Colors.white,
                text: 'Register',
                onPress: () async {
                  setState(() {
                    _isLoading = true;
                  });

                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please fill in all fields'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    setState(() {
                      _isLoading = false;
                    });
                    return;
                  }

                  try {
                    final newUser = await _auth.createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    if (newUser != null) {
                      await _showUsernameDialog(newUser.user!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registration successful'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      prefs.setBool('loggedIn', true);
                      await newUser.user?.sendEmailVerification();
                      Navigator.pushNamed(context, EmailVerificationScreen.id,);
                    }
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'email-already-in-use') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User already exists'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registration failed: ${e.message}'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    print(e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Registration failed: $e'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
              ),
              SizedBox(height: 10.0),
              Text(
                'Or Continue Using',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  User? user = await _signInWithGoogle();
                  if (user != null) {
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Registration successful'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setBool('loggedIn', true);
                    Navigator.pushNamed(context, FriendsScreen.id);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Registration failed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: Container(
                  width: 50,
                  child: Image.asset('images/google.webp'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, LoginScreen.id);
                },
                child: Text(
                  'Already have an account?',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
