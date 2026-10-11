import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../auth/role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _animController.repeat(reverse: true);

    // Transition to main screen after 2.3 seconds
    Timer(const Duration(milliseconds: 2300), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (ctx, anim1, anim2) => const RoleSelectionScreen(),
            transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Pulsing Heartbeat / Blood Droplet Icon
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE57373), Color(0xFFD9534F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(55),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bloodtype_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              const Text(
                'LifeFlow Blood Bank',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Live Blood Availability, Nearby Routing & Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),

              // Subtle, pleasant loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withAlpha(180)),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Connecting to Nearby Blood Centres in India...',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
