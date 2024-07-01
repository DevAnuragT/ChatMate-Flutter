import 'package:chatmate/screens/login_screen.dart';
import 'package:chatmate/screens/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:chatmate/screens/welcome_screen.dart';
import 'package:chatmate/screens/people.dart';
import 'package:chatmate/screens/my_friends.dart';
import 'package:chatmate/screens/friend_requests.dart';
import 'package:chatmate/screens/profile.dart';
import 'package:chatmate/screens/forget_password.dart';
import 'package:chatmate/screens/blocked_users.dart';
import 'package:chatmate/screens/email_verification.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Initialize loggedIn if not previously set
  if (prefs.getBool('loggedIn') == null) {
    prefs.setBool('loggedIn', false);
  }

  // Debug prints for tracking initialization
  print('Initial loggedIn value: ${prefs.getBool('loggedIn')}');

  runApp(ChatMate(loggedIn: prefs.getBool('loggedIn') ?? false));
}


class ChatMate extends StatelessWidget {
  final loggedIn;
  ChatMate({required this.loggedIn});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: Color(0xFF0F2631),
        appBarTheme: AppBarTheme(
          color: Colors.black54,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
            borderRadius: BorderRadius.all(Radius.circular(30.0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueGrey),
            borderRadius: BorderRadius.all(Radius.circular(30.0)),
          ),
          hintStyle: TextStyle(color: Colors.white70),
        ),
        iconTheme: IconThemeData(
          color: Colors.lightBlueAccent,
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          minWidth: 1,
          buttonColor: Color(0xFF088395),
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      initialRoute: loggedIn ? FriendsScreen.id : WelcomeScreen.id,
      routes: {
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        WelcomeScreen.id: (context) => WelcomeScreen(),
        PeopleScreen.id: (context) => PeopleScreen(),
        FriendRequestScreen.id: (context) => FriendRequestScreen(),
        FriendsScreen.id: (context) => FriendsScreen(),
        ProfileScreen.id: (context) => ProfileScreen(),
        ForgotPasswordScreen.id: (context) => ForgotPasswordScreen(),
        EmailVerificationScreen.id: (context) => EmailVerificationScreen(),
        BlockedUsersScreen.id: (context) => BlockedUsersScreen(),
      },
    );
  }
}
