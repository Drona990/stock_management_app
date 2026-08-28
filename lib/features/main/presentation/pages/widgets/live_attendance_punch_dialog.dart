import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showLiveAttendancePunchModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const LiveAttendancePunchDialog(),
  );
}

class LiveAttendancePunchDialog extends StatefulWidget {
  const LiveAttendancePunchDialog({super.key});

  @override
  State<LiveAttendancePunchDialog> createState() => _LiveAttendancePunchDialogState();
}

class _LiveAttendancePunchDialogState extends State<LiveAttendancePunchDialog> {
  // Theme Palette
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color surfaceBg = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF8B949E);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color roseRed = Color(0xFFF43F5E);

  bool _isProcessing = false;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _handlePunch(String punchType) async {
    setState(() => _isProcessing = true);
    try {
      // Backend API latency simulation
      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  "✅ $punchType recorded successfully at ${DateFormat('hh:mm a').format(_currentTime)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            backgroundColor: punchType == "CHECK-IN" ? emeraldGreen : roseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Punch submission failed: $e"),
            backgroundColor: roseRed,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 500;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Center(
        child: Container(
          width: isMobile ? double.infinity : 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: brandBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: brandBlue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "ATTENDANCE TERMINAL",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: deepNavy,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18, color: textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Live Digital Clock Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: surfaceBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('hh:mm:ss a').format(_currentTime),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: deepNavy,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_currentTime),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Shift Info Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: brandBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ASSIGNED SHIFT",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textMuted),
                    ),
                    Text(
                      "GS-01 • 09:30 AM to 06:30 PM",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: brandBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: brandBlue, strokeWidth: 2),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handlePunch("CHECK-IN"),
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: const Text(
                          "PUNCH IN",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handlePunch("CHECK-OUT"),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text(
                          "PUNCH OUT",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: roseRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}