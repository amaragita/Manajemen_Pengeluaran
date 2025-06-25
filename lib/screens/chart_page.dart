import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const Map<String, Color> kCategoryColors = {
  'Makanan': Color(0xFF1976D2),
  'Belanja': Color(0xFFE040FB),
  'Transport': Color(0xFFFFA000),
  'Hiburan': Color(0xFF43A047),
  'Lainnya': Color(0xFF757575),
};

class ChartPage extends StatefulWidget {
  const ChartPage({Key? key}) : super(key: key);

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  int _selectedMonth = 1; // 1 = Januari
  final int _selectedYear = 2025;

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth < 1) _selectedMonth = 1;
      if (_selectedMonth > 12) _selectedMonth = 12;
    });
  }

  String get _monthName {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[_selectedMonth];
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafik Pengeluaran'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Catatan Pengeluaran')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          Map<String, double> categoryTotals = {};
          double total = 0;
          for (var doc in docs) {
            final date = (doc['date'] as Timestamp).toDate();
            if (date.year == _selectedYear && date.month == _selectedMonth) {
              final amount = doc['amount'] is int ? (doc['amount'] as int).toDouble() : doc['amount'];
              categoryTotals[doc['category']] = (categoryTotals[doc['category']] ?? 0) + amount;
              total += amount;
            }
          }
          if (total == 0) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                _buildMonthSelector(),
                const SizedBox(height: 24),
                const Center(child: Text('Belum ada data pengeluaran.')),
              ],
            );
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              _buildMonthSelector(),
              const SizedBox(height: 24),
              SizedBox(
                height: 240,
                child: PieChart(
                  PieChartData(
                    sections: categoryTotals.entries.map((entry) {
                      final color = kCategoryColors[entry.key] ?? Colors.grey;
                      final percent = (entry.value / total * 100).toStringAsFixed(0);
                      return PieChartSectionData(
                        color: color,
                        value: entry.value,
                        title: '$percent%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      );
                    }).toList(),
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currencyFormat.format(total),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...categoryTotals.entries.map((entry) {
                final color = kCategoryColors[entry.key] ?? Colors.grey;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                  child: Row(
                    children: [
                      Container(width: 18, height: 18, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text(currencyFormat.format(entry.value)),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _selectedMonth > 1 ? () => _changeMonth(-1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '$_monthName $_selectedYear',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _selectedMonth < 12 ? () => _changeMonth(1) : null,
        ),
      ],
    );
  }
} 