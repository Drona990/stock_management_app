import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'injection.dart' as di;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Notification tapped in background: ${notificationResponse.payload}');
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const LinuxInitializationSettings linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');
    const WindowsInitializationSettings windowInit = WindowsInitializationSettings(
      appName: 'Svenska Accounting',
      appUserModelId: 'com.svenska.stock.app',
      guid: '9f8b4d8d-2d9d-4e9d-8d8d-9d8d8d8d8d8e',
    );

    await flutterLocalNotificationsPlugin.initialize(
        onDidReceiveNotificationResponse: (response) => debugPrint(response.payload),
        settings: InitializationSettings(
            android: androidInit,
            iOS: iosInit,
            macOS: iosInit,
            linux: linuxInit,
            windows: windowInit
        )
    );

    await dotenv.load(fileName: ".env");
    await di.init();

    runApp(const MyApp());
  } catch (e) {
    debugPrint("INIT ERROR: $e");
    runApp(const MyApp());
  }
}