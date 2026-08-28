import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../core/utils/app_routes.dart';
import 'core/theme/app_color.dart';
import 'features/auth/presentation/block/login_bloc.dart';
import 'injection.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // 🌟 ENGINE: Start or reset inactivity tracking loop
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(days: 360), _handleAutoLogout);
  }

  // 🌟 TRIGGER: Core action when timer reaches explicit limit (5 min)
  Future<void> _handleAutoLogout() async {
    if (!GetIt.I.isRegistered<FlutterSecureStorage>()) return;
    final storage = GetIt.I<FlutterSecureStorage>();

    // Clear dynamic auth tokens safely
    final String? token = await storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'user_role');

      // Kick user instantly to Login page via public root navigation key channel
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired. Re-Login again."),
            backgroundColor: Colors.redAccent,
          ),
        );
        AppRouter.router.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (context) => sl<LoginBloc>()),

      ],
      child: GestureDetector(
        // 🌟 CAPTURE EVERY USER TOUCH MATRIX -> Reset dynamic timer pulse on interaction
        behavior: HitTestBehavior.translucent,
        onTap: _startInactivityTimer,
        onPanDown: (_) => _startInactivityTimer(),
        onScaleStart: (_) => _startInactivityTimer(),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.router,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.backgroundGrey,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryCyan,
              primary: AppColors.primaryCyan,
              onPrimary: AppColors.pureWhite,
              surface: AppColors.pureWhite,
              onSurface: AppColors.deepBlack,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(color: AppColors.deepBlack, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(color: AppColors.deepBlack),
              bodyMedium: TextStyle(color: AppColors.textGrey),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.pureWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryCyan, width: 2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: AppColors.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}