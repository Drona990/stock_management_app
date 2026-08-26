import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../pages/bar&resturant/user_management_page.dart';

class EditUserDialog extends StatefulWidget {
  final dynamic user;
  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandRed = Color(0xFFD32027);
  static const Color darkSlate = Color(0xFF0B0E14);

  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late TextEditingController _ageController;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _ageController = TextEditingController(
      text: (widget.user['meta_specs']?['age'] ?? '25').toString(),
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _saving = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<UserMgmtBloc>();

    try {
      final Map<String, dynamic> updateData = {
        "name": _nameController.text.trim(),
        "age": int.tryParse(_ageController.text) ?? 25,
      };
      if (_passwordController.text.isNotEmpty) {
        updateData["password"] = _passwordController.text;
      }

      await sl<ApiClient>().put(
        '/api/user/${widget.user['user_id']}/update/',
        data: updateData,
      );

      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text("✅ Staff profile specifications updated successfully!"),
          backgroundColor: Color(0xFF0D9488),
        ),
      );
      bloc.add(LoadUsers());
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("❌ Modification Fault: $e"),
          backgroundColor: brandRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 3.5, height: 16, color: brandBlue),
                const SizedBox(width: 8),
                const Text(
                  "Edit Staff Specifications",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: darkSlate,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Updating identity parameters for: ${widget.user['username'] ?? 'User'}",
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
              decoration: _inputStyle("STAFF FULL NAME", Icons.badge_outlined),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _ageController,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
              decoration: _inputStyle("AGE PARAMETER", Icons.calendar_month_outlined),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
              decoration: _inputStyle(
                "RESET ACCESS PASSWORD (OPTIONAL)",
                Icons.lock_reset_outlined,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: _saving
                      ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                  )
                      : const Text(
                    "SAVE CHANGES",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon, {Widget? suffix}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 9.5, color: Colors.blueGrey, fontWeight: FontWeight.bold),
    prefixIcon: Icon(icon, size: 15, color: brandBlue),
    suffixIcon: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: brandBlue, width: 1.5),
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
  );
}