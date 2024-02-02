//main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:authentication_01/providers/auth_state.dart';
import 'package:authentication_01/screens/splash.dart';
import 'package:authentication_01/screens/chat.dart';
//import 'firebase_options.dart';
import 'package:authentication_01/screens/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthState(),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 63, 17, 177)),
      ),
      home: Consumer<AuthState>(
        builder: (ctx, authState, _) {
          if (authState.isAuthenticating) {
            return SplashScreen();
          }

          if (authState.user != null) {
            return const ChatScreen();
          }

          return const AuthScreen();
        },
      ),
      routes: {
        '/chat': (ctx) => const ChatScreen(),
      },
    );
  }
}
