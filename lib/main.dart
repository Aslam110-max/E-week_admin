import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:eweek_admin/Dimentions/dimention.dart';
import 'package:eweek_admin/homePage/homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: MainPage());
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
        animationDuration: Duration(milliseconds: 5),
        splashIconSize: Dimensions.screenHeight,
        splash: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Image.asset('images/logo.png',height: Dimensions.height10*7,width: Dimensions.height10*7,),
          ),
        ),
        nextScreen: HomePage(),
       splashTransition: SplashTransition.rotationTransition,
      pageTransitionType: PageTransitionType.fade,
      );
  }
}
