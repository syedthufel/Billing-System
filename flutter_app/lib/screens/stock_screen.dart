import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/stock.dart';
import '../models/product.dart';

class StockScreen extends StatefulWidget {
  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Stock> _stocks = [];
  List<Map<String, dynamic>> _lowStockAlerts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStockData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final [stockResponse, alertsResponse] = await Future.wait([
        ApiService.getStock(limit: 100),
        ApiService.getLowStockAlerts(),
      ]);

      setState(() {
        _stocks = (stockResponse['stocks'] as List)
            .map((stock) => Stock.fromJson(stock))
            .toList();
        _lowStockAlerts = List<Map<String, dynamic>>.from(alertsResponse['alerts']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load stock data: $e');
    }
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
        title: const Text('Stock Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Stock (${_stocks.length})'),
            Tab(text: 'Alerts (${_lowStockAlerts.length})'),
            const Tab(text: 'Movements'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllStockTab(),
          _buildAlertsTab(),
          _buildMovementsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockMovementDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Stock Movement',
      ),
    );
  }

  Widget _buildAllStockTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStockData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Products',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _stocks.length,
              itemBuilder: (context, index) {
                final stock = _stocks[index];
                // Note: In a real app, we'd have product details populated
                return StockTile(
                  stock: stock,
                  onTap: () => _showStockDetails(stock),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lowStockAlerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No stock alerts'),
            Text('All products are well stocked!'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStockData,
      child: ListView.builder(
        itemCount: _lowStockAlerts.length,
        itemBuilder: (context, index) {
          final alert = _lowStockAlerts[index];
          return AlertTile(
            alert: alert,
            onTap: () {
              // Handle alert tap
            },
          );
        },
      ),
    );
  }

  Widget _buildMovementsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Stock Movements'),
          Text('Feature coming soon...'),
        ],
      ),
    );
  }

  void _showStockDetails(Stock stock) {
    showDialog(
      context: context,
      builder: (context) => StockDetailsDialog(stock: stock),
    );
  }

  void _showAddStockMovementDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStockMovementDialog(
        stocks: _stocks,
        onAdd: (stockId, type, quantity, reason) async {
          try {
            await ApiService.addStockMovement(stockId, {
              'type': type,
              'quantity': quantity,
              'reason': reason,
            });
            
            _showSuccessSnackBar('Stock movement added successfully');
            _loadStockData();
          } catch (e) {
            _showErrorSnackBar('Failed to add stock movement: $e');
          }
        },
      ),
    );
  }
}

class StockTile extends StatelessWidget {
  final Stock stock;
  final VoidCallback onTap;

  const StockTile({
    Key? key,
    required this.stock,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (stock.stockStatus) {
      case 'out-of-stock':
        statusColor = Colors.red;
        break;
      case 'low-stock':
      case 'minimum-reached':
        statusColor = Colors.orange;
        break;
      case 'overstock':
        statusColor = Colors.amber;
        break;
      default:
        statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Text(
            stock.currentStock.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Product ID: ${stock.productId.substring(0, 8)}...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${stock.location}'),
            Text('Reorder Level: ${stock.reorderLevel}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stock.stockStatus.replaceAll('-', ' ').toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Min: ${stock.minimumStock}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class AlertTile extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;

  const AlertTile({
    Key? key,
    required this.alert,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final urgency = alert['urgency'] as String;
    final isHighPriority = urgency == 'high';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isHighPriority ? Colors.red[50] : Colors.orange[50],
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isHighPriority ? Icons.error : Icons.warning,
          color: isHighPriority ? Colors.red : Colors.orange,
        ),
        title: Text(
          alert['product']['name'] ?? 'Unknown Product',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${alert['currentStock']}'),
            Text('Minimum Required: ${alert['minimumStock']}'),
            Text('Reorder Level: ${alert['reorderLevel']}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHighPriority ? Colors.red : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            urgency.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class StockDetailsDialog extends StatelessWidget {
  final Stock stock;

  const StockDetailsDialog({
    Key? key,
    required this.stock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stock Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Product ID', stock.productId),
            _buildDetailRow('Current Stock', stock.currentStock.toString()),
            _buildDetailRow('Minimum Stock', stock.minimumStock.toString()),
            _buildDetailRow('Maximum Stock', stock.maximumStock.toString()),
            _buildDetailRow('Reorder Level', stock.reorderLevel.toString()),
            _buildDetailRow('Location', stock.location.toString()),
            _buildDetailRow('Status', stock.stockStatus),
            _buildDetailRow('Last Updated', 
                stock.lastUpdated.toString().substring(0, 19)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class AddStockMovementDialog extends StatefulWidget {
  final List<Stock> stocks;
  final Function(String stockId, String type, int quantity, String reason) onAdd;

  const AddStockMovementDialog({
    Key? key,
    required this.stocks,
    required this.onAdd,
  }) : super(key: key);

  @override
  _AddStockMovementDialogState createState() => _AddStockMovementDialogState();
}

class _AddStockMovementDialogState extends State<AddStockMovementDialog> {
  String? _selectedStockId;
  String _selectedType = 'in';
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  final List<String> _movementTypes = ['in', 'out', 'adjustment'];

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Stock Movement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStockId,
              decoration: const InputDecoration(
                labelText: 'Select Product',
              ),
              items: widget.stocks.map((stock) {
                return DropdownMenuItem(
                  value: stock.id,
                  child: Text('${stock.productId.substring(0, 8)}... (Stock: ${stock.currentStock})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStockId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a product';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Movement Type',
              ),
              items: _movementTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: _selectedType == 'adjustment' ? 'New Stock Level' : 'Quantity',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
              ),
              maxLines: 2,
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
            if (_selectedStockId != null && 
                _quantityController.text.isNotEmpty &&
                _reasonController.text.isNotEmpty) {
              final quantity = int.tryParse(_quantityController.text) ?? 0;
              widget.onAdd(
                _selectedStockId!,
                _selectedType,
                quantity,
                _reasonController.text,
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add Movement'),
        ),
      ],
    );
  }
}