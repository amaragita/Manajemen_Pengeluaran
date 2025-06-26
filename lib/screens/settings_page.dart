import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifOn = false;
  int _rating = 0;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showRatingDialog() async {
    int tempRating = _rating;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Beri Rating Aplikasi'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < tempRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                  tempRating = index + 1;
                  Navigator.of(context).pop();
                  _showSnackBar('Terima kasih atas ratingnya: ${index + 1} bintang');
                },
              );
            }),
          ),
        );
      },
    );
  }

  void _openDummyPage(String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DummyDetailPage(title: title, content: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pengaturan'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              },
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            children: [
              // Notifikasi
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Notifikasi'),
                  trailing: Switch(
                    value: _notifOn,
                    onChanged: (v) {
                      setState(() => _notifOn = v);
                      _showSnackBar(v ? 'Notifikasi diaktifkan' : 'Notifikasi dimatikan');
                    },
                  ),
                  onTap: () {
                    setState(() => _notifOn = !_notifOn);
                    _showSnackBar(_notifOn ? 'Notifikasi diaktifkan' : 'Notifikasi dimatikan');
                  },
                ),
              ),
              // Mode Gelap
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: const Text('Mode Gelap'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (v) async {
                      await themeProvider.toggleTheme();
                      _showSnackBar(
                        themeProvider.isDarkMode 
                          ? 'Mode gelap diaktifkan' 
                          : 'Mode terang diaktifkan'
                      );
                    },
                  ),
                  onTap: () async {
                    await themeProvider.toggleTheme();
                    _showSnackBar(
                      themeProvider.isDarkMode 
                        ? 'Mode gelap diaktifkan' 
                        : 'Mode terang diaktifkan'
                    );
                  },
                ),
              ),
              // Rating Bintang
              ListTile(
                leading: const Icon(Icons.star_border),
                title: const Text('Beri Rating Aplikasi'),
                trailing: const Icon(Icons.chevron_right),
                subtitle: _rating > 0
                    ? Row(
                        children: List.generate(5, (index) => Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        )),
                      )
                    : null,
                onTap: _showRatingDialog,
              ),
              // Share App
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Bagikan Aplikasi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _openDummyPage(
                    'Bagikan Aplikasi',
                    'Bagikan aplikasi ini ke teman-temanmu agar mereka juga bisa mengelola keuangan dengan mudah!\n\nFitur bagikan aplikasi akan segera tersedia.'
                  );
                },
              ),
              // Privacy Policy
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Kebijakan Privasi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _openDummyPage(
                    'Kebijakan Privasi',
                    'Kami menghargai privasi Anda.\nData pengguna hanya digunakan untuk keperluan aplikasi dan tidak dibagikan ke pihak ketiga.\n\nUntuk info lebih lanjut, silakan hubungi kami melalui menu Kontak.'
                  );
                },
              ),
              // Terms and Conditions
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Syarat & Ketentuan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _openDummyPage(
                    'Syarat & Ketentuan',
                    'Dengan menggunakan aplikasi ini, Anda setuju untuk mematuhi semua aturan yang berlaku.\n\nAplikasi ini hanya untuk penggunaan pribadi dan tidak untuk tujuan komersial tanpa izin.'
                  );
                },
              ),
              // Cookies Policy
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: const Text('Kebijakan Cookie'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _openDummyPage(
                    'Kebijakan Cookie',
                    'Aplikasi ini menggunakan cookie untuk meningkatkan pengalaman pengguna.\n\nCookie tidak digunakan untuk melacak aktivitas di luar aplikasi.'
                  );
                },
              ),
              // Contact
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Kontak'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _openDummyPage(
                    'Kontak',
                    'Hubungi kami untuk pertanyaan, bantuan, atau kerjasama:\n\nEmail: admin@manajemenkeuangan.com\nWhatsApp: 0812-3456-7890\n\nKami akan membalas secepatnya!'
                  );
                },
              ),
              // Feedback
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Masukan & Saran'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _openDummyPage(
                    'Masukan & Saran',
                    'Kami sangat menghargai masukan dan saran dari Anda!\n\nSilakan kirimkan ide, kritik, atau saran Anda melalui email ke:\nfeedback@manajemenkeuangan.com\n\nBersama kita buat aplikasi ini lebih baik!'
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class DummyDetailPage extends StatelessWidget {
  final String title;
  final String content;
  const DummyDetailPage({Key? key, required this.title, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            content,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
} 