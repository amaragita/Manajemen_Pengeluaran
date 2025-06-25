import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kDarkBlue = Color(0xFF0D3458);

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late DateTime _selectedDate;
  String _selectedCategory = 'Makanan';

  final List<String> _categories = [
    'Makanan',
    'Transport',
    'Belanja',
    'Hiburan',
    'Lainnya'
  ];

  final NumberFormat _thousandFormat = NumberFormat.decimalPattern('id_ID');

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _descriptionController.text = widget.expense!.description;
      _amountController.text = _thousandFormat.format(widget.expense!.amount);
      _selectedDate = widget.expense!.date;
      _selectedCategory = widget.expense!.category;
    } else {
      _selectedDate = DateTime.now();
    }
    _amountController.addListener(_formatAmountInput);
  }

  void _formatAmountInput() {
    String text = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    if (text.isEmpty) return;
    final value = int.tryParse(text);
    if (value == null) return;
    final newText = _thousandFormat.format(value);
    if (_amountController.text != newText) {
      final selectionIndex = newText.length - (_amountController.text.length - _amountController.selection.end);
      _amountController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selectionIndex < 0 ? 0 : selectionIndex),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kDarkBlue,
              onPrimary: Colors.white,
              onSurface: kDarkBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.expense?.id,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', '')),
        date: _selectedDate,
        category: _selectedCategory,
      );

      if (widget.expense == null) {
        int newId = await DatabaseHelper.instance.insertExpense(expense);
        await FirebaseFirestore.instance.collection('Catatan Pengeluaran').add({
          'id': newId,
          'description': expense.description,
          'amount': expense.amount,
          'date': Timestamp.fromDate(expense.date),
          'category': expense.category,
        });
      } else {
        await DatabaseHelper.instance.updateExpense(expense);
        final query = await FirebaseFirestore.instance
            .collection('Catatan Pengeluaran')
            .where('id', isEqualTo: expense.id)
            .get();
        if (query.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('Catatan Pengeluaran')
              .doc(query.docs.first.id)
              .update({
            'id': expense.id,
            'description': expense.description,
            'amount': expense.amount,
            'date': Timestamp.fromDate(expense.date),
            'category': expense.category,
          });
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkBlue),
        title: Text(
          widget.expense == null ? 'Tambah Pengeluaran' : 'Edit Pengeluaran',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          prefixIcon: const Icon(Icons.description, color: kDarkBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mohon masukkan deskripsi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Jumlah (Rp)',
                          prefixIcon: const Icon(Icons.attach_money, color: kDarkBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mohon masukkan jumlah';
                          }
                          final plain = value.replaceAll('.', '').replaceAll(',', '');
                          if (double.tryParse(plain) == null) {
                            return 'Mohon masukkan angka yang valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal',
                            prefixIcon: const Icon(Icons.date_range, color: kDarkBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                              const Icon(Icons.edit_calendar, color: kDarkBlue),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: const Icon(Icons.category, color: kDarkBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _categories.map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saveExpense,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kDarkBlue,
                            side: const BorderSide(color: kDarkBlue, width: 2),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            widget.expense == null ? 'Tambah Pengeluaran' : 'Simpan Perubahan',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kDarkBlue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 