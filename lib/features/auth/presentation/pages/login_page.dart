import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../block/login_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // --- Premium Industrial Financial Themes ---
  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color slateNavy = Color(0xFF1E293B);
  static const Color deepCarbon = Color(0xFF0F172A);
  static const Color inputBgFields = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    return Scaffold(
      backgroundColor: deepCarbon,
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              flex: 4,
              child: Container(
                color: deepCarbon,
                padding: const EdgeInsets.all(50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_rounded, size: 28, color: cyanPrimary),
                        SizedBox(width: 12),
                        Text(
                          "CORE FINANCE LOGISTICS",
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Commercial Ledger\n& Auditing Portal Engine.",
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Secure multi-tenant accounting core gateway. Enter corporate digital certificates signature keys to sync unified data directories ledger sheets.",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.6, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 50),
                    // Quick micro security indicator badges
                    Row(
                      children: [
                        _buildStatusIndicator("AES-256 BANKING ENCRYPTION"),
                        const SizedBox(width: 12),
                        _buildStatusIndicator("COMPLIANT TAX WORKSPACE"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            flex: isDesktop ? 3 : 7,
            child: Container(
              height: double.infinity,
              color: isDesktop ? Colors.white : deepCarbon,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 50 : 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: BlocConsumer<LoginBloc, LoginState>(
                    listener: (context, state) {
                      if (state is LoginSuccess) {
                        context.go("/dashboard");
                      } else if (state is LoginFailure) {
                        _showCustomSnackBar(context, state.error);
                      }
                    },
                    builder: (context, state) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mobile View Top Branding Wrapper
                            if (!isDesktop) ...[
                              const Center(
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white10,
                                  child: Icon(Icons.account_balance_rounded, size: 22, color: cyanPrimary),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Center(
                                child: Text(
                                  "COMMERCIAL LEDGER SYSTEM",
                                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],

                            Text(
                              "System Sign In",
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: isDesktop ? deepCarbon : Colors.white,
                                  letterSpacing: -0.5
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Provide certified credentials below to sync ledger registries.",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 24),

                            // Input Layer 1: Account Identifier Checkbox
                            Text(
                              "ACCOUNT IDENTIFICATION",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  color: isDesktop ? slateNavy.withOpacity(0.7) : Colors.grey.shade400,
                                  letterSpacing: 1.0
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _loginController,
                              style: TextStyle(fontSize: 13, color: isDesktop ? deepCarbon : Colors.white),
                              decoration: _inputDecoration(Icons.person_outline_rounded, "Username or Corporate Email", isDesktop),
                              validator: (v) => (v == null || v.isEmpty) ? "Identification target context required" : null,
                            ),
                            const SizedBox(height: 20),

                            // Input Layer 2: Security Key Parameters
                            Text(
                              "ACCOUNT SECURITY KEY",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  color: isDesktop ? slateNavy.withOpacity(0.7) : Colors.grey.shade400,
                                  letterSpacing: 1.0
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: TextStyle(fontSize: 13, color: isDesktop ? deepCarbon : Colors.white),
                              decoration: _inputDecoration(
                                Icons.lock_open_rounded,
                                "Account Access Token Key",
                                isDesktop,
                                suffix: IconButton(
                                  icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 16,
                                      color: cyanPrimary
                                  ),
                                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 4) ? "Invalid structural password sequence" : null,
                            ),

                            const SizedBox(height: 30),

                            // Dynamic Action Core Execution Dispatch Button
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: state is LoginLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cyanPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                child: state is LoginLoading
                                    ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                                    : const Text(
                                    "AUTHENTICATE FINANCE ARCHITECTURE",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Center(
                              child: Text(
                                "FINANCIAL CONTEXT DESCRIPTOR APP CORE ENGINE v1.1.0-STABLE",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint, bool isDesktop, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 16, color: isDesktop ? slateNavy.withOpacity(0.5) : Colors.white60),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      filled: true,
      fillColor: isDesktop ? inputBgFields : Colors.white.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: isDesktop ? BorderSide.none : const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: cyanPrimary, width: 1.2),
      ),
    );
  }

  Widget _buildStatusIndicator(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  void _showCustomSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
        LoginSubmitted(_loginController.text, _passwordController.text),
      );
    }
  }
}