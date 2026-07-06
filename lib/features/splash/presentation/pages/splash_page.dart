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

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startAppFlow();
  }

  Future<void> _startAppFlow() async {
    await Future.delayed(const Duration(seconds: 2));
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
    const Color darkBackground = Color(0xFF101218);
    const Color cyanPrimary = Color(0xFF00BCD4);
    const Color surfaceGrey = Color(0xFF1A1C24);

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    cyanPrimary.withOpacity(0.05),
                    darkBackground,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceGrey,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: cyanPrimary.withOpacity(0.5), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: cyanPrimary.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Image.asset(
                            'assets/icons/logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  "SVENSKA SYSTEMS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "POWERING ACCOUNTING INTELLIGENCE",
                  style: TextStyle(
                    color: cyanPrimary.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 50),
                const SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor: surfaceGrey,
                    color: cyanPrimary,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}