
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();

  // 🟢 Connection Status Tracker
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  bool _isConnecting = false;
  String? _currentRole;
  String? _currentId;

  // 🔗 Laptop/Server IP
  final String _baseWsUrl = "ws://10.56.210.96:8000/ws/order";

  Stream<dynamic> get stream => _controller.stream;

  void initConnection(String role, String id) {
    if (isConnected.value) {
      _channel?.sink.close();
      isConnected.value = false;
    }

    _currentRole = role;
    _currentId = id;
    final String fullUrl = "$_baseWsUrl/$role/$id/";
    _connect(fullUrl);
  }

  void _connect(String url) {
    if (_isConnecting || _controller.isClosed) return;
    _isConnecting = true;

    try {
      debugPrint("🚀 ATTEMPTING WS CONNECT: $url");

      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
            (message) {
          _isConnecting = false;
          isConnected.value = true;
          debugPrint("📥 WS RECEIVED: $message");

          try {
            final data = jsonDecode(message);
            if (!_controller.isClosed) _controller.add(data);
          } catch (e) {
            debugPrint("⚠️ WS JSON Parsing Error: $e");
          }
        },
        onError: (error) {
          debugPrint("❌ WS ERROR: $error");
          _onConnectionLost();
        },
        onDone: () {
          debugPrint("🔌 WS DISCONNECTED FROM SERVER");
          _onConnectionLost();
        },
      );
    } catch (e) {
      debugPrint("⚠️ WS EXCEPTION: $e");
      _onConnectionLost();
    }
  }

  void _onConnectionLost() {
    _isConnecting = false;
    isConnected.value = false;
    _channel = null;

    if (_currentRole != null) {
      debugPrint("🔄 Retrying connection in 5 seconds...");
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_currentRole != null && !isConnected.value && !_isConnecting) {
        initConnection(_currentRole!, _currentId!);
      }
    });
  }

  void dispose() {
    debugPrint("🧹 Disposing WebSocket Service");
    _currentRole = null;
    _channel?.sink.close();
    isConnected.value = false;
  }
}