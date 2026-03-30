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

  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color darkBackground = Color(0xFF1A1C24);
  static const Color lightGreyBody = Color(0xFFF4F7F7);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [

              if (isDesktop) ...[
                const Icon(Icons.business_outlined, size: 40, color: cyanPrimary),
                const SizedBox(height: 10),
                const Text("STOCK MANAGEMENT SYSTEM",
                    style: TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.w600)),
                const SizedBox(height: 30),
              ],

              Container(
                width: isDesktop ? 420 : size.width * 0.9,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
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
                          const Text(
                            "Login",
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: darkBackground),
                          ),
                          Container(
                            height: 4,
                            width: 40,
                            margin: const EdgeInsets.only(top: 8, bottom: 24),
                            decoration: BoxDecoration(
                              color: cyanPrimary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          const Text("IDENTIFICATION",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 1.2)),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _loginController,
                            style: const TextStyle(fontSize: 15),
                            decoration: _inputDecoration(Icons.person_outline, "Username or Email"),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 25),

                          const Text("SECURITY KEY",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 1.2)),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(fontSize: 15),
                            decoration: _inputDecoration(
                              Icons.lock_open_rounded,
                              "Password",
                              suffix: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                    size: 18, color: cyanPrimary),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                            validator: (v) => v!.length < 4 ? "Invalid Password" : null,
                          ),

                          const SizedBox(height: 35),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: state is LoginLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cyanPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: state is LoginLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("ACCESS DASHBOARD",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text("v1.0.2-stable", style: TextStyle(color: Colors.white24, fontSize: 10,fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: darkBackground.withValues(alpha: 0.5)),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 14),
      filled: true,
      fillColor: lightGreyBody,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cyanPrimary, width: 1.5)
      ),
    );
  }

  void _showCustomSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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