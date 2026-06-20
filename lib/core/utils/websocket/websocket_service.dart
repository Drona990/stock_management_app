import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../app_routes.dart';
import '../constant/Endpoints.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  // Central Broadcast Stream for the entire application to listen to real-time events
  final StreamController<Map<String, dynamic>> _centralEventStreamController =
  StreamController<Map<String, dynamic>>.broadcast();

  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final _storage = const FlutterSecureStorage();

  bool _isConnecting = false;
  String? _cachedAuthToken;

  Stream<Map<String, dynamic>> get centralEventStream => _centralEventStreamController.stream;

  /// Initializes the Central WebSocket Gateway connection
  void initCentralGateway() async {
    // If already connected, safely close the existing connection before re-authenticating
    if (isConnected.value) {
      _channel?.sink.close();
      isConnected.value = false;
    }

    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) return;

    _cachedAuthToken = token;

    String baseHttpUrl = Endpoints.baseUrl.trim();
    String connectionUri = "";

    // 🌟 PURE DYNAMIC PROTOCOL DETECTOR ENGINE
    String wsProtocol = "ws://";
    if (baseHttpUrl.startsWith("https://")) {
      wsProtocol = "wss://";
      baseHttpUrl = baseHttpUrl.replaceFirst("https://", "");
    } else if (baseHttpUrl.startsWith("http://")) {
      wsProtocol = "ws://";
      baseHttpUrl = baseHttpUrl.replaceFirst("http://", "");
    }

    // Builds the dynamic secure matrix pipeline routing URI
    connectionUri = "$wsProtocol$baseHttpUrl/ws/live/gateway/?token=$token";

    _connect(connectionUri);
  }

  /// Establishes connection to the WebSocket endpoint and handles incoming data streams
  void _connect(String url) {
    if (_isConnecting || _centralEventStreamController.isClosed) return;
    _isConnecting = true;

    try {
      debugPrint("📡 CONNECTING TO CENTRAL GATEWAY PIPELINE: $url");
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
            (message) {
          _isConnecting = false;
          isConnected.value = true;

          try {
            final Map<String, dynamic> packet = jsonDecode(message);
            final String eventType = packet['type'] ?? "";
            final dynamic payload = packet['payload'] ?? {};

            // ======================================================================
            // 🛡️ BRANCH 1: INTERNAL CENTRAL REAL-TIME SECURITY ALERTS MUX
            // ======================================================================
            if (eventType == "FORCE_LOGOUT") {
              _executeEmergencyKillSwitch(payload);
              return; // Security pulse breaks flow execution instantly
            }

            // ======================================================================
            // 📦 BRANCH 2: REGULAR DATA STREAMS (ORDERS, INVENTORIES, METRICS)
            // ======================================================================
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

  /// Triggered by Admin Cluster Event to forcefully log out a breached session
  void _executeEmergencyKillSwitch(dynamic payload) async {
    debugPrint("🚨 ADMIN TERMINATION EVENT DETECTED: Blowing local authorization tokens.");

    _cachedAuthToken = null; // Kill retry criteria pointer loops
    _channel?.sink.close();
    isConnected.value = false;

    final String currentSessionId = await _storage.read(key: 'session_id') ?? "";
    String scope = payload['scope'] ?? "";
    String targetSession = payload['target_session_id'] ?? "";

    if (scope == "GLOBAL_KILL" || (scope == "SINGLE_DEVICE" && targetSession == currentSessionId)) {
      await _storage.deleteAll(); // Hard clean token stores metadata arrays

      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🛑 SECURITY ACCOUNT EXPIRED: ${payload['message']}"),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
        AppRouter.router.go('/login');
      }
    }
  }

  /// Outbound frame payload dispatcher transmitter
  void sendPayloadEvent(String eventType, Map<String, dynamic> dataPayload) {
    if (_channel != null && isConnected.value) {
      final outboundFrame = jsonEncode({
        "type": eventType,
        "payload": dataPayload
      });
      _channel!.sink.add(outboundFrame);
    }
  }

  /// Handles network failure dropouts and triggers an auto-retry mechanism in 5 seconds
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

  /// Gracefully closes the streaming gateway connection manually (e.g., on User Logout)
  void closeGateway() {
    _cachedAuthToken = null;
    _channel?.sink.close();
    isConnected.value = false;
  }
}