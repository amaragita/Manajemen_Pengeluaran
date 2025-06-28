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

  void _showEditDialog() async {
    final usernameController = TextEditingController(text: _username ?? '');
    final passwordController = TextEditingController();
    final currentPassword = await PreferencesHelper.getPassword() ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  hintText: currentPassword.isNotEmpty ? 'Biarkan kosong jika tidak ingin mengubah' : null,
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                final newPassword = passwordController.text.trim();
                if (newUsername.isEmpty) return;
                await PreferencesHelper.saveUsername(newUsername);
                if (newPassword.isNotEmpty) {
                  await PreferencesHelper.savePassword(newPassword);
                }
                setState(() {
                  _username = newUsername;
                });
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui!')),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 56),
            // Header dengan icon orang dan info pengguna
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.person, size: 60, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _username ?? 'User',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Tombol edit username & password
                    TextButton.icon(
                      onPressed: _showEditDialog,
                      icon: Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                      label: Text('Edit Profil', style: TextStyle(color: theme.colorScheme.primary)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pengguna Aplikasi',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 70),
            // Statistik Pengeluaran
            Text(
              'Statistik Pengeluaran',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.monetization_on,
                    label: 'Total Pengeluaran',
                    value: _totalExpenses,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.receipt_long,
                    label: 'Jumlah Catatan',
                    value: _totalNotes,
                    isInt: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Tombol Logout
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 