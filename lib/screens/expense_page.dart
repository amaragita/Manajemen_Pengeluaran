import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

const Color kDarkBlue = Color(0xFF0D3458);
const Color kLightGrey = Color(0xFFF5F7FA);

const Map<String, Color> kCategoryColors = {
  'Makanan': Color(0xFF1976D2),
  'Belanja': Color(0xFFE040FB),
  'Transport': Color(0xFFFFA000),
  'Hiburan': Color(0xFF43A047),
  'Lainnya': Color(0xFF757575),
};

class ExpensePage extends StatefulWidget {
  const ExpensePage({Key? key}) : super(key: key);

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua', 'Makanan', 'Transport', 'Belanja', 'Hiburan', 'Lainnya'
  ];

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Pengeluaran'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            color: kLightGrey,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final bool selected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      selectedColor: kDarkBlue,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : kDarkBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Catatan Pengeluaran')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada pengeluaran.'));
                }
                final docs = snapshot.data!.docs.where((doc) {
                  if (_selectedCategory == 'Semua') return true;
                  return doc['category'] == _selectedCategory;
                }).toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('Belum ada pengeluaran untuk kategori ini.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final amount = doc['amount'] is int ? (doc['amount'] as int).toDouble() : doc['amount'];
                    final date = (doc['date'] as Timestamp).toDate();
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              _iconForCategory(doc['category']),
                              color: kCategoryColors[doc['category']] ?? kDarkBlue,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['description'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${doc['category']} - ${DateFormat('dd/MM/yyyy').format(date)}',
                                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(amount),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: kDarkBlue, fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () async {
                                        await _editExpense(doc);
                                      },
                                      tooltip: 'Edit',
                                      color: kDarkBlue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('Catatan Pengeluaran')
                                            .doc(doc.id)
                                            .delete();
                                      },
                                      tooltip: 'Hapus',
                                      color: kDarkBlue,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
        backgroundColor: kDarkBlue,
        foregroundColor: Colors.white,
        tooltip: 'Tambah Catatan Pengeluaran',
      ),
    );
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
    // Tidak perlu reload manual, StreamBuilder akan update otomatis
  }

  Future<void> _editExpense(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final expense = AddExpenseScreen(
      expense: Expense(
        id: data['id'],
        description: data['description'],
        amount: data['amount'] is int ? (data['amount'] as int).toDouble() : data['amount'],
        date: (data['date'] as Timestamp).toDate(),
        category: data['category'],
      ),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => expense),
    );
    // Tidak perlu reload manual, StreamBuilder akan update otomatis
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