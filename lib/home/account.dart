import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyapar_app/config/session_manager.dart';
import 'package:vyapar_app/home/shops/shops_management.dart';
import 'package:vyapar_app/home/returns/returns_management.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> with AutomaticKeepAliveClientMixin {
  User? _currentUser;
  String _firstName = '';
  String _email = '';
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadUserData() async {
    if (_isDisposed) return;
    
    _currentUser = FirebaseAuth.instance.currentUser;
    _firstName = await SessionManager().getFirstName() ?? '';
    _email = await SessionManager().getEmail() ?? '';
    
    _safeSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isDisposed) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader()),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAccountOptions(),
                const SizedBox(height: 20),
                _buildAppInfo(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Profile Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                child: Text(
                  _getInitials(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User Name
            Text(
              _firstName.isNotEmpty ? _firstName : 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // User Email
            Text(
              _currentUser?.email ?? _email,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Edit Profile Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildOptionCard(
            'Shop Management',
            'Manage customer shops and companies',
            Icons.store_outlined,
            Colors.blue,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopsManagement(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildOptionCard(
            'Returns Management',
            'Handle product returns and stock restoration',
            Icons.assignment_return_outlined,
            Colors.orange,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReturnsManagement(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildOptionCard(
            'Backup & Sync',
            'Your data is securely stored in Firebase',
            Icons.cloud_done_outlined,
            Colors.green,
            () {
              _showFirebaseBackupDialog();
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildOptionCard(
            'Support & Help',
            'Get help and contact support',
            Icons.help_outline,
            Colors.indigo,
            () {
              _showSupportDialog();
            },
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          _buildOptionCard(
            'Logout',
            'Sign out of your account',
            Icons.logout,
            Colors.red,
            () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales & Marketing App',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              const Divider(),
              
              const SizedBox(height: 16),
              
              const Text(
                'Professional invoice management and sales tracking for your business. Built with modern technology and designed for Pakistani businesses.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _showComingSoonDialog('Privacy Policy');
                    },
                    icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                    label: const Text('Privacy'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showComingSoonDialog('Terms of Service');
                    },
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('Terms'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showSupportDialog();
                    },
                    icon: const Icon(Icons.feedback_outlined, size: 16),
                    label: const Text('Feedback'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (_firstName.isNotEmpty) {
      return _firstName.substring(0, 1).toUpperCase();
    } else if (_currentUser?.email != null) {
      return _currentUser!.email!.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to access your account.',
        ),
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
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) {
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

  void _showFirebaseBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Backup & Sync'),
        content: const Text(
          'Your data is already safely stored in Google Firebase. You don\'t need to back it up.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Coming Soon'),
        content: Text(
          '$feature feature is coming soon! We\'re working hard to bring you the best experience.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Support & Help'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need help with the app? Here are some ways to get support:'),
              SizedBox(height: 16),
              Text('• Check the in-app help sections'),
              Text('• Contact us through app feedback'),
              Text('• Visit our website for tutorials'),
              Text('• Email us for technical support'),
              SizedBox(height: 16),
              Text(
                'We\'re here to help you manage your business better!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you! We\'ll get back to you soon.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Feedback'),
          ),
        ],
      ),
    );
  }
}