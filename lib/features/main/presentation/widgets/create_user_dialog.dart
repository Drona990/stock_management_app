
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../pages/bar&resturant/user_management_page.dart';
import '../../../inventory/presentation/bloc/location_bloc.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  final storage = const FlutterSecureStorage();

  String _selectedRole = "staff";
  String _selectedGender = "M";
  int? _selectedLocationId;
  String _currentUserRole = "";
  bool _isLoading = false;
  bool _isPermissionLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    context.read<LocationBloc>().add(LoadLocations());

    _firstNameController.addListener(_updateFullName);
    _lastNameController.addListener(_updateFullName);
  }

  void _updateFullName() {
    setState(() {
      _nameController.text = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}".trim();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
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

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dobController.text = picked.toString().split(' ')[0]);
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a location")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String path = _selectedRole == 'admin' ? '/api/admin/create/' : '/api/staff/create/';

      await sl<ApiClient>().post(path, data: {
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        "name": _nameController.text.trim(),
        "phone_number": _phoneController.text.trim(),
        "dob": _dobController.text,
        "gender": _selectedGender,
        "role": _selectedRole,
        "location": _selectedLocationId,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created!"), backgroundColor: Colors.green));
        context.read<UserMgmtBloc>().add(LoadUsers());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionLoaded) return const Center(child: CircularProgressIndicator());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Create New User", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),

                // Access Level (Role) Dropdown
                _buildLabel("ACCESS LEVEL"),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: [
                    if (_currentUserRole == 'superuser')
                      const DropdownMenuItem(value: "admin", child: Text("Administrator / Manager")),
                    const DropdownMenuItem(value: "staff", child: Text("Staff")),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val!),
                  decoration: _inputStyle("", Icons.admin_panel_settings_outlined),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: _buildField("FIRST NAME", _firstNameController, "Drona", Icons.badge_outlined)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField("LAST NAME", _lastNameController, "Tandi", Icons.badge_outlined)),
                  ],
                ),
                const SizedBox(height: 16),

                _buildLabel("FULL NAME (AUTO)"),
                TextFormField(
                  controller: _nameController,
                  readOnly: true,
                  decoration: _inputStyle("", Icons.person_outline).copyWith(fillColor: Colors.grey[200]),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildField("PHONE NUMBER", _phoneController, "9876543210", Icons.phone_android_outlined)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("DATE OF BIRTH"),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: _selectDate,
                            decoration: _inputStyle("YYYY-MM-DD", Icons.calendar_today_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("GENDER"),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            items: const [
                              DropdownMenuItem(value: "M", child: Text("Male")),
                              DropdownMenuItem(value: "F", child: Text("Female")),
                              DropdownMenuItem(value: "O", child: Text("Other")),
                            ],
                            onChanged: (v) => setState(() => _selectedGender = v!),
                            decoration: _inputStyle("", Icons.transgender_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("LOCATION"),
                          BlocBuilder<LocationBloc, LocationState>(
                            builder: (context, state) {
                              return DropdownButtonFormField<int>(
                                value: _selectedLocationId,
                                items: state is LocationLoaded
                                    ? state.locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList()
                                    : [],
                                onChanged: (v) => setState(() => _selectedLocationId = v),
                                decoration: _inputStyle("Select", Icons.location_on_outlined),
                                validator: (v) => v == null ? "Required" : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildField("EMAIL", _emailController, "user@example.com", Icons.email_outlined, isEmail: true),
                const SizedBox(height: 16),
                _buildField("PASSWORD", _passwordController, "••••••••", Icons.lock_outline, isPassword: true),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitData,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1C24), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CREATE"),
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

  Widget _buildField(String label, TextEditingController controller, String hint, IconData icon, {bool isEmail = false, bool isPassword = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(label),
      TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: _inputStyle(hint, icon),
        validator: (v) {
          if (v!.isEmpty) return "Required";
          if (isEmail && !v.contains("@")) return "Invalid Email";
          return null;
        },
      ),
    ]);
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)));

  InputDecoration _inputStyle(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 18, color: const Color(0xFF00BCD4)),
    filled: true,
    fillColor: const Color(0xFFF8F9FA),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
  );
}