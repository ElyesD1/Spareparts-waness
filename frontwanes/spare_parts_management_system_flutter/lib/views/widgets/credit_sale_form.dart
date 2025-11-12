import 'package:flutter/material.dart';

class CreditSaleForm extends StatefulWidget {
  final Function(String customerId, double totalAmount) onSubmit;

  const CreditSaleForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  _CreditSaleFormState createState() => _CreditSaleFormState();
}

class _CreditSaleFormState extends State<CreditSaleForm> {
  final _formKey = GlobalKey<FormState>();
  String _customerId = '';
  double _totalAmount = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Credit Sale'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Customer ID'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a customer ID';
                }
                return null;
              },
              onSaved: (value) => _customerId = value!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Total Amount'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onSaved: (value) => _totalAmount = double.parse(value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onSubmit(_customerId, _totalAmount);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
