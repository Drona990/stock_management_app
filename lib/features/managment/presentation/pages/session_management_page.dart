
import 'dart:async';
import 'dart:convert';
import 'dart:io'; // 🌟 Added for native platform checks
import 'package:flutter/foundation.dart'; // 🌟 Added for kIsWeb support
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/io.dart'; // 🌟 Added for native socket upgrades
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../../../../core/utils/constant/Endpoints.dart';

// =============================================================================
// 1. REAL-TIME SESSION MANAGEMENT BLOC ENGINE (RESTORED TO /ws/realtime-sessions/)
// =============================================================================
abstract class SessionRealtimeEvent {}
class ConnectRealtimeStream extends SessionRealtimeEvent {}
class UpdateMetricsFromStream extends SessionRealtimeEvent {
  final List dynamicPayload;
  UpdateMetricsFromStream(this.dynamicPayload);
}
class TerminateAllUserSessions extends SessionRealtimeEvent {
  final String userId;
  final String userName;
  TerminateAllUserSessions({required this.userId, required this.userName});
}

abstract class SessionRealtimeState {}
class SessionClusterLoading extends SessionRealtimeState {}
class SessionClusterLiveLoaded extends SessionRealtimeState {
  final List userSessionTelemetry;
  SessionClusterLiveLoaded(this.userSessionTelemetry);
}
class SessionClusterError extends SessionRealtimeState {
  final String error;
  SessionClusterError(this.error);
}

