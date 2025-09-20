import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyapar_app/home/invoices/invoices.dart';
import 'package:vyapar_app/home/dashboard/dashboard.dart';
import 'package:vyapar_app/home/profits/profits.dart';
import 'package:vyapar_app/home/payments/payment_management.dart';
import 'package:vyapar_app/config/session_manager.dart';

import 'account.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  String _userName = '';
  bool _isDisposed = false;

  // Create unique global keys for each tab to prevent conflicts
  final GlobalKey _dashboardKey = GlobalKey();
  final GlobalKey _invoicesKey = GlobalKey();
  final GlobalKey _paymentsKey = GlobalKey();
  final GlobalKey _profitsKey = GlobalKey();
  final GlobalKey _accountKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserName();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isDisposed) {
      _safeSetState(() {
        _loadUserName();
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadUserName() async {
    if (_isDisposed) return;

    try {
      final firstName = await SessionManager().getFirstName();
      final user = FirebaseAuth.instance.currentUser;

      _safeSetState(() {
        _userName = firstName ?? user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
      });
    } catch (e) {
      debugPrint('Error loading user name: $e');
      _safeSetState(() {
        _userName = 'User';
      });
    }
  }

  Future<void> _handleLogout() async {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                await SessionManager().clearAll();
                if (mounted && !_isDisposed) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                debugPrint('Logout error: $e');
                if (mounted && !_isDisposed) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error logging out. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return Dashboard(
          key: _dashboardKey,
          onNavigateToTab: _onItemTapped,
        );
      case 1:
        return Invoices(key: _invoicesKey);
      case 2:
        return PaymentManagement(key: _paymentsKey);
      case 3:
        return Profits(key: _profitsKey);
      case 4:
        return Account(key: _accountKey);
      default:
        return Dashboard(
          key: _dashboardKey,
          onNavigateToTab: _onItemTapped,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isDisposed) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales & Marketing',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (_userName.isNotEmpty)
              Text(
                'Welcome, $_userName',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildTabContent(0),
            _buildTabContent(1),
            _buildTabContent(2),
            _buildTabContent(3),
            _buildTabContent(4),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Invoices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              label: 'Profits',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_isDisposed || !mounted || index == _selectedIndex) return;

    try {
      _safeSetState(() {
        _selectedIndex = index;
      });
    } catch (e) {
      debugPrint('Error navigating to tab $index: $e');
    }
  }
}