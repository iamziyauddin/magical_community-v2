import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magical_community/core/theme/app_theme.dart';
import 'package:magical_community/core/services/api_service.dart';
import 'package:magical_community/models/consumption_group_model.dart';

class ConsumptionDetailScreen extends StatefulWidget {
  final ConsumptionGroupModel consumption;

  const ConsumptionDetailScreen({super.key, required this.consumption});

  @override
  State<ConsumptionDetailScreen> createState() =>
      _ConsumptionDetailScreenState();
}

class _ConsumptionDetailScreenState extends State<ConsumptionDetailScreen> {
  late ConsumptionGroupModel _consumption;
  bool _isDeleting = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _consumption = widget.consumption;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          title: const Text('Consumption Details'),
          backgroundColor: AppTheme.primaryBlack,
          foregroundColor: AppTheme.white,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Edit',
              onPressed: _isSaving || _isDeleting ? null : _showEditDialog,
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: _isSaving || _isDeleting ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMainCard(),
              const SizedBox(height: 16),
              _buildProductsCard(),
              const SizedBox(height: 16),
              _buildDetailsCard(),
              // if (_consumption.notes?.isNotEmpty == true) ...[
              //   const SizedBox(height: 16),
              //   _buildNotesCard(),
              // ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppTheme.white, AppTheme.errorRed.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Consumption Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  _consumption.totalProducts.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorRed,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              _consumption.totalProducts == 1
                  ? _consumption.items.first.productName
                  : 'Multi-Product Consumption',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlack,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Total Quantity Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.remove_circle,
                    color: AppTheme.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Consumed: ${_consumption.totalQuantity}',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
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
                Icon(Icons.inventory_2, color: AppTheme.errorRed, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Products Consumed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List all products
            ..._consumption.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: EdgeInsets.only(
                  bottom: index < _consumption.items.length - 1 ? 12 : 0,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: AppTheme.errorRed, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.inventory,
                        color: AppTheme.errorRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlack,
                            ),
                          ),
                          // const SizedBox(height: 2),
                          // Text(
                          //   'Product ID: ${item.productId}',
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //     color: AppTheme.darkGrey.withOpacity(0.7),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
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
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryBlack,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Consumption Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // _buildDetailRow(
            //   Icons.confirmation_number,
            //   'Consumption ID',
            //   consumption.id,
            // ),
            // const SizedBox(height: 16),
            _buildDetailRow(
              Icons.shopping_cart,
              'Products Count',
              '${_consumption.totalProducts} products',
            ),
            const SizedBox(height: 16),

            // _buildDetailRow(
            //   Icons.remove_circle,
            //   'Total Quantity',
            //   '${consumption.totalQuantity} units',
            // ),
            // const SizedBox(height: 16),
            _buildDetailRow(
              Icons.calendar_today,
              'Consumption Date',
              DateFormat('EEEE, MMMM dd, yyyy').format(_consumption.date),
            ),
            const SizedBox(height: 16),

            // _buildDetailRow(
            //   Icons.access_time,
            //   'Time Recorded',
            //   DateFormat('HH:mm:ss').format(consumption.createdAt),
            // ),
            // const SizedBox(height: 16),

            // _buildDetailRow(Icons.person, 'Added By', consumption.addedBy),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.darkGrey.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkGrey.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildNotesCard() {
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
                Icon(Icons.note, color: AppTheme.accentYellow, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Additional Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentYellow.withOpacity(0.3),
                ),
              ),
              child: Text(
                _consumption.notes!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryBlack,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    // Build a map of productId -> quantity for editing
    final Map<String, int> quantities = {
      for (final item in _consumption.items) item.productId: item.quantity,
    };
    bool saving = false; // local dialog saving state for inline progress

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Consumption'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat(
                          'EEE, MMM dd, yyyy',
                        ).format(_consumption.date),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _consumption.items.length,
                        itemBuilder: (context, index) {
                          final item = _consumption.items[index];
                          final q = quantities[item.productId] ?? 0;
                          return ListTile(
                            title: Text(
                              item.productName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: q > 0
                                      ? () => setDialogState(
                                          () => quantities[item.productId] =
                                              q - 1,
                                        )
                                      : null,
                                  icon: const Icon(Icons.remove),
                                  iconSize: 28,
                                ),
                                Text(
                                  '$q',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setDialogState(
                                    () => quantities[item.productId] = q + 1,
                                  ),
                                  icon: const Icon(Icons.add),
                                  iconSize: 28,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tip: Set to 0 to remove a product from this date.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (saving || _isSaving)
                      ? null
                      : () async {
                          // Build products payload excluding zeros
                          final products = quantities.entries
                              .where((e) => e.value > 0)
                              .map(
                                (e) => {
                                  'productId': e.key,
                                  'quantity': e.value,
                                },
                              )
                              .toList();

                          if (products.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please keep at least one product with quantity > 0',
                                ),
                                backgroundColor: AppTheme.errorRed,
                              ),
                            );
                            return;
                          }
                          // turn on inline progress
                          setDialogState(() => saving = true);
                          setState(() => _isSaving = true);
                          dynamic res;
                          try {
                            res = await ApiService.put(
                              '/products/usage',
                              data: {
                                'date': DateFormat(
                                  'yyyy-MM-dd',
                                ).format(_consumption.date),
                                'products': products,
                              },
                              context: context,
                              successMessage: 'Consumption updated',
                            );
                          } finally {
                            setDialogState(() => saving = false);
                            setState(() => _isSaving = false);
                          }

                          if (res != null && mounted) {
                            // Update local state to reflect new quantities
                            setState(() {
                              _consumption = _consumption.copyWith(
                                items: _consumption.items
                                    .map(
                                      (it) => it.copyWith(
                                        quantity:
                                            quantities[it.productId] ??
                                            it.quantity,
                                      ),
                                    )
                                    .where(
                                      (it) =>
                                          (quantities[it.productId] ??
                                              it.quantity) >
                                          0,
                                    )
                                    .toList(),
                              );
                              _hasChanges = true; // mark to refresh list
                            });
                            if (mounted)
                              Navigator.pop(ctx); // close edit dialog only
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                  ),
                  child: (saving || _isSaving)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete() {
    bool deleting = false; // local dialog deleting state for inline progress
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Delete Consumption'),
            content: Text(
              'Delete all product usage for ${DateFormat('MMM dd, yyyy').format(_consumption.date)}? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: deleting
                    ? null
                    : () async {
                        setDialogState(() => deleting = true);
                        setState(() => _isDeleting = true);
                        dynamic res;
                        try {
                          res = await ApiService.delete(
                            '/products/usage',
                            data: {
                              'date': DateFormat(
                                'yyyy-MM-dd',
                              ).format(_consumption.date),
                            },
                            context: context,
                            successMessage: 'Consumption deleted',
                          );
                        } finally {
                          setDialogState(() => deleting = false);
                          setState(() => _isDeleting = false);
                        }
                        if (res != null && mounted) {
                          Navigator.pop(ctx); // close confirm dialog
                          Navigator.of(
                            context,
                          ).pop(true); // close detail and refresh list
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  foregroundColor: Colors.white,
                ),
                child: deleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }
}
