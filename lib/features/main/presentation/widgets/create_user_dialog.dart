import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../pages/bar&resturant/user_management_page.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final storage = const FlutterSecureStorage();

  String _selectedRole = "staff";
  String _currentUserRole = "";
  bool _isLoading = false;
  bool _isPermissionLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final role = await storage.read(key: 'user_role') ?? 'staff';
    if (mounted) {
      setState(() {
        _currentUserRole = role.toLowerCase();
        _isPermissionLoaded = true;
      });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Dynamic Endpoint logic
      final String path = _selectedRole == 'admin'
          ? '/api/admin/create/'
          : '/api/staff/create/';

      final response = await sl<ApiClient>().post(path, data: {
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "name": _nameController.text.trim(),
        "role": _selectedRole,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${_selectedRole.toUpperCase()} Created Successfully!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Refresh list
          context.read<UserMgmtBloc>().add(LoadUsers());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    List<DropdownMenuItem<String>> roleItems = [
      if (_currentUserRole == 'superuser')
        const DropdownMenuItem(value: "admin", child: Text("Administrator / Manager")),

      const DropdownMenuItem(value: "staff", child: Text("Restaurant Staff")),
      const DropdownMenuItem(value: "chef", child: Text("Kitchen Chef")),
      const DropdownMenuItem(value: "barman", child: Text("Bar Specialist")),
      const DropdownMenuItem(value: "waiter", child: Text("Restaurant Waiter")),

    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Provision New Credential",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1C24))),
                const SizedBox(height: 8),
                const Text("Set up login access for your restaurant team members.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 32),

                _buildLabel("FULL NAME"),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputStyle("e.g. Drona Tandi", Icons.person_outline),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),

                _buildLabel("EMAIL ADDRESS"),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputStyle("staff@restaurant.com", Icons.email_outlined),
                  validator: (v) => !v!.contains("@") ? "Invalid email" : null,
                ),
                const SizedBox(height: 20),

                _buildLabel("TEMPORARY PASSWORD"),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputStyle("••••••••", Icons.lock_outline),
                  validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
                ),
                const SizedBox(height: 20),

                _buildLabel("ACCESS LEVEL"),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: roleItems, // ✅ Filtered Items
                  onChanged: (val) => setState(() => _selectedRole = val!),
                  decoration: _inputStyle("", Icons.admin_panel_settings_outlined),
                ),
                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1C24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey)),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF00BCD4)),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 1)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}