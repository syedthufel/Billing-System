import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class TallyScreen extends StatefulWidget {
  @override
  _TallyScreenState createState() => _TallyScreenState();
}

class _TallyScreenState extends State<TallyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _topCustomers = [];
  Map<String, dynamic>? _gstReport;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTallyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTallyData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final today = DateTime.now();
      final firstDayOfMonth = DateTime(today.year, today.month, 1);
      final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);

      final [dashboardData, topCustomers, gstReport] = await Future.wait([
        ApiService.getDashboardData(),
        ApiService.getTopCustomers(10),
        ApiService.getGSTReport(
          firstDayOfMonth.toIso8601String().split('T')[0],
          lastDayOfMonth.toIso8601String().split('T')[0],
        ),
      ]);

      setState(() {
        _dashboardData = dashboardData;
        _topCustomers = List<Map<String, dynamic>>.from(topCustomers['topCustomers']);
        _gstReport = gstReport;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load tally data: $e');
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
        title: const Text('Tally & Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'GST Report'),
            Tab(text: 'Customers'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSalesTab(),
                _buildGSTTab(),
                _buildCustomersTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadTallyData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_dashboardData != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      'Today',
                      '₹${_dashboardData!['today']['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                      '${_dashboardData!['today']['totalInvoices'] ?? 0} invoices',
                      Icons.today,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
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
                    child: _buildOverviewCard(
                      'This Year',
                      '₹${_dashboardData!['thisYear']['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                      '${_dashboardData!['thisYear']['totalInvoices'] ?? 0} invoices',
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      'GST Today',
                      '₹${_dashboardData!['today']['totalGST']?.toStringAsFixed(2) ?? '0.00'}',
                      'Collected',
                      Icons.account_balance,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Sales Trend Chart (Placeholder)
            Text(
              'Sales Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 3),
                        FlSpot(1, 4),
                        FlSpot(2, 3.5),
                        FlSpot(3, 5),
                        FlSpot(4, 4),
                        FlSpot(5, 6),
                        FlSpot(6, 5.5),
                      ],
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Detailed Sales Reports'),
          Text('Feature coming soon...'),
        ],
      ),
    );
  }

  Widget _buildGSTTab() {
    return RefreshIndicator(
      onRefresh: _loadTallyData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GST Summary (This Month)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_gstReport != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGSTRow(
                        'Total GST Collected',
                        '₹${_gstReport!['summary']['totalGSTCollected']?.toStringAsFixed(2) ?? '0.00'}',
                        true,
                      ),
                      const Divider(),
                      _buildGSTRow(
                        'Total Taxable Amount',
                        '₹${_gstReport!['summary']['totalTaxableAmount']?.toStringAsFixed(2) ?? '0.00'}',
                        false,
                      ),
                      const Divider(),
                      _buildGSTRow(
                        'Total Invoices',
                        '${_gstReport!['summary']['totalInvoices'] ?? 0}',
                        false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              if (_gstReport!['gstBreakdown'] != null && 
                  (_gstReport!['gstBreakdown'] as List).isNotEmpty) ...[
                Text(
                  'GST Rate Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...((_gstReport!['gstBreakdown'] as List).map<Widget>((breakdown) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          '${breakdown['_id']}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text('GST Rate: ${breakdown['_id']}%'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Taxable: ₹${breakdown['totalTaxableAmount']?.toStringAsFixed(2) ?? '0.00'}'),
                          Text('GST: ₹${breakdown['totalGSTAmount']?.toStringAsFixed(2) ?? '0.00'}'),
                        ],
                      ),
                      trailing: Text(
                        '${breakdown['totalTransactions']} items',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                }).toList()),
              ],
            ] else ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No GST data available'),
                        Text('Create some invoices to see GST reports'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersTab() {
    return RefreshIndicator(
      onRefresh: _loadTallyData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Top Customers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _topCustomers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No customer data available'),
                        Text('Create some invoices to see top customers'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _topCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _topCustomers[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(customer['_id']['name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone: ${customer['_id']['phone'] ?? 'N/A'}'),
                              Text('Invoices: ${customer['totalInvoices'] ?? 0}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${customer['totalPurchases']?.toStringAsFixed(2) ?? '0.00'}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Text(
                                'Avg: ₹${customer['averagePurchase']?.toStringAsFixed(2) ?? '0.00'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    String title, 
    String value, 
    String subtitle, 
    IconData icon, 
    Color color
  ) {
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildGSTRow(String label, String value, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}