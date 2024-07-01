import 'package:chatmate/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'my_friends.dart';

class EmailVerificationScreen extends StatefulWidget {
  static const String id = 'email_verification_screen';

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _auth = FirebaseAuth.instance;
  User? _user;
  Timer? _timer;
  bool _canResendEmail = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    startEmailVerificationCheck();
    _startResendEmailTimer();
  }

  Future<void> startEmailVerificationCheck() async {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _user?.reload();
      if (_user?.emailVerified ?? false) {
        timer.cancel();
        Navigator.pushNamedAndRemoveUntil(
          context,
          FriendsScreen.id,
              (route) => false,
        );
      }
    });
  }

  void _startResendEmailTimer() {
    Timer(Duration(seconds: 30), () {
      setState(() {
        _canResendEmail = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await _user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email resent.'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _canResendEmail = false;
      });
      _startResendEmailTimer();
    } catch (e) {
      print('Failed to resend verification email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend verification email.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  Future<void> verifyEmail() async {
    await _user?.reload();
    if (_user?.emailVerified?? false) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        FriendsScreen.id,
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Verification'),
      ),
      body: RefreshIndicator(
        onRefresh: verifyEmail,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              Text(
                'A verification email has been sent to your email address. Please check your inbox and verify your email before logging in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _canResendEmail ? _resendVerificationEmail : null,
                child: Text(_canResendEmail ? 'Resend Verification Email' : 'Wait 30 seconds'),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, LoginScreen.id, (route)=> false);
                },
                child: Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
