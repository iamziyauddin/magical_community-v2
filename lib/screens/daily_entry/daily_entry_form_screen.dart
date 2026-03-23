import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'package:magical_community/models/api_product_model.dart';
import 'daily_entry_model.dart';

/// Form screen for creating or editing a daily entry.
/// Pass [existingEntry] to pre-fill fields for editing.
class DailyEntryFormScreen extends StatefulWidget {
  final DailyEntryData? existingEntry;

  const DailyEntryFormScreen({super.key, this.existingEntry});

  bool get isEditing => existingEntry != null;

  @override
  State<DailyEntryFormScreen> createState() => _DailyEntryFormScreenState();
}

class _DailyEntryFormScreenState extends State<DailyEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Date
  late DateTime _selectedDate;

  // Controllers for numeric fields
  late final TextEditingController _visitEntryController;
  late final TextEditingController _trialsStartController;
  late final TextEditingController _trialShakesController;
  late final TextEditingController _newUmsController;
  late final TextEditingController _totalUmsController;
  late final TextEditingController _umsShakesController;
  late final TextEditingController _cashPaymentController;
  late final TextEditingController _upiPaymentController;
  late final TextEditingController _clubExpensesController;

  // FocusNodes for keyboard next-field navigation
  final _visitEntryFocus = FocusNode();
  final _trialsStartFocus = FocusNode();
  final _trialShakesFocus = FocusNode();
  final _umsShakesFocus = FocusNode();
  final _newUmsFocus = FocusNode();
  final _totalUmsFocus = FocusNode();
  final _cashPaymentFocus = FocusNode();
  final _upiPaymentFocus = FocusNode();
  final _clubExpensesFocus = FocusNode();

  // Dynamic product fields
  List<ApiProductModel> _apiProducts = [];
  bool _isLoadingProducts = true;
  final Map<String, TextEditingController> _productControllers = {};
  final Map<String, FocusNode> _productFocusNodes = {};

  // Auto-calculated values
  int _totalShakes = 0;
  double _totalPayment = 0;

  // Submission state
  bool _isSubmitting = false;

  // Club ID – TODO: inject via session/auth
  static const String _clubId = 'cmeqwbcij000312qwdm95ib54';

  String get _selectedDay => DateFormat('EEEE').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;

    _selectedDate = e?.date ?? DateTime.now();

    _visitEntryController =
        TextEditingController(text: e != null && e.visitEntry != 0 ? '${e.visitEntry}' : '');
    _trialsStartController =
        TextEditingController(text: e != null && e.trialsStart != 0 ? '${e.trialsStart}' : '');
    _trialShakesController =
        TextEditingController(text: e != null && e.trialShakes != 0 ? '${e.trialShakes}' : '');
    _newUmsController = TextEditingController(text: e != null && e.newUms != 0 ? '${e.newUms}' : '');
    _totalUmsController = TextEditingController(text: e != null && e.totalUms != 0 ? '${e.totalUms}' : '');
    _umsShakesController =
        TextEditingController(text: e != null && e.umsShakes != 0 ? '${e.umsShakes}' : '');
    _cashPaymentController = TextEditingController(
        text: e != null && e.cashPayment != 0 ? e.cashPayment.toStringAsFixed(0) : '');
    _upiPaymentController = TextEditingController(
        text: e != null && e.upiPayment != 0 ? e.upiPayment.toStringAsFixed(0) : '');
    _clubExpensesController = TextEditingController(
        text: e != null && e.clubExpenses != 0 ? e.clubExpenses.toStringAsFixed(0) : '');

    _trialShakesController.addListener(_calculateTotalShakes);
    _umsShakesController.addListener(_calculateTotalShakes);
    _cashPaymentController.addListener(_calculateTotalPayment);
    _upiPaymentController.addListener(_calculateTotalPayment);

    // Calculate initial totals
    _calculateTotalShakes();
    _calculateTotalPayment();

    // Fetch products from API
    _fetchProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _visitEntryController.dispose();
    _trialsStartController.dispose();
    _trialShakesController.dispose();
    _newUmsController.dispose();
    _totalUmsController.dispose();
    _umsShakesController.dispose();
    _cashPaymentController.dispose();
    _upiPaymentController.dispose();
    _clubExpensesController.dispose();
    // Dispose focus nodes
    _visitEntryFocus.dispose();
    _trialsStartFocus.dispose();
    _trialShakesFocus.dispose();
    _umsShakesFocus.dispose();
    _newUmsFocus.dispose();
    _totalUmsFocus.dispose();
    _cashPaymentFocus.dispose();
    _upiPaymentFocus.dispose();
    _clubExpensesFocus.dispose();
    // Dispose dynamic product controllers and focus nodes
    for (final c in _productControllers.values) {
      c.dispose();
    }
    for (final f in _productFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  // ─── API ────────────────────────────────────────────────────────

  Future<void> _fetchProducts() async {
    try {
      final response = await ApiService.get(
        '/products/?page=1&limit=20',
        context: context,
      );

      if (response != null && response['success'] == true) {
        final apiResponse = ApiProductsResponse.fromJson(response);
        final activeProducts = apiResponse.data.data
            .where((product) => product.isActive)
            .toList();

        // Sort alphabetically
        activeProducts.sort((a, b) => a.name.compareTo(b.name));

        setState(() {
          _apiProducts = activeProducts;
          _initProductControllers();
          _isLoadingProducts = false;
        });
      } else {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _initProductControllers() {
    final existingProducts = widget.existingEntry?.products ?? {};
    for (final product in _apiProducts) {
      final qty = existingProducts[product.name] ?? 0;
      _productControllers[product.id] =
          TextEditingController(text: qty != 0 ? '$qty' : '');
      _productFocusNodes[product.id] = FocusNode();
    }
  }

  // ─── Calculations ──────────────────────────────────────────────

  void _calculateTotalShakes() {
    final trial = int.tryParse(_trialShakesController.text) ?? 0;
    final ums = int.tryParse(_umsShakesController.text) ?? 0;
    setState(() {
      _totalShakes = trial + ums;
    });
  }

  void _calculateTotalPayment() {
    final cash = double.tryParse(_cashPaymentController.text) ?? 0;
    final upi = double.tryParse(_upiPaymentController.text) ?? 0;
    setState(() {
      _totalPayment = cash + upi;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.accentYellow,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.primaryBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ─── Build Entry Data ──────────────────────────────────────────

  Map<String, int> _buildProductsMap() {
    final Map<String, int> map = {};
    for (final product in _apiProducts) {
      final controller = _productControllers[product.id];
      if (controller != null) {
        final qty = int.tryParse(controller.text) ?? 0;
        map[product.name] = qty;
      }
    }
    return map;
  }

  DailyEntryData _buildEntryData() {
    return DailyEntryData(
      id: widget.existingEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      visitEntry: int.tryParse(_visitEntryController.text) ?? 0,
      trialsStart: int.tryParse(_trialsStartController.text) ?? 0,
      trialShakes: int.tryParse(_trialShakesController.text) ?? 0,
      umsShakes: int.tryParse(_umsShakesController.text) ?? 0,
      newUms: int.tryParse(_newUmsController.text) ?? 0,
      totalUms: int.tryParse(_totalUmsController.text) ?? 0,
      totalShakes: _totalShakes,
      cashPayment: double.tryParse(_cashPaymentController.text) ?? 0,
      upiPayment: double.tryParse(_upiPaymentController.text) ?? 0,
      clubExpenses: double.tryParse(_clubExpensesController.text) ?? 0,
      totalPayment: _totalPayment,
      products: _buildProductsMap(),
    );
  }

  /// Build API payload for POST request
  Map<String, dynamic> _buildApiPayload(DailyEntryData entry) {
    // Build products list with id & quantity (only non-zero)
    final List<Map<String, dynamic>> productsList = [];
    for (final product in _apiProducts) {
      final controller = _productControllers[product.id];
      if (controller != null) {
        final qty = int.tryParse(controller.text) ?? 0;
        if (qty > 0) {
          productsList.add({
            'id': product.id,
            'quantity': qty,
          });
        }
      }
    }

    return {
      'clubId': _clubId,
      'entryDate': DateFormat('yyyy-MM-dd').format(entry.date),
      'visitEntry': entry.visitEntry,
      'trialsStart': entry.trialsStart,
      'trialShakes': entry.trialShakes,
      'newUms': entry.newUms,
      'umsShakes': entry.umsShakes,
      'totalUms': entry.totalUms,
      'totalShakes': entry.totalShakes,
      'cashPayment': entry.cashPayment,
      'upiPayment': entry.upiPayment,
      'totalPayment': entry.totalPayment,
      'clubExpenses': entry.clubExpenses,
      'products': productsList,
    };
  }

  /// Submit entry to the API
  Future<void> _submitToApi(DailyEntryData entry, BuildContext dialogCtx) async {
    if (_isSubmitting) return;

    // 1. Close the confirmation dialog first
    Navigator.pop(dialogCtx);

    // 2. Show a progress dialog
    _showProgressDialog(widget.isEditing ? 'Updating entry...' : 'Saving entry...');

    setState(() => _isSubmitting = true);

    try {
      final payload = _buildApiPayload(entry);
      final response = await ApiService.post(
        '/daily-entries/',
        data: payload,
        context: context,
        showSuccessMessage: false,
      );

      // 3. Dismiss progress dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response != null && response['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true); // return true = success, list screen will refresh
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to save entry. Please try again.'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      // Dismiss progress dialog on error
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showProgressDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.accentYellow,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final entry = _buildEntryData();
      _showConfirmationDialog(entry);
    }
  }

  // ─── Confirmation Dialog ───────────────────────────────────────

  void _showConfirmationDialog(DailyEntryData entry) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: AppTheme.accentYellow, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      widget.isEditing ? 'Confirm Update' : 'Confirm Entry',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.formattedDate} • ${entry.dayName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.accentYellow.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _confirmSection('Entry Details', [
                        _confirmRow('Visit Entry', '${entry.visitEntry}'),
                        _confirmRow("Trial's Start", '${entry.trialsStart}'),
                        _confirmRow('New UMS', '${entry.newUms}'),
                      ]),
                      const SizedBox(height: 12),
                      _confirmSection('Shakes & UMS', [
                        _confirmRow('Trial Shakes', '${entry.trialShakes}'),
                        _confirmRow('UMS Shakes', '${entry.umsShakes}'),
                        _confirmRow('Total UMS', '${entry.totalUms}'),
                        _confirmRowHighlight('Total Shakes', '${entry.totalShakes}', AppTheme.accentYellow),
                      ]),
                      const SizedBox(height: 12),
                      _confirmSection('Payments', [
                        _confirmRow('Cash', '₹${entry.cashPayment.toStringAsFixed(2)}'),
                        _confirmRow('UPI', '₹${entry.upiPayment.toStringAsFixed(2)}'),
                        _confirmRow('Club Expenses', '₹${entry.clubExpenses.toStringAsFixed(2)}'),
                        _confirmRowHighlight('Total Payment', '₹${entry.totalPayment.toStringAsFixed(2)}', AppTheme.successGreen),
                      ]),
                      const SizedBox(height: 12),
                      _confirmSection('Products', [
                        ...entry.products.entries.map(
                          (e) => _confirmRow(e.key, '${e.value}'),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              // Action buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.lightGrey, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.darkGrey,
                          side: const BorderSide(color: AppTheme.darkGrey),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitToApi(entry, ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentYellow,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.white,
                                ),
                              )
                            : Text(
                                widget.isEditing ? 'Update' : 'Confirm',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlack,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.darkGrey)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.primaryBlack)),
        ],
      ),
    );
  }

  Widget _confirmRowHighlight(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedDate = widget.existingEntry?.date ?? DateTime.now();
      final e = widget.existingEntry;
      _visitEntryController.text = e != null && e.visitEntry != 0 ? '${e.visitEntry}' : '';
      _trialsStartController.text = e != null && e.trialsStart != 0 ? '${e.trialsStart}' : '';
      _trialShakesController.text = e != null && e.trialShakes != 0 ? '${e.trialShakes}' : '';
      _newUmsController.text = e != null && e.newUms != 0 ? '${e.newUms}' : '';
      _totalUmsController.text = e != null && e.totalUms != 0 ? '${e.totalUms}' : '';
      _umsShakesController.text = e != null && e.umsShakes != 0 ? '${e.umsShakes}' : '';
      _cashPaymentController.text = e != null && e.cashPayment != 0
          ? e.cashPayment.toStringAsFixed(0)
          : '';
      _upiPaymentController.text = e != null && e.upiPayment != 0
          ? e.upiPayment.toStringAsFixed(0)
          : '';
      _clubExpensesController.text = e != null && e.clubExpenses != 0
          ? e.clubExpenses.toStringAsFixed(0)
          : '';
      // Reset product controllers
      final existingProducts = widget.existingEntry?.products ?? {};
      for (final product in _apiProducts) {
        final controller = _productControllers[product.id];
        if (controller != null) {
          final qty = existingProducts[product.name] ?? 0;
          controller.text = qty != 0 ? '$qty' : '';
        }
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Daily Entry' : 'New Daily Entry'),
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: _resetForm,
          ),
        ],
      ),
      body: _isLoadingProducts
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Products...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Date & Day Row
                  _buildDateDayRow(),
                  const SizedBox(height: 20),

                  // Entry Details Section
                  _buildSectionHeader('Entry Details', Icons.edit_note),
                  const SizedBox(height: 10),
                  _buildCompactGrid([
                    _TileData('Visit Entry', _visitEntryController, Icons.login, focusNode: _visitEntryFocus, nextFocus: _trialsStartFocus),
                    _TileData("Trial's Start", _trialsStartController, Icons.play_arrow, focusNode: _trialsStartFocus, nextFocus: _newUmsFocus),
                    _TileData('New UMS', _newUmsController, Icons.person_add, focusNode: _newUmsFocus, nextFocus: _trialShakesFocus),
                  ]),
                  const SizedBox(height: 20),

                  // Shakes & UMS Section
                  _buildSectionHeader('Shakes & UMS', Icons.local_drink),
                  const SizedBox(height: 10),
                  _buildCompactGrid([
                    _TileData('Trial Shakes', _trialShakesController, Icons.science, focusNode: _trialShakesFocus, nextFocus: _umsShakesFocus),
                    _TileData('UMS Shakes', _umsShakesController, Icons.blender, focusNode: _umsShakesFocus, nextFocus: _totalUmsFocus),
                    _TileData('Total UMS', _totalUmsController, Icons.groups, focusNode: _totalUmsFocus, nextFocus: _cashPaymentFocus),
                  ]),
                  const SizedBox(height: 10),
                  _buildTotalCard('Total Shakes', '$_totalShakes', AppTheme.accentYellow, Icons.calculate),
                  const SizedBox(height: 20),

                  // Payments Section
                  _buildSectionHeader('Payments', Icons.payment),
                  const SizedBox(height: 10),
                  _buildCompactGrid([
                    _TileData('Cash Payment', _cashPaymentController, Icons.money, isDecimal: true, focusNode: _cashPaymentFocus, nextFocus: _upiPaymentFocus),
                    _TileData('UPI Payment', _upiPaymentController, Icons.phone_android, isDecimal: true, focusNode: _upiPaymentFocus, nextFocus: _clubExpensesFocus),
                    _TileData('Club Expenses', _clubExpensesController, Icons.account_balance, isDecimal: true, focusNode: _clubExpensesFocus, nextFocus: _apiProducts.isNotEmpty ? _productFocusNodes[_apiProducts.first.id] : null),
                  ]),
                  const SizedBox(height: 10),
                  _buildTotalCard('Total Payment', '₹${_totalPayment.toStringAsFixed(2)}', AppTheme.successGreen, Icons.account_balance_wallet),
                  const SizedBox(height: 20),

                  // Products Section (dynamic from API)
                  _buildSectionHeader('Products', Icons.inventory_2),
                  const SizedBox(height: 10),
                  _buildProductsSection(),
                  const SizedBox(height: 28),

                  // Submit Button
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ─── Products Section (Dynamic) ────────────────────────────────

  Widget _buildProductsSection() {
    if (_isLoadingProducts) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.accentYellow,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading products...',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkGrey.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_apiProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: AppTheme.darkGrey.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No products available',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkGrey.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Build tile data for each product
    final List<_TileData> tiles = [];
    for (var i = 0; i < _apiProducts.length; i++) {
      final product = _apiProducts[i];
      final controller = _productControllers[product.id]!;
      final focusNode = _productFocusNodes[product.id]!;
      final nextFocus = i + 1 < _apiProducts.length
          ? _productFocusNodes[_apiProducts[i + 1].id]
          : null;

      tiles.add(_TileData(
        product.name,
        controller,
        _getProductIcon(product.name),
        focusNode: focusNode,
        nextFocus: nextFocus,
      ));
    }

    return _buildCompactGrid(tiles);
  }

  /// Returns an icon based on the product name
  IconData _getProductIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('sofit') || lower.contains('soft')) return Icons.local_cafe;
    if (lower.contains('formula') || lower.contains('fi')) return Icons.fitness_center;
    if (lower.contains('ppp') || lower.contains('ptt') || lower.contains('ppt')) return Icons.sports_gymnastics;
    if (lower.contains('afresh')) return Icons.local_florist;
    if (lower.contains('hydrate')) return Icons.water_drop;
    if (lower.contains('shake')) return Icons.local_drink;
    return Icons.inventory_2;
  }

  // ─── UI Builder Methods ──────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlack,
            AppTheme.primaryBlack.withOpacity(0.85),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlack.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentYellow, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDayRow() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.white,
              AppTheme.accentYellow.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentYellow.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today, color: AppTheme.accentYellow, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accentYellow.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down_circle,
                  color: AppTheme.accentYellow.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactGrid(List<_TileData> tiles) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return _buildCompactTile(
          tile.label,
          tile.controller,
          tile.icon,
          tile.isDecimal,
          focusNode: tile.focusNode,
          nextFocus: tile.nextFocus,
        );
      },
    );
  }

  Widget _buildCompactTile(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDecimal, {
    FocusNode? focusNode,
    FocusNode? nextFocus,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentYellow, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: isDecimal
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
                textInputAction: nextFocus != null
                    ? TextInputAction.next
                    : TextInputAction.done,
                inputFormatters: isDecimal
                    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
                    : [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlack,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.darkGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.darkGrey.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
                onFieldSubmitted: (_) {
                  if (nextFocus != null) {
                    FocusScope.of(context).requestFocus(nextFocus);
                  }
                },
                onTap: () {
                  controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: controller.text.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGrey,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentYellow.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentYellow,
          foregroundColor: AppTheme.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.isEditing ? Icons.update : Icons.save, size: 22),
            const SizedBox(width: 10),
            Text(
              widget.isEditing ? 'Update Daily Entry' : 'Save Daily Entry',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to hold tile data for the compact grid
class _TileData {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isDecimal;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;

  const _TileData(
    this.label,
    this.controller,
    this.icon, {
    this.isDecimal = false,
    this.focusNode,
    this.nextFocus,
  });
}
