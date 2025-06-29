import 'package:flutter/material.dart';
import 'dart:async';
import 'dashboard_page.dart';
import 'chart_page.dart';
import 'expense_page.dart';
import 'account_page.dart';
import 'settings_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  Timer? _exitTimer;
  bool _isExitReady = false;
  
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  void goToDashboard() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    print('Back button pressed. Current tab: $_selectedIndex');
    
    // Jika tidak di dashboard, pindah ke dashboard
    if (_selectedIndex != 0) {
      print('Moving to dashboard from tab: $_selectedIndex');
      setState(() {
        _selectedIndex = 0;
        _isExitReady = false;
      });
      _exitTimer?.cancel();
      return false; // Jangan keluar dari aplikasi
    }
    
    // Jika sudah di dashboard, implementasi double tap to exit
    if (!_isExitReady) {
      print('First back press - showing exit message');
      setState(() {
        _isExitReady = true;
      });
      
      // Tampilkan pesan "Ketuk lagi untuk keluar"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ketuk lagi untuk keluar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      
      // Set timer untuk reset state setelah 2 detik
      _exitTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isExitReady = false;
          });
          print('Exit timer expired - reset state');
        }
      });
      
      return false; // Jangan keluar dari aplikasi
    }
    
    // Jika sudah siap untuk exit, keluar dari aplikasi
    print('Second back press - exiting app');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            Navigator(
              key: _navigatorKeys[0],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const DashboardPage(),
              ),
            ),
            Navigator(
              key: _navigatorKeys[1],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => ChartPage(),
              ),
            ),
            Navigator(
              key: _navigatorKeys[2],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => ExpensePage(),
              ),
            ),
            Navigator(
              key: _navigatorKeys[3],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const AccountPage(),
              ),
            ),
            Navigator(
              key: _navigatorKeys[4],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => SettingsPage(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
} 