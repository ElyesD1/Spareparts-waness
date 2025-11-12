import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/domain/operational_expense.dart';
import '../../services/operational_expense_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/auth_service.dart';

class OperationalExpenseForm extends StatefulWidget {
  final OperationalExpense? expense;
  final VoidCallback onSuccess;

  const OperationalExpenseForm({
    Key? key,
    this.expense,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<OperationalExpenseForm> createState() => _OperationalExpenseFormState();
}

class _OperationalExpenseFormState extends State<OperationalExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'other';
  DateTime _selectedDate = DateTime.now();
  String?
  _selectedWarehouseId; // Changed to nullable to avoid default invalid value
  String? _createdBy;

  List<Map<String, dynamic>> _warehouses = [];
  bool _loading = false;
  bool _loadingData = true;

  final List<Map<String, dynamic>> _expenseTypes = [
    {'value': 'rent', 'label': 'Loyer', 'icon': Icons.home},
    {
      'value': 'electricity',
      'label': 'Électricité',
      'icon': Icons.electric_bolt,
    },
    {'value': 'water', 'label': 'Eau', 'icon': Icons.water_drop},
    {'value': 'fuel', 'label': 'Carburant', 'icon': Icons.local_gas_station},
    {'value': 'other', 'label': 'Autre', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final futures = await Future.wait([
        WarehouseService().getWarehouses(),
        AuthService().getCurrentUser(),
      ]);

      setState(() {
        _warehouses = futures[0] as List<Map<String, dynamic>>;
        final currentUser = futures[1] as Map<String, dynamic>?;
        // Handle multiple possible ID field names from backend
        _createdBy =
            currentUser?['userId'] ?? currentUser?['id'] ?? currentUser?['_id'];
        _loadingData = false;
      });

      // Set default warehouse if available
      if (_warehouses.isNotEmpty && _selectedWarehouseId == null) {
        _selectedWarehouseId = _warehouses.first['id']?.toString();
      }

      // Load existing expense data if editing
      if (widget.expense != null) {
        _titleController.text = widget.expense!.title;
        _amountController.text = widget.expense!.amount.toString();
        _selectedType = widget.expense!.type;
        _selectedDate = widget.expense!.date;
        _selectedWarehouseId = widget.expense!.warehouseId;
        _createdBy = widget.expense!.createdBy;
        if (widget.expense!.note != null) {
          _noteController.text = widget.expense!.note!;
        }
      }
    } catch (e) {
      setState(() => _loadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de chargement: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un entrepôt')),
      );
      return;
    }

    if (_createdBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erreur: Impossible de déterminer l\'utilisateur actuel',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final expense = OperationalExpense(
        id: widget.expense?.id,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _selectedType,
        warehouseId:
            _selectedWarehouseId!, // Safe to use ! here after null check
        createdBy: _createdBy!,
        date: _selectedDate,
        note:
            _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
      );

      if (widget.expense != null) {
        await OperationalExpenseService.updateOperationalExpense(
          widget.expense!.id!,
          expense,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dépense mise à jour avec succès')),
          );
        }
      } else {
        await OperationalExpenseService.createOperationalExpense(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dépense ajoutée avec succès')),
          );
        }
      }

      // The parent will handle Navigator.pop() in onSuccess callback
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B3C34),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            hintText: 'Enter $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8F0EE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8F0EE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C63FF)),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    if (_loadingData) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Fixed at top
              Container(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit : Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? 'Modifier Dépense'
                                : 'Ajouter Nouvelle Dépense',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B3C34),
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Mettre à jour les détails de la dépense'
                                : 'Créer une nouvelle dépense opérationnelle',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFFB0B3C7)),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      _buildTextField(
                        label: 'Title',
                        controller: _titleController,
                        icon: Icons.title,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),

                      // Amount Field
                      _buildTextField(
                        label: 'Amount',
                        controller: _amountController,
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Please enter a valid amount';
                          }
                          if (double.parse(value.trim()) <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),

                      // Type Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Type',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B3C34),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.category,
                                color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8F0EE),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8F0EE),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items:
                                _expenseTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type['value'],
                                    child: Row(
                                      children: [
                                        Icon(
                                          type['icon'],
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(type['label']),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                      // Warehouse Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Warehouse',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B3C34),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value:
                                (_selectedWarehouseId != null &&
                                        _warehouses.any(
                                          (w) =>
                                              w['id']?.toString() ==
                                              _selectedWarehouseId,
                                        ))
                                    ? _selectedWarehouseId
                                    : null,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.warehouse,
                                color: Colors.grey,
                              ),
                              hintText: 'Sélectionner un entrepôt',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8F0EE),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8F0EE),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items:
                                _warehouses.map((warehouse) {
                                  return DropdownMenuItem<String>(
                                    value: warehouse['id']?.toString(),
                                    child: Text(
                                      warehouse['name'] ??
                                          'Entrepôt ${warehouse['id']}',
                                    ),
                                  );
                                }).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner un entrepôt';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _selectedWarehouseId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                      // Date Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B3C34),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE8F0EE),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFF8F9FB),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(_selectedDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                      // Note Field
                      _buildTextField(
                        label: 'Note (Optional)',
                        controller: _noteController,
                        icon: Icons.note,
                        maxLines: 3,
                      ),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _loading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _loading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(isEditing ? 'Update' : 'Create'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
