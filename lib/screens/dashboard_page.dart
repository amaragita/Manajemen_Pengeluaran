import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/preferences_helper.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onLogout;
  const DashboardPage({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _username;
  static const Map<String, Color> kCategoryColors = {
    'Makanan': Color(0xFF1976D2),
    'Belanja': Color(0xFFE040FB),
    'Transport': Color(0xFFFFA000),
    'Hiburan': Color(0xFF43A047),
    'Lainnya': Color(0xFF757575),
  };

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = await PreferencesHelper.getUsername();
    setState(() {
      _username = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Utama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi keluar'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Tidak'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Ya'),
                    ),
                  ],
                ),
              );
              if (result == true) {
                widget.onLogout();
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Catatan Pengeluaran')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          // Hitung total, minggu ini, bulan ini, dan 5 terakhir
          double totalExpenses = 0;
          double weekExpenses = 0;
          double monthExpenses = 0;
          List<QueryDocumentSnapshot> recentExpenses = [];
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          final monthAgo = DateTime(now.year, now.month, 1);
          for (var doc in docs) {
            final amount = doc['amount'] is int ? (doc['amount'] as int).toDouble() : doc['amount'];
            final date = (doc['date'] as Timestamp).toDate();
            totalExpenses += amount;
            if (date.isAfter(weekAgo)) weekExpenses += amount;
            if (date.isAfter(monthAgo)) monthExpenses += amount;
          }
          recentExpenses = docs.take(5).toList();

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.account_circle, size: 40, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username != null ? 'Halo, $_username!' : 'Halo!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('Selamat datang kembali!', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Pengeluaran', style: TextStyle(fontSize: 16, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(totalExpenses),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          child: Column(
                            children: [
                              const Text('Minggu Ini', style: TextStyle(fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(weekExpenses),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: Colors.green.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          child: Column(
                            children: [
                              const Text('Bulan Ini', style: TextStyle(fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(monthExpenses),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Pengeluaran Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (recentExpenses.isEmpty)
                  const Text('Belum ada pengeluaran.', style: TextStyle(color: Colors.black54)),
                ...recentExpenses.map((doc) {
                  final amount = doc['amount'] is int ? (doc['amount'] as int).toDouble() : doc['amount'];
                  final date = (doc['date'] as Timestamp).toDate();
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: Icon(_iconForCategory(doc['category']), color: _DashboardPageState.kCategoryColors[doc['category']] ?? Colors.blue.shade400),
                      title: Text(doc['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${doc['category']} - ${DateFormat('dd/MM/yyyy').format(date)}'),
                      trailing: Text(currencyFormat.format(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Makanan':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_car;
      case 'Belanja':
        return Icons.shopping_cart;
      case 'Hiburan':
        return Icons.movie;
      case 'Lainnya':
        return Icons.more_horiz;
      default:
        return Icons.receipt_long;
    }
  }
} 