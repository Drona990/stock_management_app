import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _startAppFlow();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startAppFlow() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    if (GetIt.I.isRegistered<FlutterSecureStorage>()) {
      final storage = GetIt.I<FlutterSecureStorage>();
      final token = await storage.read(key: 'access_token');
      final role = await storage.read(key: 'user_role');

      if (token != null && token.isNotEmpty) {
        if (role?.toLowerCase() == 'staff') {
          context.go('/dc_terminal');
          return;
        }
        context.go('/dashboard');
        return;
      }
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Brand Color Palette based on Softwing Logo
    const Color brandBlue = Color(0xFF0066B3);
    const Color brandRed = Color(0xFFD32027);
    const Color darkBackground = Color(0xFF0B0E14);
    const Color surfaceCard = Color(0xFF141923);
    const Color textMuted = Color(0xFF8B949E);

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          // Dynamic Gradient Aura Background (Blue on Top-Right, Red on Bottom-Left)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandBlue.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandRed.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central Brand Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glassmorphic Logo Container
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: surfaceCard.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: brandBlue.withOpacity(0.2),
                            blurRadius: 35,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: brandRed.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(-5, -5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/icons/logo.png', // Ensure your logo file is placed here
                          width: 85,
                          height: 85,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Brand Typography
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "SOFTWING ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                        Text(
                          "TECH LABS",
                          style: TextStyle(
                            color: brandBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Subtitle / Tagline
                    const Text(
                      "ENTERPRISE HR & WORKFORCE PLATFORM",
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Dual Accent Line Progress Bar
                    Container(
                      width: 48,
                      height: 3.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [brandBlue, brandRed],
                        ),
                      ),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Version Branding
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "v1.0.0 • Secured Enterprise Portal",
                style: TextStyle(
                  color: textMuted.withOpacity(0.6),
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}