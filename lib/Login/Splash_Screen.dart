import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ornatique/Login/login_screen.dart';
import 'package:ornatique/Screens/DashBoardScreen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String? uid;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Full duration = 10s
    );

    // Fade in over 7s → Hold for 2s → Fade out in 1s
    _fadeAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.linear)),
        weight: 70, // 0–7s
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 20, // 7–9s
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10, // 9–10s
      ),
    ]).animate(_controller);

    // Optional: scale animation (light zoom in)
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70, // Zoom in during fade in
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 30,
      ),
    ]).animate(_controller);

    checkpref();



    _controller.forward();

    // Navigate after full animation (10s)
    Timer(const Duration(seconds: 3), () {
      navigateNext();
    });
  }

  void navigateNext() {
    if (uid.toString() == "null") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashBoardScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Image.asset(
              'assets/splash logo.png',
              height: 400,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> checkpref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getString("Uid").toString();
    print(uid.toString());
    prefs.remove("firstTimePopup");

    final info = await PackageInfo.fromPlatform();
    print("App Latest Version===============>"+info.version.toString());
  }





}