class SessionRealtimeBloc
    extends Bloc<SessionRealtimeEvent, SessionRealtimeState> {
  final ApiClient api;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  SessionRealtimeBloc(this.api) : super(SessionClusterLoading()) {
    on<ConnectRealtimeStream>((event, emit) async {
      try {
        await _wsSubscription?.cancel();
        await _wsChannel?.sink.close();

        final String? token = await _secureStorage.read(key: 'access_token');
        if (token == null || token.isEmpty) {
          emit(SessionClusterError(
              "Authentication token missing. Re-login required."));
          return;
        }

        // 🌟 DYNAMIC DOMAIN RESOLUTION
        String baseHttpUrl = Endpoints.baseUrl.trim();

        if (baseHttpUrl.endsWith('/')) {
          baseHttpUrl = baseHttpUrl.substring(0, baseHttpUrl.length - 1);
        }

        String wsUrlString = "";

        if (baseHttpUrl.startsWith("https://")) {
          final String cleanDomain = baseHttpUrl.replaceFirst("https://", "");
          wsUrlString = "wss://$cleanDomain/ws/realtime-sessions/?token=${token.trim()}";
        } else if (baseHttpUrl.startsWith("http://")) {
          final String cleanIp = baseHttpUrl.replaceFirst("http://", "");
          wsUrlString = "ws://$cleanIp/ws/realtime-sessions/?token=${token.trim()}";
        } else {
          wsUrlString = "wss://$baseHttpUrl/ws/realtime-sessions/?token=${token.trim()}";
        }

        // 🌟 WINDOWS SECURE PORT EXPLICIT LOCK ENGINE
        if (!kIsWeb && Platform.isWindows) {
          if (wsUrlString.contains("test.ultra.winagrum.tech") &&
              !wsUrlString.contains(":443")) {
            wsUrlString = wsUrlString.replaceAll(
                "test.ultra.winagrum.tech", "test.ultra.winagrum.tech:443");
          } else if (wsUrlString.contains("winagrum.tech") &&
              !wsUrlString.contains(":443")) {
            wsUrlString =
                wsUrlString.replaceAll("winagrum.tech", "winagrum.tech:443");
          }
        }

        final wsUrl = Uri.parse(wsUrlString);
        debugPrint("📡 CONNECTING TO SESSION TELEMETRY SOCKET -> $wsUrlString");

        // 🌟 WINDOWS NATIVE SAFE HANDSHAKE ENGINE
        if (!kIsWeb && Platform.isWindows) {
          // Dynamic Origin format (e.g. https://test.ultra.winagrum.tech)
          final String originHeader = "https://${wsUrl.host}";

          _wsChannel = IOWebSocketChannel.connect(
            wsUrl,
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
          _wsChannel = WebSocketChannel.connect(wsUrl);
        }

        _wsSubscription = _wsChannel!.stream.listen((message) {
          debugPrint("📥 SESSION WS RECEIVED: $message");
          final decoded = jsonDecode(message);

          final List dynamicData = decoded['data'] ??
              decoded['payload'] ??
              decoded['active_sessions'] ??
              [];
          add(UpdateMetricsFromStream(dynamicData));
        }, onError: (err) {
          debugPrint("🚨 Realtime Session Network Engine Down: $err");
        }, onDone: () {
          debugPrint("🔌 WebSocket Session Connection Closed cleanly.");
        });
      } catch (e) {
        emit(SessionClusterError(
            "WebSocket Realtime Telemetry Cluster unreachable."));
      }
    });

    on<UpdateMetricsFromStream>((event, emit) {
      emit(SessionClusterLiveLoaded(event.dynamicPayload));
    });

    on<TerminateAllUserSessions>((event, emit) async {
      try {
        if (state is SessionClusterLiveLoaded) {
          final currentList =
              (state as SessionClusterLiveLoaded).userSessionTelemetry;

          // User ki devices ko runtime par map karke khali (empty) karo
          final updatedList = currentList.map((user) {
            if (user['user_id'].toString() == event.userId) {
              final modifiedUser = Map<String, dynamic>.from(user);
              modifiedUser['is_online'] = false;
              modifiedUser['is_active'] = false;
              modifiedUser['devices'] = [];
              return modifiedUser;
            }
            return user;
          }).toList();

          emit(SessionClusterLiveLoaded(List.from(updatedList)));
        }

        await api.post('/api/admin/devices/', data: {
          "user_id": event.userId,
          "action": "logout_all_devices"
        });
      } catch (e) {
        debugPrint(
            "Failed to dispatch global purge sequence command block: $e");
      }
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    return super.close();
  }
}

// =============================================================================
// 2. VIEW SURFACE: HIGH-DENSITY PURGED TRADITIONAL SCREEN
// =============================================================================
class SessionManagementPage extends StatefulWidget {
  const SessionManagementPage({super.key});

  @override
  State<SessionManagementPage> createState() => _SessionManagementPageState();
}

class _SessionManagementPageState extends State<SessionManagementPage> {
  String _searchQuery = "";
  final Map<String, bool> _expandedUserTrees = {};

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return BlocProvider(
      create: (context) => SessionRealtimeBloc(sl<ApiClient>())..add(ConnectRealtimeStream()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderHeader(),
              const SizedBox(height: 16),
              _buildSearchField(),
              const SizedBox(height: 12),
              Expanded(
                child: Builder(
                    builder: (blocContext) {
                      return _buildRealtimeGridOrTable(blocContext, isMobile);
                    }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("REAL-TIME MASTER SESSION TERMINALS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        SizedBox(height: 2),
        Text("LIVE OPERATIONAL SYSTEM TELEMETRY • CRITICAL GLOBAL ACCESS INTERCEPTOR ACTIVE", style: TextStyle(color: Color(0xFF00BCD4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        decoration: const InputDecoration(
            hintText: "Filter telemetry profiles explicitly by User Name...",
            hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
            prefixIcon: Icon(Icons.search, size: 14, color: Color(0xFF00BCD4)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.only(top: 6)
        ),
      ),
    );
  }

  Widget _buildRealtimeGridOrTable(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
      child: BlocBuilder<SessionRealtimeBloc, SessionRealtimeState>(
        builder: (context, state) {
          if (state is SessionClusterLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 2));
          if (state is SessionClusterError) return Center(child: Text(state.error, style: const TextStyle(fontSize: 11, color: Colors.red)));

          if (state is SessionClusterLiveLoaded) {
            final rawRecords = state.userSessionTelemetry;

            if (rawRecords.isEmpty) {
              return const Center(child: Text("Waiting for active structural session telemetry data stream...", style: TextStyle(fontSize: 11, color: Colors.grey)));
            }

            final userRecords = rawRecords.where((u) {
              final String name = (u['username'] ?? u['full_name'] ?? u['name'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery);
            }).toList();

            if (userRecords.isEmpty) return const Center(child: Text("No operational telemetry profiles matched.", style: TextStyle(fontSize: 11)));

            if (!isMobile) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFFF8FAFC),
                    child: Row(children: [
                      _hCell("USER CORPORE IDENTITY", 5),
                      _hCell("NETWORK STATE", 3),
                      _hCell("ACTIVE TERMINALS SYSTEM SUB-TREE", 10),
                      _hCell("SECURITY REVOCATION CONTEXT", 4, true),
                    ]),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: userRecords.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (ctx, i) => _buildLiveTelemetryRow(context, userRecords[i]),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: userRecords.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (ctx, i) => _buildMobileLiveCard(context, userRecords[i]),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLiveTelemetryRow(BuildContext context, dynamic record) {
    final bool isOnline = record['is_active'] ?? record['is_online'] ?? true;
    final List devices = record['devices'] ?? [];
    final String uId = record['user_id'].toString();
    final bool isTreeExpanded = _expandedUserTrees[uId] ?? false;

    final List visibleDevices = isTreeExpanded ? devices : devices.take(3).toList();
    final int hiddenCount = devices.length - visibleDevices.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isOnline ? const Color(0xFF00BCD4) : Colors.grey.shade400,
                  child: Text((record['username'] ?? record['name'] ?? "U")[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record['full_name'] ?? record['username'] ?? record['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                      Text(record['email'] ?? "", style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: isOnline ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(isOnline ? "LIVE NOW" : "OFFLINE", style: TextStyle(color: isOnline ? Colors.green.shade800 : Colors.grey.shade600, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            flex: 10,
            child: devices.isEmpty
                ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text("No active terminal sessions found.", style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...visibleDevices.map((dev) => _buildInlineDeviceChip(dev)).toList(),
                if (devices.length > 3) ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => setState(() => _expandedUserTrees[uId] = !isTreeExpanded),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        isTreeExpanded ? "See Less Collapse ▲" : "See More (+$hiddenCount Devices) ▼",
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF00BCD4)),
                      ),
                    ),
                  )
                ]
              ],
            ),
          ),

          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 26,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmGlobalSessionPurge(context, record),
                  icon: const Icon(Icons.gpp_bad_rounded, size: 11),
                  label: const Text("KILL SESSIONS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: Color(0xFFFCA5A5), width: 0.5)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInlineDeviceChip(dynamic dev) {
    final String devName = dev['device_name'] ?? "Generic Device";
    final String duration = dev['duration_online'] ?? dev['duration_uptime'] ?? "Just now";

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getDeviceIcon(devName), size: 11, color: Colors.blueGrey.shade600),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(fontSize: 10, color: Color(0xFF334155)),
                children: [
                  TextSpan(text: devName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: "  •  "),
                  TextSpan(text: dev['ip_address'] ?? "0.0.0.0", style: const TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 9.5)),
                  const TextSpan(text: "  •  "),
                  TextSpan(text: duration, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLiveCard(BuildContext context, dynamic record) {
    final bool isOnline = record['is_active'] ?? record['is_online'] ?? true;
    final List devices = record['devices'] ?? [];
    final String uId = record['user_id'].toString();
    final bool isTreeExpanded = _expandedUserTrees[uId] ?? false;

    final List visibleDevices = isTreeExpanded ? devices : devices.take(3).toList();
    final int hiddenCount = devices.length - visibleDevices.length;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: isOnline ? const Color(0xFF00BCD4).withOpacity(0.3) : Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(record['full_name'] ?? record['username'] ?? "User Node", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                InkWell(
                  onTap: () => _confirmGlobalSessionPurge(context, record),
                  child: const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 16),
                )
              ],
            ),
            const Divider(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (devices.isEmpty)
                  Text("No active terminal sessions found.", style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontStyle: FontStyle.italic))
                else ...[
                  ...visibleDevices.map((d) => _buildInlineDeviceChip(d)).toList(),
                  if (devices.length > 3) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _expandedUserTrees[uId] = !isTreeExpanded),
                      child: Text(
                        isTreeExpanded ? "See Less ▲" : "See More (+$hiddenCount) ▼",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00BCD4)),
                      ),
                    )
                  ]
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _hCell(String t, int f, [bool r = false]) => Expanded(flex: f, child: Text(t, textAlign: r ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)));

  IconData _getDeviceIcon(String device) {
    final d = device.toLowerCase();
    if (d.contains('windows')) return Icons.desktop_windows_outlined;
    if (d.contains('flutter') || d.contains('android') || d.contains('mobile')) return Icons.phone_android_outlined;
    if (d.contains('mac') || d.contains('iphone')) return Icons.laptop_mac_outlined;
    return Icons.devices_other_outlined;
  }

  Future<void> _confirmGlobalSessionPurge(BuildContext context, dynamic record) async {
    final bloc = context.read<SessionRealtimeBloc>();
    final String targetName = record['full_name'] ?? record['username'] ?? "This Account";
    final String targetUserId = record['user_id'].toString();

    return showDialog(
      context: context,
      builder: (dialogContext) => AppContextDialog(
        targetName: targetName,
        onConfirm: () {
          bloc.add(TerminateAllUserSessions(userId: targetUserId, userName: targetName));
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("🚨 Dispatched absolute flush sequence command matrix for $targetName"), backgroundColor: Colors.red.shade900)
          );
        },
      ),
    );
  }
}

class AppContextDialog extends StatelessWidget {
  final String targetName;
  final VoidCallback onConfirm;
  const AppContextDialog({super.key, required this.targetName, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text("CRITICAL: Invalidate Access Tokens", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            const TextSpan(text: "Are you absolutely verified to initiate a complete structural token wipeout for "),
            TextSpan(text: targetName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const TextSpan(text: "? This action will forcibly close all active sub-tree connections immediately."),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(fontSize: 11, color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
          child: const Text("PURGE ALL TERMINALS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}