import 'package:cw6/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginShowup extends StatefulWidget {
  const LoginShowup({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginShowup> {
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Taskscreate()),
        );
      } else {
        throw Exception('Google sign-in exited by user');
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: signInWithGoogle,
              child: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
