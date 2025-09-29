import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'billing_screen.dart';
import 'stock_screen.dart';
import 'tally_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _stockSummary;
  bool _isLoading = true;

  final List<Widget> _screens = [
    DashboardTab(),
    BillingScreen(),
    StockScreen(),
    TallyScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final [dashboardData, stockSummary] = await Future.wait([
        ApiService.getDashboardData(),
        ApiService.getStockSummary(),
      ]);

      setState(() {
        _dashboardData = dashboardData;
        _stockSummary = stockSummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load dashboard data: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing System'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'biometric':
                  _showBiometricDialog();
                  break;
                case 'logout':
                  await context.read<AuthService>().logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'biometric',
                child: ListTile(
                  leading: Icon(Icons.fingerprint),
                  title: Text('Biometric Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(),
          _screens[1],
          _screens[2],
          _screens[3],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Billing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Tally',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Consumer<AuthService>(
              builder: (context, authService, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            authService.currentUser?.username.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${authService.currentUser?.username ?? 'User'}',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                'Role: ${authService.currentUser?.role.toUpperCase() ?? 'USER'}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (authService.currentUser?.biometricEnabled == true)
                          Icon(
                            Icons.fingerprint,
                            color: Theme.of(context).primaryColor,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Sales Summary
            if (_dashboardData != null) ...[
              Text(
                'Sales Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Today',
                      '₹${_dashboardData!['today']['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                      '${_dashboardData!['today']['totalInvoices'] ?? 0} invoices',
                      Icons.today,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'This Month',
                      '₹${_dashboardData!['thisMonth']['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                      '${_dashboardData!['thisMonth']['totalInvoices'] ?? 0} invoices',
                      Icons.calendar_month,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'This Year',
                      '₹${_dashboardData!['thisYear']['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                      '${_dashboardData!['thisYear']['totalInvoices'] ?? 0} invoices',
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'GST Collected',
                      '₹${_dashboardData!['today']['totalGST']?.toStringAsFixed(2) ?? '0.00'}',
                      'Today',
                      Icons.account_balance,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Stock Summary
            if (_stockSummary != null) ...[
              Text(
                'Stock Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Products',
                      '${_stockSummary!['totalProducts'] ?? 0}',
                      'Items in inventory',
                      Icons.inventory,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Low Stock',
                      '${_stockSummary!['lowStockCount'] ?? 0}',
                      'Need attention',
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Out of Stock',
                      '${_stockSummary!['outOfStockCount'] ?? 0}',
                      'Items',
                      Icons.remove_circle,
                      Colors.red[700]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Overstock',
                      '${_stockSummary!['overstockCount'] ?? 0}',
                      'Items',
                      Icons.add_circle,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Create Invoice',
                    Icons.add_box,
                    Colors.green,
                    () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'Stock Check',
                    Icons.search,
                    Colors.blue,
                    () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'View Reports',
                    Icons.analytics,
                    Colors.purple,
                    () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, Color color) {
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
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBiometricDialog() {
    final authService = context.read<AuthService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                authService.currentUser?.biometricEnabled == true
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: authService.currentUser?.biometricEnabled == true
                    ? Colors.green
                    : Colors.grey,
              ),
              title: const Text('Biometric Login'),
              subtitle: Text(
                authService.currentUser?.biometricEnabled == true
                    ? 'Enabled'
                    : 'Disabled',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (authService.currentUser?.biometricEnabled != true)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await authService.enableBiometric();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric authentication enabled'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (authService.error != null) {
                  _showErrorSnackBar(authService.error!);
                }
              },
              child: const Text('Enable'),
            )
          else
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await authService.disableBiometric();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric authentication disabled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else if (authService.error != null) {
                  _showErrorSnackBar(authService.error!);
                }
              },
              child: const Text('Disable'),
            ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Dashboard Tab'),
    );
  }
}