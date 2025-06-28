import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

const Color kDarkBlue = Color(0xFF0D3458);

// ======================
// AddExpenseScreen
// Halaman untuk tambah/edit pengeluaran, termasuk upload foto bukti
// ======================
class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  // Konstruktor menerima data expense jika mode edit
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // Key untuk validasi form
  final _formKey = GlobalKey<FormState>();
  // Controller untuk input deskripsi
  final _descriptionController = TextEditingController();
  // Controller untuk input jumlah
  final _amountController = TextEditingController();
  // State tanggal yang dipilih
  late DateTime _selectedDate;
  // State kategori yang dipilih
  String _selectedCategory = 'Makanan';
  // Path gambar bukti (bisa lokal/file atau url)
  String? _imagePath;
  // ImagePicker untuk ambil gambar
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
    // Jika mode edit, isi field dengan data expense lama
    if (widget.expense != null) {
      _descriptionController.text = widget.expense!.description;
      _amountController.text = _thousandFormat.format(widget.expense!.amount);
      _selectedDate = widget.expense!.date;
      _selectedCategory = widget.expense!.category;
      _imagePath = widget.expense!.imagePath;
    } else {
      // Jika tambah baru, tanggal default hari ini
      _selectedDate = DateTime.now();
    }
    // Listener untuk format input jumlah
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

  //Fungsi utama untuk menyimpan pengeluaran
  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? imageUrl;
        if (_imagePath != null) {
          if (_imagePath!.startsWith('http')) {
            imageUrl = _imagePath;
          } else {
            imageUrl = await _uploadImageToImgur(_imagePath!);
          }
        }

        final expense = Expense(
          description: _descriptionController.text,
          amount: double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', '')),
          date: _selectedDate,
          category: _selectedCategory,
          imagePath: imageUrl,
        );

        if (widget.expense == null) {
          await FirebaseFirestore.instance.collection('Catatan Pengeluaran').add({
            'description': expense.description,
            'amount': expense.amount,
            'date': Timestamp.fromDate(expense.date),
            'category': expense.category,
            'imagePath': expense.imagePath,
          });
        } else {
          // Tidak ada id, update tidak bisa dilakukan dengan where('id', ...)
          // Solusi: tampilkan pesan error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit pengeluaran tidak didukung setelah penghapusan SQLite.')), 
            );
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengeluaran berhasil disimpan!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('=== ERROR: $e ===');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error menyimpan data: $e')),
          );
        }
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

  // DITAMBAHKAN: Komentar - Fungsi untuk upload gambar ke Imgur
  Future<String?> _uploadImageToImgur(String imagePath) async {
    // Ganti clientId dengan milikmu jika perlu
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
                      // ======================
                      // Input Deskripsi
                      // ======================
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
                      // ======================
                      // Input Jumlah
                      // ======================
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
                      // ======================
                      // Input Tanggal
                      // ======================
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
                      // ======================
                      // Dropdown Kategori
                      // ======================
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
                      // ======================
                      // Upload/Tampil Gambar Bukti
                      // ======================
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
                      // ======================
                      // Tombol Simpan
                      // ======================
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