import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

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
      _imagePath = widget.expense!.imagePath;
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
      String? imageUrl;
      if (_imagePath != null) {
        if (_imagePath!.startsWith('http')) {
          // Sudah berupa URL, tidak perlu upload ulang
          imageUrl = _imagePath;
        } else {
          // Path lokal, upload ke Imgur
          imageUrl = await _uploadImageToImgur(_imagePath!);
        }
      }

      final expense = Expense(
        id: widget.expense?.id,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', '')),
        date: _selectedDate,
        category: _selectedCategory,
        imagePath: imageUrl,
      );

      if (widget.expense == null) {
        int newId = await DatabaseHelper.instance.insertExpense(expense);
        await FirebaseFirestore.instance.collection('Catatan Pengeluaran').add({
          'id': newId,
          'description': expense.description,
          'amount': expense.amount,
          'date': Timestamp.fromDate(expense.date),
          'category': expense.category,
          'imagePath': expense.imagePath,
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
            'imagePath': expense.imagePath,
          });
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _takePicture() async {
    // Request camera permission
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin kamera diperlukan untuk mengambil foto')),
        );
        return;
      }
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        setState(() {
          _imagePath = photo.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil foto: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih gambar: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImageToImgur(String imagePath) async {
    const clientId = 'ce914dbe81f558a';
    final url = Uri.parse('https://api.imgur.com/3/image');
    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Client-ID $clientId',
      },
      body: {
        'image': base64Image,
        'type': 'base64',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['link'];
    } else {
      print('Imgur upload failed: \\${response.body}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: kDarkBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          widget.expense == null ? 'Tambah Pengeluaran' : 'Edit Pengeluaran',
          style: theme.appBarTheme.titleTextStyle?.copyWith(color: Colors.white) ?? const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _descriptionController,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          labelStyle: theme.textTheme.bodyMedium,
                          prefixIcon: Icon(Icons.description, color: theme.colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor ?? (isDark ? theme.cardColor : Colors.white),
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
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Jumlah (Rp)',
                          labelStyle: theme.textTheme.bodyMedium,
                          prefixIcon: Icon(Icons.attach_money, color: theme.colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor ?? (isDark ? theme.cardColor : Colors.white),
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
                            labelStyle: theme.textTheme.bodyMedium,
                            prefixIcon: Icon(Icons.date_range, color: theme.colorScheme.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor ?? (isDark ? theme.cardColor : Colors.white),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: theme.textTheme.bodyLarge),
                              Icon(Icons.edit_calendar, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        style: theme.textTheme.bodyLarge,
                        dropdownColor: theme.cardColor,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          labelStyle: theme.textTheme.bodyMedium,
                          prefixIcon: Icon(Icons.category, color: theme.colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor ?? (isDark ? theme.cardColor : Colors.white),
                        ),
                        items: _categories.map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category, style: theme.textTheme.bodyLarge),
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
                      const SizedBox(height: 18),
                      // Image Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foto Bukti Pengeluaran',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(height: 8),
                          if (_imagePath != null && _imagePath!.isNotEmpty)
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.primary),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _imagePath!.startsWith('http')
                                    ? Image.network(
                                        _imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 48, color: theme.colorScheme.primary)),
                                      )
                                    : Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 48, color: theme.colorScheme.primary)),
                                      ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showImageSourceDialog,
                                  icon: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
                                  label: Text(
                                    'Ambil Foto',
                                    style: TextStyle(color: theme.colorScheme.primary),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: theme.colorScheme.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: theme.inputDecorationTheme.fillColor ?? (isDark ? theme.cardColor : Colors.white),
                                  ),
                                ),
                              ),
                              if (_imagePath != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _imagePath = null;
                                    });
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saveExpense,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            side: BorderSide(color: theme.colorScheme.primary, width: 2),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            widget.expense == null ? 'Tambah Pengeluaran' : 'Simpan Perubahan',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary),
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