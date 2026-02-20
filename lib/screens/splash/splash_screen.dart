import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/screens/auth/login_screen.dart';
import 'package:kisanbazaar/screens/buyer/buyer_dashboard.dart';
import 'package:kisanbazaar/screens/seller/seller_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
             duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
    _checkUserStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkUserStatus() async {
    try {
      // Allow animation to play for 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) _navigateToScreen(const LoginScreen());
        return;
      }

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!userDoc.exists) {
        if (mounted) _navigateToScreen(const LoginScreen());
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String role = (userData['role'] ?? '').toString().trim().toLowerCase();

      if (mounted) {
        if (role == 'buyer') {
          _navigateToScreen(const BuyerDashboard());
        } else if (role == 'seller') {
          _navigateToScreen(SellerDashboard());
        } else {
          _navigateToScreen(const LoginScreen());
        }
      }
    } catch (e) {
      debugPrint('Error in _checkUserStatus: $e');
      if (mounted) _navigateToScreen(const LoginScreen());
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // KisanBazaar Logo
              Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                "KisanBazaar",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32), // Professional Dark Green
                  letterSpacing: 1.2,
                  fontFamily: 'Roboto', // Clean sans-serif
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Farm to Market, Simplified",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 50),

              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
