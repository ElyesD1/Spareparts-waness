import 'package:flutter/material.dart';
import '../../models/domain/credit_sale.dart';
import '../../services/credit_payments_service.dart';
import '../../services/credit_sales_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentForm extends StatefulWidget {
  final CreditSale creditSale;
  final VoidCallback onPaymentAdded;
  final VoidCallback? onRefreshCreditSales;

  const PaymentForm({
    Key? key, 
    required this.creditSale, 
    required this.onPaymentAdded,
    this.onRefreshCreditSales,
  }) : super(key: key);

  @override
  _PaymentFormState createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  double? _amount;
  String _paymentMethod = 'cash';
  String _notes = '';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        constraints: BoxConstraints(
          maxWidth: 500,
          minWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(color: Colors.green.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Add Payment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Credit Sale Info avec design amélioré
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Customer: ${widget.creditSale.customer.name}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoRow('Total Amount', '${widget.creditSale.totalAmount.toStringAsFixed(2)} DNT', Colors.blue.shade600),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoRow('Remaining', '${widget.creditSale.remainingAmount.toStringAsFixed(2)} DNT', Colors.orange.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'After this payment, the remaining amount will be ${(widget.creditSale.remainingAmount - (_amount ?? 0)).toStringAsFixed(2)} DNT',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Form avec design amélioré
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Amount Field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Amount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _amount?.toString(),
                                  decoration: InputDecoration(
                                    hintText: 'Enter amount',
                                    prefixIcon: const Icon(Icons.attach_money),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                    ),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) {
                                    setState(() {
                                      _amount = double.tryParse(value);
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter payment amount';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount <= 0) {
                                      return 'Please enter a valid amount';
                                    }
                                    if (amount > widget.creditSale.remainingAmount) {
                                      return 'Amount cannot exceed remaining balance';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Payment Method Field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _paymentMethod,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.payment),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                                    DropdownMenuItem(value: 'card', child: Text('Card')),
                                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                                    DropdownMenuItem(value: 'check', child: Text('Check')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _paymentMethod = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Notes Field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes (Optional)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _notes,
                                  decoration: InputDecoration(
                                    hintText: 'Add payment notes...',
                                    prefixIcon: const Icon(Icons.note),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                    ),
                                  ),
                                  maxLines: 3,
                                  onChanged: (value) {
                                    _notes = value;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed footer with buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Add Payment',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildInfoRow(String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    if (_formKey.currentState!.validate() && _amount != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Get the auth token to extract user ID
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        
        final paymentData = {
          'credit_sale_id': widget.creditSale.id,
          'amount': _amount,
          'payment_method': _paymentMethod,
          'notes': _notes,
          'payment_date': DateTime.now().toIso8601String(),
        };

        
        await CreditPaymentsService().createCreditPayment(paymentData);
        
        // Vérifier et mettre à jour automatiquement le statut
        try {
          await CreditSalesService().checkAndUpdateCreditSaleStatus(widget.creditSale.id);
          
          // Check if this payment completed the credit sale
          final wasFullyPaid = _amount! >= widget.creditSale.remainingAmount;
          
          if (wasFullyPaid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paiement complet! Le statut a été mis à jour vers "Payé".'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment of ${_amount!.toStringAsFixed(2)} DNT added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Ne pas bloquer le processus si la mise à jour du statut échoue
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment of ${_amount!.toStringAsFixed(2)} DNT added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        widget.onPaymentAdded();
        
        // Refresh credit sales data to show updated status
        if (widget.onRefreshCreditSales != null) {
          widget.onRefreshCreditSales!();
        }
        
        Navigator.of(context).pop();
      } catch (e) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
