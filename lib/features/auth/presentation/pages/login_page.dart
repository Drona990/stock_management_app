import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../block/login_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isPasswordVisible = false;
  bool _isScanningLocked = false;

  // Theme Colors
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandCyan = Color(0xFF06B6D4);
  static const Color deepCarbon = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF8B949E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetectBarcode(BarcodeCapture capture) {
    if (_isScanningLocked) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? raw = barcodes.first.rawValue;
    if (raw != null && raw.isNotEmpty) {
      setState(() => _isScanningLocked = true);
      context.read<LoginBloc>().add(LoginWithQRSubmitted(raw));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    return Scaffold(
      backgroundColor: deepCarbon,
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            context.go('/dashboard');
          } else if (state is LoginFailure) {
            setState(() => _isScanningLocked = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Logo & Branding
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: brandBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fingerprint_rounded, color: brandCyan, size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "SOFTWING WORKFORCE",
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enterprise Personnel Self-Service Portal",
                      style: TextStyle(color: textMuted, fontSize: 10.5),
                    ),
                    const SizedBox(height: 20),

                    // Navigation Tabs: QR Access vs Credentials
                    Container(
                      height: 40,
                      decoration: BoxDecoration(color: deepCarbon, borderRadius: BorderRadius.circular(8)),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: textMuted,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(color: brandBlue, borderRadius: BorderRadius.circular(7)),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(iconMargin: EdgeInsets.zero, text: "QR PASS SCAN"),
                          Tab(iconMargin: EdgeInsets.zero, text: "CREDENTIALS"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tab Views
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // Tab 1: Live QR Scanner
                          _buildQRScannerTab(state),

                          // Tab 2: Manual Email & Password Form
                          _buildCredentialsFormTab(state),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      "SOFTWING HRMS • POWERED BY ZERO-TRUST SECURITY",
                      style: TextStyle(color: Colors.white24, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQRScannerTab(LoginState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brandCyan, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetectBarcode,
                ),
                if (state is LoginLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator(color: brandCyan)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Scan the Login Pass assigned by your Admin to enter.",
          textAlign: TextAlign.center,
          style: TextStyle(color: textMuted, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildCredentialsFormTab(LoginState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("OFFICIAL WORK EMAIL / EMP CODE", style: TextStyle(color: textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _loginController,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            decoration: _inputStyle(Icons.alternate_email_rounded, "name@softwing.in"),
            validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
          ),
          const SizedBox(height: 14),
          const Text("PORTAL PASSWORD", style: TextStyle(color: textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            decoration: _inputStyle(
              Icons.lock_outline_rounded,
              "Enter your password",
              suffix: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 16, color: textMuted),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (v) => (v == null || v.length < 4) ? "Valid password required" : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: state is LoginLoading
                  ? null
                  : () {
                if (_formKey.currentState!.validate()) {
                  context.read<LoginBloc>().add(
                    LoginSubmitted(_loginController.text.trim(), _passwordController.text),
                  );
                }
              },
              child: state is LoginLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("AUTHENTICATE ACCOUNT", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white60, size: 16),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
      filled: true,
      fillColor: deepCarbon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }
}