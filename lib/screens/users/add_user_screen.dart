import 'dart:async';
import 'package:flutter/material.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/data/services/user_service.dart';
import 'package:magical_community/data/models/subscription_plan.dart';
import 'package:magical_community/data/models/add_user_request.dart';
import 'package:magical_community/models/user_model.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _diseaseController = TextEditingController();
  final _amountController = TextEditingController();
  final _referralNameController = TextEditingController();

  final UserService _userService = UserService();

  List<SubscriptionPlan> _subscriptionPlans = [];
  bool _isLoadingPlans = true;
  bool _isSubmitting = false;
  bool _isSearchingReferral = false;
  List<Map<String, dynamic>> _referralSuggestions = [];
  Timer? _referralDebounce;
  String _lastReferralQuery = '';
  String? _selectedReferralUserId;
  bool _isSelectingReferral =
      false; // guard to avoid clearing selection during programmatic set

  SubscriptionPlan? _selectedPlan;
  DateTime _visitDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
    _referralNameController.addListener(_onReferralTextChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _diseaseController.dispose();
    _amountController.dispose();
    _referralNameController.dispose();
    _referralDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSubscriptionPlans() async {
    try {
      final result = await _userService.getSubscriptionPlans();
      result.when(
        success: (plans) {
          setState(() {
            _subscriptionPlans = plans;
            _isLoadingPlans = false;
          });
        },
        failure: (message, statusCode) {
          setState(() => _isLoadingPlans = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading subscription plans: $message'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        },
      );
    } catch (e) {
      setState(() => _isLoadingPlans = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading subscription plans: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        title: const Text('Add New User'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _firstNameController,
                label: 'First Name*',
                icon: Icons.person,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name*',
                icon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  // Optional: only validate format if provided
                  if (value == null || value.isEmpty) return null;
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number*',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (value.length != 10) {
                    return 'Please enter valid 10-digit mobile number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                label: 'Address*',
                icon: Icons.home,
                maxLines: 3,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _diseaseController,
                label: 'disease',
                icon: Icons.health_and_safety,
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
                validator: null,
              ),

              const SizedBox(height: 24),

              // Referral Section (now mandatory)
              _buildSectionHeader('Referral*', Icons.people),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _referralNameController,
                        decoration: InputDecoration(
                          labelText: 'Referral (search users)',
                          hintText: 'Type at least 3 characters to search',
                          prefixIcon: const Icon(
                            Icons.person,
                            color: AppTheme.accentYellow,
                          ),
                          suffixIcon:
                              (_selectedReferralUserId != null ||
                                  _referralNameController.text.isNotEmpty)
                              ? IconButton(
                                  tooltip: 'Clear selection',
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: AppTheme.darkGrey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _referralNameController.clear();
                                      _selectedReferralUserId = null;
                                      _referralSuggestions = [];
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.accentYellow,
                              width: 2,
                            ),
                          ),
                        ),
                        // Mandatory: must have text AND a selected referral user from suggestions
                        validator: (value) {
                          final txt = value?.trim() ?? '';
                          if (txt.isEmpty) {
                            return 'Referral is required';
                          }
                          if (_selectedReferralUserId == null ||
                              _selectedReferralUserId!.isEmpty) {
                            return 'Select a referral from the list';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_isSearchingReferral)
                        const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.accentYellow,
                              ),
                            ),
                          ),
                        )
                      else if (_referralSuggestions.isNotEmpty &&
                          _referralNameController.text.trim().length >= 3)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SizedBox(
                            // Fix height to a reasonable extent and make list scrollable
                            height: 240,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              physics: const ClampingScrollPhysics(),
                              itemCount: _referralSuggestions.length,
                              itemBuilder: (context, index) {
                                final item = _referralSuggestions[index];
                                final first = (item['firstName'] ?? '')
                                    .toString()
                                    .trim();
                                final last = (item['lastName'] ?? '')
                                    .toString()
                                    .trim();
                                final fullName = (first + ' ' + last).trim();
                                final roleRaw = (item['memberRole'] ?? '')
                                    .toString()
                                    .trim();
                                String? roleDisplay;
                                if (roleRaw.isNotEmpty) {
                                  final lowered = roleRaw.toLowerCase();
                                  if (lowered == 'member') {
                                    roleDisplay = 'UMS';
                                  } else if (lowered == 'coach') {
                                    roleDisplay = 'Coach';
                                  } else if (lowered == 'seniorcoach' ||
                                      lowered == 'senior_coach') {
                                    roleDisplay = 'Senior Coach';
                                  } else {
                                    roleDisplay =
                                        roleRaw[0].toUpperCase() +
                                        roleRaw.substring(1);
                                  }
                                }
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    fullName.isEmpty
                                        ? 'Unknown Name'
                                        : fullName,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: roleDisplay == null
                                      ? null
                                      : Text(roleDisplay),
                                  onTap: () {
                                    setState(() {
                                      _isSelectingReferral = true;
                                      _referralNameController.text = fullName;
                                      _selectedReferralUserId =
                                          (item['id'] ??
                                                  item['_id'] ??
                                                  item['userId'] ??
                                                  '')
                                              .toString();
                                      _referralSuggestions = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Subscription Plans Section
              Row(
                children: [
                  Expanded(
                    child: _buildSectionHeader(
                      'Subscription Plans',
                      Icons.card_membership,
                    ),
                  ),
                  if (_selectedPlan != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedPlan = null;
                          _amountController.clear();
                        });
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear Selection'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoadingPlans)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentYellow,
                    ),
                  ),
                )
              else
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_subscriptionPlans.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No subscription plans available',
                              style: TextStyle(
                                color: AppTheme.darkGrey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        else ...[
                          // "None" option
                          // Container(
                          //   decoration: BoxDecoration(
                          //     borderRadius: BorderRadius.circular(12),
                          //     border: Border.all(
                          //       color: _selectedPlan == null
                          //           ? AppTheme.accentYellow
                          //           : AppTheme.darkGrey.withOpacity(0.3),
                          //       width: _selectedPlan == null ? 2 : 1,
                          //     ),
                          //     color: _selectedPlan == null
                          //         ? AppTheme.accentYellow.withOpacity(0.1)
                          //         : null,
                          //   ),
                          //   child: RadioListTile<SubscriptionPlan?>(
                          //     title: Row(
                          //       children: [
                          //         Icon(
                          //           Icons.do_not_disturb,
                          //           color: AppTheme.darkGrey.withOpacity(0.7),
                          //         ),
                          //         const SizedBox(width: 8),
                          //         const Expanded(
                          //           child: Column(
                          //             crossAxisAlignment:
                          //                 CrossAxisAlignment.start,
                          //             children: [
                          //               Text(
                          //                 'Visitor only',
                          //                 style: TextStyle(
                          //                   fontWeight: FontWeight.bold,
                          //                   fontSize: 16,
                          //                 ),
                          //               ),
                          //               Text(
                          //                 'Register user without any subscription plan',
                          //                 style: TextStyle(
                          //                   color: AppTheme.darkGrey,
                          //                   fontSize: 12,
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //         ),
                          //         const Text(
                          //           'Free',
                          //           style: TextStyle(
                          //             fontWeight: FontWeight.bold,
                          //             fontSize: 16,
                          //             color: AppTheme.darkGrey,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //     value: null,
                          //     groupValue: _selectedPlan,
                          //     activeColor: AppTheme.accentYellow,
                          //     onChanged: (value) {
                          //       setState(() {
                          //         _selectedPlan = null;
                          //         _amountController.clear();
                          //       });
                          //     },
                          //   ),
                          // ),
                          const SizedBox(height: 12),

                          // Subscription plans
                          ..._subscriptionPlans.asMap().entries.map((entry) {
                            final index = entry.key;
                            final plan = entry.value;
                            final isSelected = _selectedPlan?.id == plan.id;

                            return Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.successGreen
                                          : AppTheme.darkGrey.withOpacity(0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    color: isSelected
                                        ? AppTheme.successGreen.withOpacity(0.1)
                                        : null,
                                  ),
                                  child: RadioListTile<SubscriptionPlan>(
                                    title: Row(
                                      children: [
                                        const Icon(
                                          Icons.workspace_premium,
                                          color: AppTheme.successGreen,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                plan.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                plan.description,
                                                style: const TextStyle(
                                                  color: AppTheme.darkGrey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              plan.displayPrice,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppTheme.successGreen,
                                              ),
                                            ),
                                            Text(
                                              plan.displayDuration,
                                              style: const TextStyle(
                                                color: AppTheme.darkGrey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    value: plan,
                                    groupValue: _selectedPlan,
                                    activeColor: AppTheme.successGreen,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPlan = value;
                                        // Default to zero payment on selecting a plan
                                        _amountController.text = '0';
                                      });
                                    },
                                  ),
                                ),
                                if (index < _subscriptionPlans.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Visit Date Picker (default: today)
              _buildSectionHeader('Visit Date', Icons.event),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.accentYellow,
                  ),
                  title: Text(
                    '${_visitDate.year.toString().padLeft(4, '0')}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}',
                  ),
                  subtitle: const Text('Tap to change visit date'),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _visitDate,
                      firstDate: DateTime(2020, 1, 1),
                      lastDate: DateTime(2100, 12, 31),
                    );
                    if (picked != null) {
                      setState(() => _visitDate = picked);
                    }
                  },
                ),
              ),

              // Amount section for selected plan
              if (_selectedPlan != null) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('Payment Amount', Icons.currency_rupee),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _amountController,
                  label: 'Amount to Pay',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    // Allow zero amount; treat empty as 0 (handled in save)
                    if (value == null || value.isEmpty) return null;
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 0) {
                      return 'Amount cannot be negative';
                    }
                    if (_selectedPlan != null &&
                        amount > _selectedPlan!.price) {
                      return 'Amount cannot exceed ${_selectedPlan!.displayPrice}';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: AppTheme.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlack,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Registering User...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // const Icon(Icons.person_add),
                            const SizedBox(width: 8),
                            Text(
                              'Submit',
                              // _selectedPlan != null
                              //     ? 'Register User with ${_selectedPlan!.name}'
                              //     : 'Register User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentYellow),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.accentYellow),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentYellow, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      textCapitalization: textCapitalization,
      validator: validator,
    );
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final referralNameText = _referralNameController.text.trim();
      final request = AddUserRequest(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phoneNumber: _mobileController.text,
        address: _addressController.text,
        disease: _diseaseController.text.isEmpty
            ? 'none'
            : _diseaseController.text,
        referralName: referralNameText.isEmpty ? null : referralNameText,
        referralId:
            (_selectedReferralUserId != null &&
                _selectedReferralUserId!.isNotEmpty)
            ? _selectedReferralUserId
            : null,
        subscriptionPlanId: _selectedPlan?.id,
        amount: amount,
        visitDate: _visitDate,
      );

      final result = await _userService.addUser(request);

      result.when(
        success: (response) {
          _showSuccessDialog(firstName, lastName, response);
        },
        failure: (message, statusCode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $message'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _onReferralTextChanged() {
    // Always search when typing in referral box
    final query = _referralNameController.text.trim();
    if (_isSelectingReferral) {
      // Ignore the change triggered by selecting a suggestion
      _isSelectingReferral = false;
      _lastReferralQuery = query;
      return;
    }
    // If user edits the field after selecting, clear the selected referral id
    if (_selectedReferralUserId != null) {
      setState(() {
        _selectedReferralUserId = null;
      });
    }
    _lastReferralQuery = query;
    _referralDebounce?.cancel();
    if (query.length < 3) {
      // Clear suggestions when input too short
      if (_referralSuggestions.isNotEmpty || _isSearchingReferral) {
        setState(() {
          _referralSuggestions = [];
          _isSearchingReferral = false;
        });
      }
      return;
    }
    _referralDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchReferral(query);
    });
  }

  Future<void> _searchReferral(String query) async {
    setState(() => _isSearchingReferral = true);
    try {
      final result = await _userService.searchReferralCandidates(search: query);
      if (!mounted) return;
      // Ensure result is still for current query
      if (query != _lastReferralQuery) return;
      result.when(
        success: (list) {
          setState(() {
            _referralSuggestions = list;
            _isSearchingReferral = false;
          });
        },
        failure: (message, statusCode) {
          setState(() {
            _referralSuggestions = [];
            _isSearchingReferral = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Search error: $message'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearchingReferral = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  // Helper method to convert AddUserUser to UserModel for returning to lists
  UserModel _convertAddUserToUserModel(AddUserUser addUserUser) {
    // Convert the AddUserUser response to a Map that UserModel can parse
    final userJson = {
      'id': addUserUser.userId,
      'firstName': addUserUser.firstName,
      'lastName': addUserUser.lastName,
      'name': '${addUserUser.firstName} ${addUserUser.lastName}'.trim(),
      'email': addUserUser.email,
      'mobileNumber': addUserUser.phoneNumber,
      'address': addUserUser.address,
      'disease': addUserUser.disease,
      'userType': addUserUser.memberRole,
      'memberRole': addUserUser.memberRole,
      'isActive': addUserUser.isActive,
      'membershipStatus': addUserUser.membershipStatus,
      'membershipStartDate': addUserUser.membershipStartDate,
      'membershipEndDate': addUserUser.membershipEndDate,
      'totalPayable': addUserUser.totalPayable,
      'totalPaid': addUserUser.totalPaid,
      'dueAmount': addUserUser.dueAmount,
      'membershipType': addUserUser.membershipType,
      'attendanceSummary': addUserUser.attendanceSummary,
      'activeMembership': addUserUser.activeMembership,
      'referBy': addUserUser.referBy,
      if (addUserUser.referBy != null) ...{
        'referredByName':
            '${addUserUser.referBy!['firstName'] ?? ''} ${addUserUser.referBy!['lastName'] ?? ''}'
                .trim(),
        'referredById': addUserUser.referBy!['referralId'],
      },
    };

    return UserModel.fromMemberJson(userJson);
  }

  // Removed _designationFromMemberRole after simplifying referral suggestion list UI.

  void _showSuccessDialog(
    String firstName,
    String lastName,
    AddUserResponseData response,
  ) {
    final referralText = _referralNameController.text.trim();
    String referralInfo = referralText.isEmpty
        ? 'No referral'
        : 'Referred by: $referralText';

    String healthInfo = _diseaseController.text.isEmpty
        ? 'No health issues reported'
        : 'Health notes: ${_diseaseController.text}';

    // Convert AddUserUser to UserModel for returning to the list
    final newUser = _convertAddUserToUserModel(response.user);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$firstName $lastName has been registered successfully!'),
            const SizedBox(height: 8),
            Text(
              'Plan: ${_selectedPlan?.name ?? 'No plan'}',
              style: const TextStyle(fontSize: 12, color: AppTheme.darkGrey),
            ),
            const SizedBox(height: 4),
            Text(
              'Amount: ${_amountController.text.isNotEmpty ? '₹${_amountController.text}' : '₹0'}',
              style: const TextStyle(fontSize: 12, color: AppTheme.darkGrey),
            ),
            const SizedBox(height: 4),
            Text(
              '$referralInfo',
              style: const TextStyle(fontSize: 12, color: AppTheme.darkGrey),
            ),
            const SizedBox(height: 4),
            Text(
              healthInfo,
              style: const TextStyle(fontSize: 12, color: AppTheme.darkGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, {
                'userAdded': true,
                'newUser': newUser, // Return the new user for list refresh
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: AppTheme.primaryBlack,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
