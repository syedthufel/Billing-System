import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../config/app_config.dart';
import '../controllers/billing_controller.dart';
import '../services/pdf_service.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerGstinController = TextEditingController();
  final _placeOfSupplyController = TextEditingController(text: 'TAMILNADU');
  
  List<InvoiceItem> _items = [];
  String _paymentMethod = 'cash';
  double _cgstRate = 9.0;
  double _sgstRate = 9.0;

  @override
  void initState() {
    super.initState();
    _addNewItem();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _customerGstinController.dispose();
    _placeOfSupplyController.dispose();
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      _items.add(InvoiceItem(
        product: '',
        productId: '',
        description: '',
        hsnCode: '',
        quantity: 1,
        price: 0.0,
        gstRate: 18.0,
        gstAmount: 0.0,
        total: 0.0,
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  void _updateItem(int index, InvoiceItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get _cgstAmount {
    return (_subtotal * _cgstRate) / 100;
  }

  double get _sgstAmount {
    return (_subtotal * _sgstRate) / 100;
  }

  double get _totalAmount {
    return _subtotal + _cgstAmount + _sgstAmount;
  }

  Future<void> _generateInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty || _items.every((item) => item.description.isEmpty)) {
      _showErrorSnackBar('Please add at least one item');
      return;
    }

    final invoice = Invoice(
      id: '',
      invoiceNumber: '',
      customer: Customer(
        name: _customerNameController.text.trim(),
        address: _customerAddressController.text.trim(),
        gstin: _customerGstinController.text.trim(),
        phone: '',
        email: '',
      ),
      items: _items,
      subtotal: _subtotal,
      totalGST: _cgstAmount + _sgstAmount,
      total: _totalAmount,
      paymentMethod: _paymentMethod,
      paymentStatus: 'paid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref.read(billingControllerProvider.notifier).createInvoice(invoice);
    
    if (success && mounted) {
      _showSuccessSnackBar('Invoice generated successfully');
      // Show options to print or share PDF
      _showPdfOptions(invoice);
    } else {
      _showErrorSnackBar('Failed to generate invoice');
    }
  }

  void _clearForm() {
    _customerNameController.clear();
    _customerAddressController.clear();
    _customerGstinController.clear();
    setState(() {
      _items.clear();
      _addNewItem();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showPdfOptions(Invoice invoice) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invoice Generated'),
        content: const Text('What would you like to do with the invoice?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
            child: const Text('New Invoice'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _printInvoice(invoice);
              _clearForm();
            },
            child: const Text('Print'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _shareInvoice(invoice);
              _clearForm();
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice(Invoice invoice) async {
    try {
      await PdfService.printInvoice(invoice);
    } catch (e) {
      _showErrorSnackBar('Failed to print invoice');
    }
  }

  Future<void> _shareInvoice(Invoice invoice) async {
    try {
      await PdfService.shareInvoice(invoice);
    } catch (e) {
      _showErrorSnackBar('Failed to share invoice');
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearForm,
            tooltip: 'Clear Form',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Invoice Header
            _buildInvoiceHeader(),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Details
                    _buildCustomerDetails(),
                    const SizedBox(height: 24),
                    
                    // Items Section
                    _buildItemsSection(),
                    const SizedBox(height: 24),
                    
                    // Tax Calculations
                    _buildTaxCalculations(),
                    const SizedBox(height: 24),
                    
                    // Payment Method
                    _buildPaymentMethod(),
                  ],
                ),
              ),
            ),
            
            // Generate Invoice Button
            _buildBottomActions(billingState),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Text(
            'TAX INVOICE',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConfig.companyName.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            AppConfig.companyAddress,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          if (AppConfig.companyGstin.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'GSTIN No. : ${AppConfig.companyGstin}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill To',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name*',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _placeOfSupplyController,
                    decoration: const InputDecoration(
                      labelText: 'Place of Supply',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerAddressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customerGstinController,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN No.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invoice Details'),
                        const SizedBox(height: 8),
                        Text('Date: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Description of Services/Products',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNewItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return _buildItemRow(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: item.description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  _updateItem(index, item.copyWith(description: value));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: item.hsnCode,
                decoration: const InputDecoration(
                  labelText: 'HSN Code',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  _updateItem(index, item.copyWith(hsnCode: value));
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: item.quantity.toString(),
                decoration: const InputDecoration(
                  labelText: 'Qty',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final qty = int.tryParse(value) ?? 1;
                  _updateItem(index, item.copyWith(quantity: qty));
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: item.price.toString(),
                decoration: const InputDecoration(
                  labelText: 'Rate',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value) ?? 0.0;
                  _updateItem(index, item.copyWith(price: price));
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '₹${(item.quantity * item.price).toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeItem(index),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaxCalculations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTaxRow('Taxable Value', _subtotal),
            const Divider(),
            _buildTaxRow('ADD CGST $_cgstRate%', _cgstAmount),
            _buildTaxRow('ADD SGST $_sgstRate%', _sgstAmount),
            const Divider(thickness: 2),
            _buildTaxRow('Total', _totalAmount, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = 'cash'),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'cash',
                          groupValue: _paymentMethod,
                          onChanged: (value) => setState(() => _paymentMethod = value!),
                        ),
                        const Text('Cash'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = 'card'),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'card',
                          groupValue: _paymentMethod,
                          onChanged: (value) => setState(() => _paymentMethod = value!),
                        ),
                        const Text('Card'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = 'upi'),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'upi',
                          groupValue: _paymentMethod,
                          onChanged: (value) => setState(() => _paymentMethod = value!),
                        ),
                        const Text('UPI'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(AsyncValue billingState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total: ₹${_totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: billingState.isLoading ? null : _previewInvoice,
            icon: const Icon(Icons.preview),
            label: const Text('Preview'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: billingState.isLoading ? null : _generateInvoice,
            icon: billingState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.receipt_long),
            label: const Text('Generate'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty || _items.every((item) => item.description.isEmpty)) {
      _showErrorSnackBar('Please add at least one item');
      return;
    }

    final invoice = Invoice(
      id: 'preview',
      invoiceNumber: 'PREVIEW-${DateTime.now().millisecondsSinceEpoch}',
      customer: Customer(
        name: _customerNameController.text.trim().isEmpty 
            ? 'Sample Customer' : _customerNameController.text.trim(),
        address: _customerAddressController.text.trim(),
        gstin: _customerGstinController.text.trim(),
        phone: '',
        email: '',
      ),
      items: _items,
      subtotal: _subtotal,
      totalGST: _cgstAmount + _sgstAmount,
      total: _totalAmount,
      paymentMethod: _paymentMethod,
      paymentStatus: 'preview',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await PdfService.printInvoice(invoice);
    } catch (e) {
      _showErrorSnackBar('Failed to preview invoice');
    }
  }
}