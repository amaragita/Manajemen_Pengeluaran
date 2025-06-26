import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/preferences_helper.dart';
import 'package:intl/intl.dart';
import 'main_navigation.dart';

const Color kDarkBlue = Color(0xFF0D3458);

class AccountPage extends StatefulWidget {
  final VoidCallback onLogout;
  const AccountPage({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? _username;
  double _totalExpenses = 0;
  int _totalNotes = 0;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadStatsFromFirestore();
  }

  Future<void> _loadUsername() async {
    final username = await PreferencesHelper.getUsername();
    setState(() {
      _username = username;
    });
  }

  Future<void> _loadStatsFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('Catatan Pengeluaran').get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final amount = doc['amount'] is int ? (doc['amount'] as int).toDouble() : doc['amount'];
      total += amount;
    }
    setState(() {
      _totalExpenses = total;
      _totalNotes = snapshot.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.account_circle, size: 80, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                _username != null ? _username! : '-',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Nama Pengguna',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(
                    icon: Icons.monetization_on,
                    label: 'Total Pengeluaran',
                    value: _totalExpenses,
                  ),
                  _StatCard(
                    icon: Icons.receipt_long,
                    label: 'Jumlah Catatan',
                    value: _totalNotes,
                    isInt: true,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final bool isInt;
  const _StatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.isInt = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              isInt ? value.toString() : NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value),
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
} 