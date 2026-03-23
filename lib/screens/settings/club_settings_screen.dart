import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/core/storage/user_storage.dart';
import 'package:magical_community/data/models/login_response.dart';

class ClubSettingsScreen extends StatefulWidget {
  const ClubSettingsScreen({super.key});

  @override
  State<ClubSettingsScreen> createState() => _ClubSettingsScreenState();
}

class _ClubSettingsScreenState extends State<ClubSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clubNameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _clubAddressController = TextEditingController();

  Club? _currentClub;
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final club = await UserStorage.getClub();
      final user = await UserStorage.getUser();

      if (club != null && user != null) {
        setState(() {
          _currentClub = club;
          _currentUser = user;
          _clubNameController.text = club.name;
          _adminNameController.text = user.fullName;
          _adminPhoneController.text = user.phoneNumber;
          _clubAddressController.text = club.location;
          _isLoading = false;
        });
      } else {
        // Fallback to default values if no club/user data
        setState(() {
          _clubNameController.text = 'Magical Community';
          _adminNameController.text = 'Admin User';
          _adminPhoneController.text = '+91 98765 43210';
          _clubAddressController.text = '123 Fitness Street, Wellness City';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading club settings: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _clubNameController.dispose();
    _adminNameController.dispose();
    _adminPhoneController.dispose();
    _clubAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          title: const Text('Club Information'),
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
        title: const Text('Club Information'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _saveSettings, icon: const Icon(Icons.save)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentYellow.withOpacity(0.1),
                        AppTheme.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 40,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Club Information',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage your club details and administrator information',
                        style: TextStyle(
                          color: AppTheme.darkGrey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Club Information Section
              _buildSection(
                title: 'Club Details',
                icon: Icons.store,
                color: AppTheme.accentYellow,
                children: [
                  _buildTextFormField(
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
                  _buildTextFormField(
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
              ),

              const SizedBox(height: 24),

              // Administrator Section
              _buildSection(
                title: 'Administrator Details',
                icon: Icons.admin_panel_settings,
                color: AppTheme.softGreen,
                children: [
                  _buildTextFormField(
                    controller: _adminNameController,
                    label: 'Administrator Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter administrator name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _adminPhoneController,
                    label: 'Administrator Phone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveSettings,
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
                      const Text(
                        'Save Changes',
                        style: TextStyle(
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

  Widget _buildTextFormField({
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

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Update club information if available
        if (_currentClub != null) {
          final updatedClub = Club(
            id: _currentClub!.id,
            name: _clubNameController.text,
            code: _currentClub!.code,
            location: _clubAddressController.text,
            phoneNumber: _currentClub!.phoneNumber,
            email: _currentClub!.email,
            isActive: _currentClub!.isActive,
          );

          await UserStorage.saveClub(updatedClub);

          setState(() {
            _currentClub = updatedClub;
          });
        }

        // Update user information if available
        if (_currentUser != null) {
          final updatedUser = User(
            id: _currentUser!.id,
            firstName: _adminNameController.text.split(' ').first,
            lastName: _adminNameController.text.split(' ').length > 1
                ? _adminNameController.text.split(' ').skip(1).join(' ')
                : '',
            email: _currentUser!.email,
            phoneNumber: _adminPhoneController.text,
            role: _currentUser!.role,
            memberRole: _currentUser!.memberRole,
            isActive: _currentUser!.isActive,
            createdAt: _currentUser!.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );

          await UserStorage.saveUser(updatedUser);

          setState(() {
            _currentUser = updatedUser;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Club information updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving club settings: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
