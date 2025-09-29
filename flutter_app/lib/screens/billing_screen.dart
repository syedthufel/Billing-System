import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/invoice.dart';

class BillingScreen extends StatefulWidget {
  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<Product> _products = [];
  List<InvoiceItem> _cartItems = [];
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'cash',
    'card', 
    'upi',
    'bank-transfer',
    'cheque'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final response = await ApiService.getProducts(limit: 100);
      setState(() {
        _products = (response['products'] as List)
            .map((product) => Product.fromJson(product))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load products: $e');
    }
  }

  void _addToCart(Product product) {
    showDialog(
      context: context,
      builder: (context) => AddToCartDialog(
        product: product,
        onAdd: (quantity, discount) {
          final existingItemIndex = _cartItems.indexWhere(
            (item) => item.productId == product.id,
          );

          if (existingItemIndex != -1) {
            // Update existing item
            final existingItem = _cartItems[existingItemIndex];
            final newQuantity = existingItem.quantity + quantity;
            final itemSubtotal = product.basePrice * newQuantity;
            final itemGST = itemSubtotal * (product.gstRate / 100);
            final itemTotal = itemSubtotal + itemGST - discount;

            _cartItems[existingItemIndex] = InvoiceItem(
              productId: product.id,
              productName: product.name,
              sku: product.sku,
              quantity: newQuantity,
              unitPrice: product.basePrice,
              gstRate: product.gstRate,
              gstAmount: itemGST,
              totalAmount: itemTotal,
              discount: discount,
            );
          } else {
            // Add new item
            final itemSubtotal = product.basePrice * quantity;
            final itemGST = itemSubtotal * (product.gstRate / 100);
            final itemTotal = itemSubtotal + itemGST - discount;

            _cartItems.add(InvoiceItem(
              productId: product.id,
              productName: product.name,
              sku: product.sku,
              quantity: quantity,
              unitPrice: product.basePrice,
              gstRate: product.gstRate,
              gstAmount: itemGST,
              totalAmount: itemTotal,
              discount: discount,
            ));
          }
          
          setState(() {});
        },
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  double get _subtotal => _cartItems.fold(
      0, (sum, item) => sum + (item.unitPrice * item.quantity));

  double get _totalGST => _cartItems.fold(0, (sum, item) => sum + item.gstAmount);

  double get _totalDiscount => _cartItems.fold(0, (sum, item) => sum + item.discount);

  double get _grandTotal => _subtotal + _totalGST - _totalDiscount;

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate() || _cartItems.isEmpty) {
      _showErrorSnackBar('Please fill all required fields and add items to cart');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final invoiceData = {
        'customerInfo': {
          'name': _customerNameController.text.trim(),
          'email': _customerEmailController.text.trim(),
          'phone': _customerPhoneController.text.trim(),
        },
        'items': _cartItems.map((item) => item.toJson()).toList(),
        'paymentMethod': _selectedPaymentMethod,
        'notes': _notesController.text.trim(),
      };

      final response = await ApiService.createInvoice(invoiceData);
      
      setState(() {
        _isLoading = false;
      });

      // Clear form after successful creation
      _clearForm();
      
      _showSuccessSnackBar('Invoice created successfully: ${response['invoiceNumber']}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to create invoice: $e');
    }
  }

  void _clearForm() {
    _customerNameController.clear();
    _customerPhoneController.clear();
    _customerEmailController.clear();
    _notesController.clear();
    setState(() {
      _cartItems.clear();
      _selectedPaymentMethod = 'cash';
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: _clearForm,
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Product List (Left Side)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search Products',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            // Implement search functionality
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return ProductTile(
                              product: product,
                              onAddToCart: () => _addToCart(product),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const VerticalDivider(),
                
                // Invoice Form (Right Side)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Customer Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _customerNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Customer Name *',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter customer name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customerPhoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number *',
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _customerEmailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email (Optional)',
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Cart Items
                      Expanded(
                        child: _cartItems.isEmpty
                            ? const Center(
                                child: Text('Add products to create invoice'),
                              )
                            : ListView.builder(
                                itemCount: _cartItems.length,
                                itemBuilder: (context, index) {
                                  return CartItemTile(
                                    item: _cartItems[index],
                                    onRemove: () => _removeFromCart(index),
                                  );
                                },
                              ),
                      ),
                      
                      // Invoice Summary
                      if (_cartItems.isNotEmpty) ...[
                        const Divider(),
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:'),
                                  Text('₹${_subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('GST:'),
                                  Text('₹${_totalGST.toStringAsFixed(2)}'),
                                ],
                              ),
                              if (_totalDiscount > 0)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Discount:'),
                                    Text('-₹${_totalDiscount.toStringAsFixed(2)}'),
                                  ],
                                ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total:',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${_grandTotal.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedPaymentMethod,
                                decoration: const InputDecoration(
                                  labelText: 'Payment Method',
                                ),
                                items: _paymentMethods.map((method) {
                                  return DropdownMenuItem(
                                    value: method,
                                    child: Text(method.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Notes (Optional)',
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _createInvoice,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text('Create Invoice'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductTile({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(product.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${product.brand} - ${product.model}'),
          Text('SKU: ${product.sku}'),
          Text('₹${product.basePrice.toStringAsFixed(2)} + ${product.gstRate}% GST'),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_shopping_cart),
        onPressed: onAddToCart,
      ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback onRemove;

  const CartItemTile({
    Key? key,
    required this.item,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.productName),
      subtitle: Text('${item.quantity} x ₹${item.unitPrice.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹${item.totalAmount.toStringAsFixed(2)}'),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class AddToCartDialog extends StatefulWidget {
  final Product product;
  final Function(int quantity, double discount) onAdd;

  const AddToCartDialog({
    Key? key,
    required this.product,
    required this.onAdd,
  }) : super(key: key);

  @override
  _AddToCartDialogState createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<AddToCartDialog> {
  final _quantityController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0');

  @override
  void dispose() {
    _quantityController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _discountController,
            decoration: const InputDecoration(
              labelText: 'Discount (₹)',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final quantity = int.tryParse(_quantityController.text) ?? 1;
            final discount = double.tryParse(_discountController.text) ?? 0;
            widget.onAdd(quantity, discount);
            Navigator.of(context).pop();
          },
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}