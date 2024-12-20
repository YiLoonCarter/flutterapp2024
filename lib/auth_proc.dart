import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

//class AuthGate extends StatelessWidget {
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (!snapshot.hasData) {
            hasNavigated = false;
            return SignInScreen(
              providers: [
                EmailAuthProvider(), // new
                GoogleProvider(
                    clientId:
                        "620340816204-ec663e7f4gs3ghnav59kpqh4tmm2nbtj.apps.googleusercontent.com"), // new
                //GoogleProvider(clientId: "YOUR_WEBCLIENT_ID"),  // new
              ],
              headerBuilder: (context, constraints, shrinkOffset) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset('lib/assets/flutterfire_300x.png'),
                  ),
                );
              },
              subtitleBuilder: (context, action) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: action == AuthAction.signIn
                      ? const Text('Welcome to FlutterFire, please sign in!')
                      : const Text('Welcome to Flutterfire, please sign up!'),
                );
              },
              footerBuilder: (context, action) {
                return const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'By signing in, you agree to our terms and conditions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              },
              sideBuilder: (context, shrinkOffset) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset('lib/assets/flutterfire_300x.png'),
                  ),
                );
              },
            );
          } else {
            if (!hasNavigated) {
              hasNavigated = true;
              Future.microtask(() => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MyHomePage(title: 'Flutter Home Page'),
                    ),
                  ));
            }
            return const SizedBox(); // Placeholder during navigation
          }
        }
        //return const MyHomePage(title: 'Flutter Home Page');
        // Show loading spinner during connection
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
