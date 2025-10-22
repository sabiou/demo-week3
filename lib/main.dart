import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:week_2/auth/sign_up.dart';
import 'package:week_2/home/home_page.dart';
import 'package:week_2/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    await _connectToFirebaseEmulators();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Dès qu'un utilisateur est connecté, on affiche la page d'accueil.
        if (snapshot.hasData) {
          return const HomePage();
        }

        // Sinon, on propose l'inscription par défaut.
        return const SignUpPage();
      },
    );
  }
}

Future<void> _connectToFirebaseEmulators() async {
  const firestorePort = 4000;
  const authPort = 3000;

  var host = 'localhost';

  FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
  await FirebaseAuth.instance.useAuthEmulator(host, authPort);
}
