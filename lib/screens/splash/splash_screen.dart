import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/screens/auth/login_screen.dart';
import 'package:kisanbazaar/screens/buyer/buyer_dashboard.dart';
import 'package:kisanbazaar/screens/seller/seller_dashboard.dart';
import 'package:kisanbazaar/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
             duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

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
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // KisanBazaar Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "KisanBazaar",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Fresh From Farmers 🌾",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 50),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
