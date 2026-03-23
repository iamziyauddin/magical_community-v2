import 'package:flutter/material.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'package:magical_community/core/storage/user_storage.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/data/models/login_response.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profile controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Club controllers
  final _clubNameController = TextEditingController();
  final _clubAddressController = TextEditingController();

  // Loaded objects are written back to storage on save; UI uses controllers
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await UserStorage.getUser();
      final club = await UserStorage.getClub();

      setState(() {
        _firstNameController.text = user?.firstName ?? '';
        _lastNameController.text = user?.lastName ?? '';
        _emailController.text = user?.email ?? '';
        _phoneController.text = user?.phoneNumber ?? '';
        _clubNameController.text = club?.name ?? '';
        _clubAddressController.text = club?.location ?? '';
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _clubNameController.dispose();
    _clubAddressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'club': {
        'name': _clubNameController.text.trim(),
        'location': _clubAddressController.text.trim(),
      },
    };

    await ApiService.executeWithLoading(
      () async {
        final res = await ApiService.put<Map<String, dynamic>>(
          '/auth/profile',
          data: payload,
          context: context,
          showSuccessMessage: true,
        );

        if (res is Map<String, dynamic>) {
          final data = res['data'];
          if (data is Map<String, dynamic>) {
            final userJson = (data['user'] ?? {}) as Map<String, dynamic>;
            final clubJson = (data['club'] ?? {}) as Map<String, dynamic>;

            final updatedUser = User.fromJson(userJson);
            final updatedClub = Club.fromJson(clubJson);

            await UserStorage.saveUser(updatedUser);
            await UserStorage.saveClub(updatedClub);

            // Controllers already hold the latest values; no stateful user/club needed
          }
        }
        return res;
      },
      context: context,
      setLoading: (v) => setState(() => _saving = v),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          title: const Text('Account Settings'),
          backgroundColor: AppTheme.primaryBlack,
          foregroundColor: AppTheme.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     onPressed: _saving ? null : _save,
        //     icon: _saving
        //         ? const SizedBox(
        //             width: 20,
        //             height: 20,
        //             child: CircularProgressIndicator(strokeWidth: 2),
        //           )
        //         : const Icon(Icons.save),
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildClubSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save),
                      const SizedBox(width: 8),
                      Text(
                        _saving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppTheme.accentYellow.withOpacity(0.1), AppTheme.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: const [
            Icon(Icons.manage_accounts, size: 40, color: AppTheme.primaryBlack),
            SizedBox(height: 16),
            Text(
              'Profile & Club Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlack,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage your personal details and club information in one place',
              style: TextStyle(color: AppTheme.darkGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16, color: AppTheme.primaryBlack),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.darkGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.white,
        labelStyle: TextStyle(color: AppTheme.darkGrey.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      color: AppTheme.accentYellow,
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: 'First Name',
          icon: Icons.badge,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter your first name'
              : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameController,
          label: 'Last Name',
          icon: Icons.badge_outlined,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please enter your last name'
              : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your email';
            if (!value.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (value.length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildClubSection() {
    return _buildSection(
      title: 'Club Details',
      icon: Icons.store,
      color: AppTheme.softGreen,
      children: [
        _buildTextField(
          controller: _clubNameController,
          label: 'Club Name',
          icon: Icons.business,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter club name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _clubAddressController,
          label: 'Club Address',
          icon: Icons.location_on,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter club address';
            }
            return null;
          },
        ),
      ],
    );
  }
}
