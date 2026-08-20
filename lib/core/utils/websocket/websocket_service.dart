
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../app_routes.dart';
import '../constant/Endpoints.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  final StreamController<Map<String, dynamic>> _centralEventStreamController =
  StreamController<Map<String, dynamic>>.broadcast();

  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final _storage = const FlutterSecureStorage();

  bool _isConnecting = false;
  String? _cachedAuthToken;

  Stream<Map<String, dynamic>> get centralEventStream =>
      _centralEventStreamController.stream;

  void initCentralGateway() async {
    if (isConnected.value) {
      _channel?.sink.close();
      isConnected.value = false;
    }

    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) return;

    _cachedAuthToken = token;

    // Clean base URL properly
    String baseHttpUrl = Endpoints.baseUrl.trim();

    String wsProtocol = "ws://";
    if (baseHttpUrl.startsWith("https://")) {
      wsProtocol = "wss://";
      baseHttpUrl = baseHttpUrl.replaceFirst("https://", "");
    } else if (baseHttpUrl.startsWith("http://")) {
      wsProtocol = "ws://";
      baseHttpUrl = baseHttpUrl.replaceFirst("http://", "");
    }

    // Trailing slash clean up
    if (baseHttpUrl.endsWith('/')) {
      baseHttpUrl = baseHttpUrl.substring(0, baseHttpUrl.length - 1);
    }

    if (!kIsWeb && Platform.isWindows) {
      if (baseHttpUrl.contains("test.ultra.winagrum.tech") &&
          !baseHttpUrl.contains(":443")) {
        baseHttpUrl = baseHttpUrl.replaceAll(
            "test.ultra.winagrum.tech", "test.ultra.winagrum.tech:443");
      } else if (baseHttpUrl.contains("winagrum.tech") &&
          !baseHttpUrl.contains(":443")) {
        baseHttpUrl =
            baseHttpUrl.replaceAll("winagrum.tech", "winagrum.tech:443");
      }
    }

    // Explicit Clean connection URI
    String connectionUri =
        "$wsProtocol$baseHttpUrl/ws/live/gateway/?token=${token.trim()}";

    _connect(connectionUri);
  }

  void _connect(String url) {
    if (_isConnecting || _centralEventStreamController.isClosed) return;
    _isConnecting = true;

    try {
      debugPrint("📡 CONNECTING TO CENTRAL GATEWAY PIPELINE: $url");

      Uri parsedUri = Uri.parse(url);

      // 🌟 WINDOWS NATIVE SAFE HANDSHAKE ENGINE SWITCH WITH ORIGIN HEADER
      if (!kIsWeb && Platform.isWindows) {

        // Dynamic origin format matching scheme (https://domain)
        String originHeader = "https://${parsedUri.host}";

        _channel = IOWebSocketChannel.connect(
          parsedUri,
          headers: {
            'Origin': originHeader, // 👈 KEY FIX: Added Required Origin Header
            'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) FlutterDesktopClient',
          },
          customClient: HttpClient()
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) => true,
        );
      } else {
        _channel = WebSocketChannel.connect(parsedUri);
      }

      _channel!.stream.listen(
            (message) {
          _isConnecting = false;
          isConnected.value = true;

          try {
            final Map<String, dynamic> packet = jsonDecode(message);
            final String eventType = packet['type'] ?? "";
            final dynamic payload = packet['payload'] ?? {};

            if (eventType == "FORCE_LOGOUT") {
              _executeEmergencyKillSwitch(payload);
              return;
            }

            if (!_centralEventStreamController.isClosed) {
              _centralEventStreamController.add(packet);
            }
          } catch (e) {
            debugPrint("⚠️ Central Parsing Crash Matrix Exception: $e");
          }
        },
        onError: (error) {
          debugPrint("❌ CENTRAL SOCKET ERROR: $error");
          _onChannelTeardown();
        },
        onDone: () {
          debugPrint("🔌 CENTRAL PIPELINE SHUTDOWN BY HOST STACK");
          _onChannelTeardown();
        },
      );
    } catch (e) {
      debugPrint("⚠️ CENTRAL BOUNDARY CRASH: $e");
      _onChannelTeardown();
    }
  }

  void _executeEmergencyKillSwitch(dynamic payload) async {
    debugPrint(
        "🚨 ADMIN TERMINATION EVENT DETECTED: Blowing local authorization tokens.");

    _cachedAuthToken = null;
    _channel?.sink.close();
    isConnected.value = false;

    final String currentSessionId =
        await _storage.read(key: 'session_id') ?? "";
    String scope = payload['scope'] ?? "";
    String targetSession = payload['target_session_id'] ?? "";

    if (scope == "GLOBAL_KILL" ||
        (scope == "SINGLE_DEVICE" && targetSession == currentSessionId)) {
      await _storage.deleteAll();

      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text("🛑 SECURITY ACCOUNT EXPIRED: ${payload['message']}"),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
        AppRouter.router.go('/login');
      }
    }
  }

  void sendPayloadEvent(String eventType, Map<String, dynamic> dataPayload) {
    if (_channel != null && isConnected.value) {
      final outboundFrame =
      jsonEncode({"type": eventType, "payload": dataPayload});
      _channel!.sink.add(outboundFrame);
    }
  }

  void _onChannelTeardown() {
    _isConnecting = false;
    isConnected.value = false;
    _channel = null;

    if (_cachedAuthToken != null) {
      debugPrint("🔄 Re-instantiating central streaming bridge in 5 seconds...");
      Future.delayed(const Duration(seconds: 5), () {
        if (_cachedAuthToken != null && !isConnected.value && !_isConnecting) {
          initCentralGateway();
        }
      });
    }
  }

  void closeGateway() {
    _cachedAuthToken = null;
    _channel?.sink.close();
    isConnected.value = false;
  }
}