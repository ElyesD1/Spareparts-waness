import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/domain/credit_sale.dart';
import '../../services/credit_payments_service.dart';

class CreditPaymentFormDialog extends StatefulWidget {
  final CreditSale creditSale;
  final VoidCallback onSuccess;

  const CreditPaymentFormDialog({
    super.key,
    required this.creditSale,
    required this.onSuccess,
  });

  @override
  State<CreditPaymentFormDialog> createState() =>
      _CreditPaymentFormDialogState();
}

class _CreditPaymentFormDialogState extends State<CreditPaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final CreditPaymentsService _paymentsService = CreditPaymentsService();

  // Form controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = 'cash';
  DateTime _paymentDate = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _remainingAmount {
    final totalPaid = widget.creditSale.payments.fold(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
    return widget.creditSale.creditAmount - totalPaid;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      setState(() {
        _error = 'Le montant doit être supérieur à 0';
      });
      return;
    }

    if (amount > _remainingAmount) {
      setState(() {
        _error =
            'Le montant ne peut pas dépasser le solde restant (${_remainingAmount.toStringAsFixed(2)} DT)';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final paymentData = {
        'credit_sale_id': widget.creditSale.id,
        'amount': amount,
        'payment_date': _paymentDate.toIso8601String(),
        'payment_method': _paymentMethod,
        'reference_number':
            _referenceController.text.isEmpty
                ? null
                : _referenceController.text,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      await _paymentsService.createCreditPayment(paymentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) _buildErrorMessage(),
                      _buildSaleInfoCard(),
                      const SizedBox(height: 24),
                      _buildAmountField(),
                      const SizedBox(height: 16),
                      _buildPaymentMethodField(),
                      const SizedBox(height: 16),
                      _buildPaymentDateField(),
                      if (_paymentMethod != 'cash') ...[
                        const SizedBox(height: 16),
                        _buildReferenceField(),
                      ],
                      const SizedBox(height: 16),
                      _buildNotesField(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF6366F1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Ajouter un Paiement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Client:',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              Text(
                widget.creditSale.customer.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Crédit total:',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              Text(
                '${widget.creditSale.creditAmount.toStringAsFixed(2)} DT',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Restant à payer:',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              Text(
                '${_remainingAmount.toStringAsFixed(2)} DT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Montant du paiement (DT)',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.attach_money),
        helperText: 'Max: ${_remainingAmount.toStringAsFixed(2)} DT',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer le montant';
        }
        final amount = double.tryParse(value);
        if (amount == null) return 'Montant invalide';
        if (amount <= 0) return 'Le montant doit être supérieur à 0';
        if (amount > _remainingAmount) {
          return 'Montant supérieur au solde restant';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentMethodField() {
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      decoration: const InputDecoration(
        labelText: 'Méthode de paiement',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payment),
      ),
      items: const [
        DropdownMenuItem(value: 'cash', child: Text('Espèces')),
        DropdownMenuItem(value: 'check', child: Text('Chèque')),
        DropdownMenuItem(
          value: 'bank_transfer',
          child: Text('Virement bancaire'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _paymentMethod = value!;
        });
      },
    );
  }

  Widget _buildPaymentDateField() {
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: const Text('Date du paiement'),
      subtitle: Text(
        '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _paymentDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (date != null) {
          setState(() {
            _paymentDate = date;
          });
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildReferenceField() {
    return TextFormField(
      controller: _referenceController,
      decoration: InputDecoration(
        labelText:
            _paymentMethod == 'check'
                ? 'Numéro de chèque'
                : 'Référence de virement',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.confirmation_number),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (optionnel)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
      ),
      maxLines: 3,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _loading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child:
                _loading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                    : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
