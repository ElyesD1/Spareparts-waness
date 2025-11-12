import 'package:flutter/material.dart';
import '../../models/domain/credit_sale.dart';
import '../../services/session_manager.dart';
import 'credit_status_badge.dart';

class CreditSaleCard extends StatefulWidget {
  final CreditSale creditSale;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAddPayment;
  final VoidCallback? onEdit;

  const CreditSaleCard({
    Key? key,
    required this.creditSale,
    this.onViewDetails,
    this.onAddPayment,
    this.onEdit,
  }) : super(key: key);

  @override
  State<CreditSaleCard> createState() => _CreditSaleCardState();
}

class _CreditSaleCardState extends State<CreditSaleCard> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await SessionManager.getUser();
    setState(() {
      _userRole = user?['role'] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer ID: ${widget.creditSale.customer.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CreditStatusBadge(status: widget.creditSale.statusDisplay),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Total', '${widget.creditSale.totalAmount.toStringAsFixed(2)} DNT'),
                ),
                Expanded(
                  child: _buildInfoItem('Payé', '${widget.creditSale.paidAmount.toStringAsFixed(2)} DNT'),
                ),
                Expanded(
                  child: _buildInfoItem('Restant', '${widget.creditSale.remainingAmount.toStringAsFixed(2)} DNT'),
                ),
                Expanded(
                  child: _buildInfoItem('Date', widget.creditSale.saleDate.toString().split(' ')[0]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onViewDetails != null)
                  TextButton.icon(
                    onPressed: widget.onViewDetails,
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Voir détails'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                    ),
                  ),
                // Bouton d'édition pour les admins
                if (_userRole == 'admin' && widget.onEdit != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Éditer'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange[600],
                    ),
                  ),
                ],
                if (widget.creditSale.remainingAmount > 0 && widget.onAddPayment != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: widget.onAddPayment,
                    icon: const Icon(Icons.attach_money, size: 16),
                    label: const Text('Ajouter paiement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
