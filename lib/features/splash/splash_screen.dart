import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _taglineOpacityAnimation;
  late Animation<double> _taglineSlideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Add animations for the tagline
    _taglineOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );
    
    _taglineSlideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Initialize Hive and check if it's the first launch of the day
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for the animation to complete
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        // Navigate directly to the journal screen
        context.go('/journal');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/icons/splash-icon.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 24),
                    // App name
                    const Text(
                      'PinkRain',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tagline with enhanced animation
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _taglineSlideAnimation.value),
                          child: Opacity(
                            opacity: _taglineOpacityAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: ChimeBellText(
                                text: "It's time to feel better",
                                duration: Duration(milliseconds: 700),
                                type: AnimationType.word,
                                textStyle: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF4A4A4A)
                                )
                            ),
                          ),
                        )
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
