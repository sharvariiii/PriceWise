//splash_screen.dart - SplashScreen widget displays an animation for a few seconds
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pricewise/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int splashtime = 3; // duration of splash screen (in seconds)

  @override
  void initState() {
    Future.delayed(Duration(seconds: splashtime), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return const HomeScreen();
      }));
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Lottie.asset(
        //'https://assets3.lottiefiles.com/packages/lf20_9evakyqx.json'
        ('assets/Animation.json'))));
  }
}
