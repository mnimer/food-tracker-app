import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cron/cron.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/firebase_options.dart';
import 'package:food_tracker/pages/home_page.dart';
import 'package:food_tracker/pages/splash_page.dart';
import 'package:go_router/go_router.dart';

final _key = GlobalKey<NavigatorState>();

/// Listen for changes to FirebaseAuth user and alert GoRouter to refresh state
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._auth) {
    _auth.authStateChanges().listen((event) {
      if (event != user) {
        user = event;
        notifyListeners();
      }
    });
  }
  User? user;
  final FirebaseAuth _auth;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    // Set androidProvider to `AndroidProvider.debug`
    androidProvider: AndroidProvider.debug,
    //a24c89c8-3f17-47b0-8b06-222f25800a0d
  );
  runApp(ThisApp());

  final cron = Cron();
  cron.schedule(Schedule.parse('*/15 * * * *'), () async {
    debugPrint('reload readings 15 minutes');

    var firestore = FirebaseFirestore.instance;
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable("getDexcomReadings");
      callable({"uid": uid});
      //debugPrint(response.data);
    }
  });
}

/// Starting Root Widget
class ThisApp extends StatelessWidget {
  ThisApp({super.key});

  final GoRouter _router = GoRouter(
      navigatorKey: _key,
      debugLogDiagnostics: true,
      initialLocation: '/', //todo start on splash page
      refreshListenable: RouterNotifier(FirebaseAuth.instance),
      routes: [
        GoRoute(
          path: '/splash',
          name: 'Splash',
          builder: (context, state) {
            return const SplashPage();
          },
        ),
        GoRoute(
          path: '/',
          name: 'Home',
          builder: (context, state) {
            return const HomePage();
          },
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) {
            return SignInScreen(
              providers: [EmailAuthProvider()],
              //Place widgets above Firebase UI
              headerBuilder: (context, constraints, shrinkOffset) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Placeholder(),
                  ),
                );
              },
            );
          },
        ),
      ],
      redirect: (context, state) {
        var currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          if (state.location != '/login') {
            return state.location;
          }
          return '/';
        }
        return '/login';
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      restorationScopeId: 'foodTracker',
      title: "Food Tracker",
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Define the default brightness and colors.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
      ),
    );
  }
}
