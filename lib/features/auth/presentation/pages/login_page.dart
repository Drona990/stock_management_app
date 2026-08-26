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

  // --- Softwing Tech Labs Corporate Theme Palette ---
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandRed = Color(0xFFD32027);
  static const Color deepCarbon = Color(0xFF0B0E14);
  static const Color surfaceCard = Color(0xFF141923);
  static const Color inputBgLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF8B949E);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    return Scaffold(
      backgroundColor: deepCarbon,
      body: Row(
        children: [
          // Left Banner: Desktop Branding & HRMS Context
          if (isDesktop)
            Expanded(
              flex: 4,
              child: Container(
                color: deepCarbon,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Badge Header
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/icons/logo.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          "SOFTWING TECH LABS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "Unified Workforce\n& ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: "Payroll Portal.",
                            style: TextStyle(
                              color: brandBlue,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Secure enterprise workspace for managing employee master records, dynamic attendance, digital salary slips, and verified credentials.",
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 13,
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Trust & Compliance Badges
                    Row(
                      children: [
                        _buildStatusIndicator("MSME RECOGNIZED", brandBlue),
                        const SizedBox(width: 12),
                        _buildStatusIndicator("ROLE-BASED JWT ACCESS", Colors.greenAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Right Banner: Login Credentials Form
          Expanded(
            flex: isDesktop ? 3 : 7,
            child: Container(
              height: double.infinity,
              color: isDesktop ? Colors.white : deepCarbon,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 50 : 24),
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
                            // Mobile Top Logo View
                            if (!isDesktop) ...[
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: surfaceCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Image.asset(
                                    'assets/icons/logo.png',
                                    width: 42,
                                    height: 42,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Center(
                                child: Text(
                                  "SOFTWING TECH LABS • HRMS",
                                  style: TextStyle(
                                    color: brandBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),
                            ],

                            Text(
                              "Sign In to HRMS",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: isDesktop ? deepCarbon : Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Enter your official credentials to access staff operations.",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDesktop ? Colors.grey.shade600 : textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Field 1: User / Email
                            Text(
                              "USERNAME OR WORK EMAIL",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: isDesktop ? const Color(0xFF1E293B) : Colors.grey.shade400,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _loginController,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDesktop ? deepCarbon : Colors.white,
                              ),
                              decoration: _inputDecoration(
                                Icons.badge_outlined,
                                "e.g. admin or employee@softwing.com",
                                isDesktop,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? "Identification required"
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // Field 2: Password
                            Text(
                              "PORTAL PASSWORD",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: isDesktop ? const Color(0xFF1E293B) : Colors.grey.shade400,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDesktop ? deepCarbon : Colors.white,
                              ),
                              decoration: _inputDecoration(
                                Icons.lock_outline_rounded,
                                "Enter your access password",
                                isDesktop,
                                suffix: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: brandBlue,
                                  ),
                                  onPressed: () => setState(
                                          () => _isPasswordVisible = !_isPasswordVisible),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 4)
                                  ? "Enter a valid password"
                                  : null,
                            ),

                            const SizedBox(height: 32),

                            // Action Button: Primary Tech Blue
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: state is LoginLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: state is LoginLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  "AUTHENTICATE & ENTER",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Footer Tag
                            Center(
                              child: Text(
                                "SOFTWING HR & WORKFORCE CORE v1.0.0",
                                style: TextStyle(
                                  color: isDesktop ? Colors.grey.shade400 : textMuted.withOpacity(0.6),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
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
      prefixIcon: Icon(
        icon,
        size: 18,
        color: isDesktop ? const Color(0xFF64748B) : Colors.white60,
      ),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: TextStyle(
        color: isDesktop ? Colors.grey.shade400 : Colors.white30,
        fontSize: 12,
      ),
      filled: true,
      fillColor: isDesktop ? inputBgLight : surfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDesktop ? const Color(0xFFE2E8F0) : Colors.white12,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: brandBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: brandRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: brandRed, width: 1.5),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        backgroundColor: brandRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
        LoginSubmitted(_loginController.text.trim(), _passwordController.text),
      );
    }
  }
}