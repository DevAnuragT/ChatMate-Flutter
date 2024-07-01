import 'package:chatmate/screens/forget_password.dart';
import 'package:chatmate/screens/my_friends.dart';
import 'package:chatmate/screens/registration_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import '../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  static const String id = "login_screen";
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  String email = '', password = '';
  bool _isLoading = false;
  bool _obscureText = true;
  final _firestore = FirebaseFirestore.instance;

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
        if (userDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loggged In'),
              duration: Duration(seconds: 1),
            ),
          );
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool('loggedIn', true);
          Navigator.pushNamedAndRemoveUntil(context, FriendsScreen.id, (route)=>false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account does not exist.'),
              duration: Duration(seconds: 1),
            ),
          );
          return null;
        }
      }
      return user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
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
                  )),
              SizedBox(height: 15.0),
              TextField(
                keyboardType: TextInputType.text,
                obscureText: _obscureText,
                onChanged: (value) {
                  password = value;
                },
                decoration: kTextFieldDecoration.copyWith(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, ForgotPasswordScreen.id);
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.red.withOpacity(0.85)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Button(
                        text: 'LogIn',
                        color: Colors.white,
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
                            final user = await _auth.signInWithEmailAndPassword(
                                email: email, password: password);
                            // ignore: unnecessary_null_comparison
                            if (user != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('LogIn successful'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              prefs.setBool('loggedIn', true);
                              Navigator.pushNamedAndRemoveUntil(context, FriendsScreen.id,(route)=>false);
                            }
                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'user-not-found' ||
                                e.code == 'wrong-password') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Invalid email or password')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('LogIn failed')),
                              );
                            }
                          } catch (e) {
                            print(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('LogIn failed')),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                      ),
              ),
              SizedBox(height: 15.0),
              Text(
                'Or Continue Using',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.0),
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
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setBool('loggedIn', true);
                  } else {
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
                  Navigator.pushNamedAndRemoveUntil(context, RegistrationScreen.id,(route)=>false);
                },
                child: Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
