import 'package:flutter/material.dart';
import 'dart:async';
import 'package:magical_community/core/network/api_result.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/data/services/user_service.dart';
import 'package:magical_community/models/user_model.dart';

class EditUserDetailsScreen extends StatefulWidget {
  final UserModel user;

  const EditUserDetailsScreen({super.key, required this.user});

  @override
  State<EditUserDetailsScreen> createState() => _EditUserDetailsScreenState();
}

class _EditUserDetailsScreenState extends State<EditUserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _diseaseController;
  bool _isSaving = false;

  // Referral editing state
  final TextEditingController _referralController = TextEditingController();
  String? _selectedReferralId; // chosen referral user id
  List<Map<String, dynamic>> _referralSuggestions = [];
  bool _isSearchingReferral = false;
  Timer? _referralDebounce;
  String _lastReferralQuery = '';
  bool _isProgrammaticSet = false; // guard suppressing clearing selection
  String? _originalReferralNameNorm; // Normalized original referral name

  // Subscription adjustments
  DateTime? _subscriptionStartDate; // chosen new start date
  DateTime? _visitStartDate; // chosen new visit start date for visitors

  @override
  void initState() {
    super.initState();
    String initialFirst = widget.user.firstName ?? '';
    String initialLast = widget.user.lastName ?? '';
    if (initialFirst.isEmpty && widget.user.name.trim().isNotEmpty) {
      final parts = widget.user.name.trim().split(' ');
      initialFirst = parts.isNotEmpty ? parts.first : '';
      initialLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    _firstNameController = TextEditingController(text: initialFirst);
    _lastNameController = TextEditingController(text: initialLast);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _phoneController = TextEditingController(text: widget.user.mobileNumber);
    _addressController = TextEditingController(text: widget.user.address);
    _diseaseController = TextEditingController(text: widget.user.disease ?? '');

    // Prefill referral display if available
    if (widget.user.referredByName != null &&
        widget.user.referredByName!.trim().isNotEmpty) {
      _isProgrammaticSet = true;
      _referralController.text = widget.user.referredByName!;
      _selectedReferralId = widget.user.referredById;
      _originalReferralNameNorm = _normalizeName(widget.user.referredByName);
      // ignore: avoid_print
      print(
        'DEBUG: Initialized referral - Name: "${widget.user.referredByName}", ID: "${widget.user.referredById}"',
      );
    } else {
      // ignore: avoid_print
      print('DEBUG: No existing referral found');
    }
    _originalReferralNameNorm = _normalizeName(widget.user.referredByName);
    _referralController.addListener(_onReferralChanged);
    _subscriptionStartDate = widget.user.membershipStartDate;
    if (widget.user.userType == UserType.visitor) {
      _visitStartDate = widget.user.membershipStartDate;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _diseaseController.dispose();
    _referralController.removeListener(_onReferralChanged);
    _referralController.dispose();
    _referralDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Details'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildFirstName(),
                const SizedBox(height: 16),
                _buildLastName(),
                const SizedBox(height: 16),
                _buildEmail(),
                const SizedBox(height: 16),
                _buildPhone(),
                const SizedBox(height: 16),
                _buildAddress(),
                const SizedBox(height: 16),
                _buildDisease(),
                const SizedBox(height: 24),
                _buildReferralSection(),
                const SizedBox(height: 24),
                if (widget.user.userType != UserType.visitor)
                  _buildSubscriptionAdjustmentSection(),
                if (widget.user.userType == UserType.visitor)
                  _buildVisitDateAdjustmentSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: AppTheme.primaryBlack,
            ),
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBlack,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Saving...'),
                    ],
                  )
                : const Text('Save Changes'),
          ),
        ),
      ),
    );
  }

  Widget _buildFirstName() => TextFormField(
    controller: _firstNameController,
    decoration: const InputDecoration(
      labelText: 'First Name',
      prefixIcon: Icon(Icons.badge),
      border: OutlineInputBorder(),
    ),
    textCapitalization: TextCapitalization.words,
    validator: (v) =>
        v == null || v.trim().isEmpty ? 'First name is required' : null,
  );

  Widget _buildLastName() => TextFormField(
    controller: _lastNameController,
    decoration: const InputDecoration(
      labelText: 'Last Name',
      prefixIcon: Icon(Icons.badge_outlined),
      border: OutlineInputBorder(),
    ),
    textCapitalization: TextCapitalization.words,
  );

  Widget _buildEmail() => TextFormField(
    controller: _emailController,
    decoration: const InputDecoration(
      labelText: 'Email',
      prefixIcon: Icon(Icons.email),
      border: OutlineInputBorder(),
    ),
    keyboardType: TextInputType.emailAddress,
  );

  Widget _buildPhone() => TextFormField(
    controller: _phoneController,
    decoration: const InputDecoration(
      labelText: 'Mobile Number',
      prefixIcon: Icon(Icons.phone),
      border: OutlineInputBorder(),
    ),
    keyboardType: TextInputType.phone,
    validator: (v) =>
        v == null || v.trim().isEmpty ? 'Mobile number is required' : null,
  );

  Widget _buildAddress() => TextFormField(
    controller: _addressController,
    decoration: const InputDecoration(
      labelText: 'Address',
      prefixIcon: Icon(Icons.location_on),
      border: OutlineInputBorder(),
    ),
    maxLines: 2,
    textCapitalization: TextCapitalization.words,
  );

  Widget _buildDisease() => TextFormField(
    controller: _diseaseController,
    decoration: const InputDecoration(
      labelText: 'Disease (Optional)',
      prefixIcon: Icon(Icons.healing),
      border: OutlineInputBorder(),
    ),
    textCapitalization: TextCapitalization.sentences,
  );

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine which referral ID to use
    final referralText = _referralController.text.trim();
    final originalReferralName = widget.user.referredByName?.trim() ?? '';
    String? referralIdToUse;

    print(
      'DEBUG: Save - referralText: "$referralText", originalName: "$originalReferralName"',
    );
    print(
      'DEBUG: Save - _selectedReferralId: "$_selectedReferralId", originalId: "${widget.user.referredById}"',
    );

    if (referralText == originalReferralName &&
        widget.user.referredById != null &&
        widget.user.referredById!.isNotEmpty) {
      // User kept original referral - always use original ID
      referralIdToUse = widget.user.referredById;
      print('DEBUG: Using original referral ID: "$referralIdToUse"');
    } else if (_selectedReferralId != null && _selectedReferralId!.isNotEmpty) {
      // User selected new referral - use new ID
      referralIdToUse = _selectedReferralId;
      print('DEBUG: Using selected referral ID: "$referralIdToUse"');
    } else {
      print('DEBUG: No valid referral ID found!');
      // This shouldn't happen due to validation, but just in case
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a referral'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final service = UserService();

    try {
      final result = await service.updateUserDetails(
        userId: widget.user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        disease: _diseaseController.text.trim().isEmpty
            ? null
            : _diseaseController.text.trim(),
        referralId: referralIdToUse,
        referralName: _referralController.text.trim().isEmpty
            ? null
            : _referralController.text.trim(),
        startDate: widget.user.userType == UserType.visitor
            ? _visitStartDate
            : _subscriptionStartDate,
        subscriptionPlanId: widget.user.activeMembership?.subscriptionPlanId,
        membershipId: widget.user.membershipId,
      );

      if (!mounted) return;

      // Debug: Check the actual type of result
      print('DEBUG: result type: ${result.runtimeType}');
      print(
        'DEBUG: result is ApiSuccess<UserModel>: ${result is ApiSuccess<UserModel>}',
      );
      print(
        'DEBUG: result is ApiFailure<UserModel>: ${result is ApiFailure<UserModel>}',
      );

      if (result is ApiSuccess<UserModel>) {
        print('DEBUG: result.data type: ${result.data.runtimeType}');
        Navigator.pop(context, {
          'detailsUpdated': true,
          'updatedUser': result.data,
        });
      } else if (result is ApiFailure<UserModel>) {
        final msg = result.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.errorRed),
        );
        setState(() => _isSaving = false);
      } else {
        // Handle unexpected result type
        print('DEBUG: Unexpected result type: ${result.runtimeType}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected result type: ${result.runtimeType}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (!mounted) return;
      // Show raw error string (no static prefix) to reflect server or exception message directly
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isEmpty ? 'Error' : msg),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  // Plan loading removed.

  Widget _buildSubscriptionAdjustmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subscription Adjustment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final initial = _subscriptionStartDate ?? DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(2020, 1, 1),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _subscriptionStartDate = picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Start Date',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _subscriptionStartDate == null
                  ? 'Select start date'
                  : '${_subscriptionStartDate!.year}-${_subscriptionStartDate!.month.toString().padLeft(2, '0')}-${_subscriptionStartDate!.day.toString().padLeft(2, '0')}',
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Adjust the active subscription start date. Leave blank to keep unchanged.',
          style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
        ),
      ],
    );
  }

  Widget _buildVisitDateAdjustmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visit Date Adjustment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final initial = _visitStartDate ?? DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(2020, 1, 1),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _visitStartDate = picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Visit Start Date',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _visitStartDate == null
                  ? 'Select visit start date'
                  : '${_visitStartDate!.year}-${_visitStartDate!.month.toString().padLeft(2, '0')}-${_visitStartDate!.day.toString().padLeft(2, '0')}',
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Adjust the visit start date. Leave blank to keep unchanged.',
          style: TextStyle(fontSize: 12, color: AppTheme.darkGrey),
        ),
      ],
    );
  }

  // (Removed unused _buildSubscriptionDateOnlySection helper)

  // Referral editing UI
  Widget _buildReferralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Referral',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _referralController,
          decoration: InputDecoration(
            labelText: 'Search referral by name',
            prefixIcon: const Icon(Icons.people_outline),
            suffixIcon: _referralController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _referralController.clear();
                        _selectedReferralId = null;
                        _referralSuggestions.clear();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) {
            final text = v?.trim() ?? '';
            print('DEBUG: Validator - text: "$text"');
            print(
              'DEBUG: Validator - _selectedReferralId: "$_selectedReferralId"',
            );
            print(
              'DEBUG: Validator - widget.user.referredByName: "${widget.user.referredByName}"',
            );
            print(
              'DEBUG: Validator - widget.user.referredById: "${widget.user.referredById}"',
            );

            if (text.isEmpty) {
              print('DEBUG: Validator - FAIL: text is empty');
              return 'Referral is required';
            }

            // If text matches original referral, always allow it (regardless of _selectedReferralId state)
            final normText = _normalizeName(text);
            if (normText == _originalReferralNameNorm &&
                widget.user.referredById != null &&
                widget.user.referredById!.isNotEmpty) {
              print('DEBUG: Validator - PASS: using original referral');
              return null; // Valid - using original referral
            }

            // For new/changed referrals, require selection from list
            if (_selectedReferralId == null || _selectedReferralId!.isEmpty) {
              print('DEBUG: Validator - FAIL: no selected referral ID');
              return 'Please select a referral from the list';
            }
            print('DEBUG: Validator - PASS: using selected referral');
            return null;
          },
          onFieldSubmitted: (_) => _triggerReferralSearchImmediate(),
        ),
        const SizedBox(height: 8),
        if (_isSearchingReferral)
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_referralSuggestions.isNotEmpty &&
            _referralController.text.trim().length >= 3)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height:
                  160, // Slightly increased from 120 to improve visibility in edit screen
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                itemCount: _referralSuggestions.length,
                itemBuilder: (context, index) {
                  final item = _referralSuggestions[index];
                  final first = (item['firstName'] ?? '').toString();
                  final last = (item['lastName'] ?? '').toString();
                  final display = (first + ' ' + last).trim();
                  final roleRaw = (item['memberRole'] ?? '').toString().trim();
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
                      // Fallback: capitalize first letter
                      roleDisplay =
                          roleRaw[0].toUpperCase() + roleRaw.substring(1);
                    }
                  }
                  return ListTile(
                    dense: true,
                    title: Text(
                      display.isEmpty ? 'Unnamed User' : display,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: roleDisplay == null ? null : Text(roleDisplay),
                    onTap: () {
                      setState(() {
                        _isProgrammaticSet = true;
                        _referralController.text = display;
                        // Keep ID extraction consistent with AddUserScreen
                        _selectedReferralId =
                            (item['id'] ?? item['_id'] ?? item['userId'] ?? '')
                                .toString();
                        _referralSuggestions.clear();
                      });
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  void _onReferralChanged() {
    final query = _referralController.text.trim();
    if (_isProgrammaticSet) {
      _isProgrammaticSet = false;
      _lastReferralQuery = query;
      return;
    }

    // Only clear the selected ID if user is actually changing the referral text
    final normQuery = _normalizeName(query);
    if (normQuery != _originalReferralNameNorm) {
      // User is typing something different from original - clear the ID so they must select from list
      if (_selectedReferralId != null) {
        setState(() => _selectedReferralId = null);
      }
    } else {
      // User typed back to original referral name - restore original ID
      if (widget.user.referredById != null &&
          widget.user.referredById!.isNotEmpty) {
        setState(() => _selectedReferralId = widget.user.referredById);
      }
    }

    _lastReferralQuery = query;
    _referralDebounce?.cancel();
    if (query.length < 3) {
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

  // Normalize names for comparison: lowercase, collapse whitespace
  String? _normalizeName(String? raw) {
    if (raw == null) return null;
    final norm = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    return norm.isEmpty ? null : norm;
  }

  void _triggerReferralSearchImmediate() {
    final query = _referralController.text.trim();
    if (query.length >= 3) {
      _referralDebounce?.cancel();
      _searchReferral(query);
    }
  }

  Future<void> _searchReferral(String query) async {
    setState(() => _isSearchingReferral = true);
    try {
      final result = await UserService().searchReferralCandidates(
        search: query,
      );
      if (!mounted) return;
      if (query != _lastReferralQuery) return; // stale
      result.when(
        success: (list) {
          setState(() {
            _referralSuggestions = list;
            _isSearchingReferral = false;
          });
        },
        failure: (message, status) {
          setState(() {
            _referralSuggestions = [];
            _isSearchingReferral = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Referral search error: $message'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearchingReferral = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referral search failed: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}
