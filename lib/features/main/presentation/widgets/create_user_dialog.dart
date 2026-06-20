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
  late TextEditingController _nameController, _passwordController, _ageController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _ageController = TextEditingController(text: (widget.user['meta_specs']?['age'] ?? '25').toString());
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

    // Async gaps se pehle local reference capture karna crash proof banata hai
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<UserMgmtBloc>();

    try {
      final Map<String, dynamic> updateData = {
        "name": _nameController.text.trim(),
        "age": int.tryParse(_ageController.text) ?? 25
      };
      if (_passwordController.text.isNotEmpty) {
        updateData["password"] = _passwordController.text;
      }

      await sl<ApiClient>().put('/api/user/${widget.user['user_id']}/update/', data: updateData);

      navigator.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text("✅ Profile Registries Synced Successfully!"), backgroundColor: Colors.green)
      );
      bloc.add(LoadUsers());

    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text("❌ Modification Fault: $e"), backgroundColor: Colors.red)
      );

    } finally { // ✅ FIXED: Ab 'finally' block block-level states ko background me safely toggle karega
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Modify Scope Specifications", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            TextField(controller: _nameController, style: const TextStyle(fontSize: 11), decoration: _inputStyle("COMPILED FULL NAME", Icons.person_outline)),
            const SizedBox(height: 12),
            TextField(controller: _ageController, style: const TextStyle(fontSize: 11), decoration: _inputStyle("AGE PARAMETER", Icons.calendar_month_outlined)),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, style: const TextStyle(fontSize: 11), obscureText: true, decoration: _inputStyle("OVERRIDE PASSWORD REGISTER", Icons.lock_reset)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(fontSize: 11))),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                  child: _saving ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white)) : const Text("COMMIT REGISTRY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String h, IconData i) => InputDecoration(
    labelText: h,
    labelStyle: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
    prefixIcon: Icon(i, size: 14, color: const Color(0xFF00BCD4)),
    border: const OutlineInputBorder(),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
  );
}