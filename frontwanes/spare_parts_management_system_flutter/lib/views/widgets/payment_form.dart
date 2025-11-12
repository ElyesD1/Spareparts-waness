import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/credit_payments_view_model.dart';
import '../../view_model/credit_sales_view_model.dart';
import '../../models/domain/credit_sale.dart';
import '../../services/credit_sales_service.dart';

class PaymentForm extends StatefulWidget {
  final CreditSale creditSale;
  final VoidCallback? onPaymentAdded;
  final VoidCallback? onRefreshCreditSales;

  const PaymentForm({
    Key? key,
    required this.creditSale,
    this.onPaymentAdded,
    this.onRefreshCreditSales,
  }) : super(key: key);

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedPaymentMethod = 'cash';
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final CreditSalesService _creditSalesService = CreditSalesService();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.creditSale.remainingAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 400;
    final isMobile = screenSize.width < 600;
    
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Container(
          width: isMobile ? screenSize.width * 0.95 : 500,
          height: screenSize.height * 0.9,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmall ? 16 : 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Credit Info Cards
                        _buildCreditInfoSection(isSmall),
                        SizedBox(height: isSmall ? 16 : 20),
                        
                        // Payment Amount
                        _buildPaymentAmountSection(isSmall),
                        SizedBox(height: isSmall ? 16 : 20),
                        
                        // Payment Method
                        _buildPaymentMethodSection(isSmall),
                        SizedBox(height: isSmall ? 16 : 20),
                        
                        // Payment Date
                        _buildPaymentDateSection(isSmall),
                        SizedBox(height: isSmall ? 16 : 20),
                        
                        // Optional Fields
                        _buildOptionalFieldsSection(isSmall),
                        SizedBox(height: isSmall ? 20 : 24),
                        
                        // Buttons
                        _buildActionButtons(isSmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4CAF50), const Color(0xFF45a049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payment, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouveau Paiement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.creditSale.customer.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditInfoSection(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF6C757D), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Informations du Crédit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF495057),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Total',
                  '${widget.creditSale.totalAmount.toStringAsFixed(0)} DNT',
                  Colors.blue,
                  Icons.credit_card,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  'Payé',
                  '${widget.creditSale.paidAmount.toStringAsFixed(0)} DNT',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            'Restant à Payer',
            '${widget.creditSale.remainingAmount.toStringAsFixed(0)} DNT',
            Colors.red,
            Icons.account_balance_wallet,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color, IconData icon, {bool isLarge = false}) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isLarge ? 24 : 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAmountSection(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.monetization_on, color: Color(0xFF28A745), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Montant du Paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF495057),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Entrez le montant',
            prefixIcon: const Icon(Icons.euro, color: Color(0xFF28A745)),
            suffixText: 'DNT',
            suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF28A745)),
            filled: true,
            fillColor: const Color(0xFF28A745).withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFF28A745).withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFF28A745).withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF28A745), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un montant';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Montant invalide';
            }
            if (amount > widget.creditSale.remainingAmount) {
              return 'Montant trop élevé';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.payment, color: Color(0xFF007BFF), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Mode de Paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF495057),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF007BFF).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF007BFF).withOpacity(0.3)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: 'cash',
                child: Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.money, color: Color(0xFF28A745), size: 18),
                      const SizedBox(width: 8),
                      const Flexible(child: Text('Espèces', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'check',
                child: Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt, color: Color(0xFFFFC107), size: 18),
                      const SizedBox(width: 8),
                      const Flexible(child: Text('Chèque', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'bank_transfer',
                child: Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance, color: Color(0xFF007BFF), size: 18),
                      const SizedBox(width: 8),
                      const Flexible(child: Text('Virement', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDateSection(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF6F42C1), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Date de Paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF495057),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF6F42C1).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6F42C1).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: Color(0xFF6F42C1)),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF6C757D)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalFieldsSection(bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reference Number
        Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF6C757D), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Référence (optionnel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF495057),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _referenceController,
          decoration: InputDecoration(
            hintText: 'Numéro de référence',
            prefixIcon: const Icon(Icons.tag, color: Color(0xFF6C757D)),
            filled: true,
            fillColor: const Color(0xFF6C757D).withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFF6C757D).withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFF6C757D).withOpacity(0.3)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        
        // Notes
        Row(
          children: [
            const Icon(Icons.note, color: Color(0xFF6C757D), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Notes (optionnel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF495057),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Notes additionnelles',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.edit_note, color: Color(0xFF6C757D)),
            ),
            filled: true,
            fillColor: const Color(0xFF6C757D).withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFF6C757D).withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFF6C757D).withOpacity(0.3)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isSmall) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _submitPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28A745),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Enregistrer le Paiement',
                  style: TextStyle(
                    fontSize: isSmall ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6C757D),
              side: const BorderSide(color: Color(0xFFDEE2E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      try {
        final paymentAmount = double.parse(_amountController.text);
        final wasFullyPaid = paymentAmount >= widget.creditSale.remainingAmount;
        
        // Show modern loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.7),
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Traitement du paiement...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez patienter pendant l\'enregistrement du paiement',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
        
        final paymentData = {
          'credit_sale_id': widget.creditSale.id,
          'received_by': 1, // TODO: Get current user ID
          'amount': paymentAmount,
          'payment_date': _selectedDate.toIso8601String(),
          'payment_method': _selectedPaymentMethod,
          'reference_number': _referenceController.text.isNotEmpty ? _referenceController.text : null,
          'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        };

        await context.read<CreditPaymentsViewModel>().createPayment(paymentData);
        
        print('Payment created successfully, checking credit sale status...');
        
        // Check and update credit sale status after payment
        try {
          await _creditSalesService.checkAndUpdateCreditSaleStatus(widget.creditSale.id);
          print('Credit sale status updated successfully');
          
        } catch (statusError) {
          print('Error updating credit sale status: $statusError');
          // Don't show error to user as payment was successful
        }
        
        if (widget.onPaymentAdded != null) {
          widget.onPaymentAdded!();
        }
        
        // Refresh credit sales data to show updated status
        if (widget.onRefreshCreditSales != null) {
          widget.onRefreshCreditSales!();
        }
        
        // Also refresh the specific credit sale in the view model
        try {
          await context.read<CreditSalesViewModel>().refreshCreditSale(widget.creditSale.id);
        } catch (e) {
          print('Error refreshing credit sale in view model: $e');
        }
        
        // Close loading dialog
        Navigator.of(context).pop();
        // Close payment form
        Navigator.of(context).pop();
        
        // Show modern success dialog
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.7),
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    wasFullyPaid ? 'Paiement Complet!' : 'Paiement Enregistré!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wasFullyPaid 
                      ? 'Le crédit a été entièrement payé. Le statut a été mis à jour.'
                      : 'Le paiement de ${paymentAmount.toStringAsFixed(0)} DNT a été ajouté avec succès.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Parfait!'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        
      } catch (e) {
        // Close loading dialog if open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Show modern error dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur de Paiement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erreur: $e',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Fermer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }
}
