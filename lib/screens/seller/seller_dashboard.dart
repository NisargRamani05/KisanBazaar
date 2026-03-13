import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kisanbazaar/screens/auth/login_screen.dart';
import 'package:kisanbazaar/screens/seller/profile_screen.dart';
import 'package:kisanbazaar/screens/seller/add_product_screen.dart';
import 'package:kisanbazaar/screens/seller/my_products_screen.dart';
import 'package:kisanbazaar/screens/seller/order_received_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisanbazaar/theme/app_colors.dart';
import 'package:kisanbazaar/screens/seller/seller_dashboard.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSelectedIndex();
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    int savedIndex = prefs.getInt('seller_selectedIndex') ?? 0;

    // Validate index (Seller dashboard has 5 tabs: 0, 1, 2, 3, 4)
    if (savedIndex > 4 || savedIndex < 0) {
      savedIndex = 0;
    }

    setState(() {
      _selectedIndex = savedIndex;
    });
  }

  Future<void> _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seller_selectedIndex', index);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _saveSelectedIndex(index);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error logging out: $e');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeScreen(),
      const MyProductsScreen(),
      const AddProductScreen(), // Handled via FAB in home, but keeping it in tabs just in case
      const OrderReceivedScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'KisanBazaar - Farmer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body:
          screens[_selectedIndex == 2
              ? 0
              : _selectedIndex], // If Add is selected, show home but it won't be since we use FAB
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddProductScreen()),
                  );
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(), // Empty space for FAB
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 2) return; // Ignore tap on empty FAB slot
            _onItemTapped(index);
          },
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, snapshot) {
              String name = "Farmer";
              if (snapshot.hasData && snapshot.data!.exists) {
                name = snapshot.data!.get('fullName') ?? "Farmer";
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "Today's Earnings",
                  value: "₹0", // Should be fetched from DB
                  icon: Icons.currency_rupee,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('orders')
                          .where('sellerId', isEqualTo: uid)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                  builder: (context, snapshot) {
                    return _buildStatCard(
                      title: "Orders Pending",
                      value:
                          snapshot.hasData
                              ? snapshot.data!.docs.length.toString()
                              : "0",
                      icon: Icons.pending_actions,
                      color: const Color(0xFFFFA000),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('products')
                    .where('sellerId', isEqualTo: uid)
                    .snapshots(),
            builder: (context, snapshot) {
              return _buildStatCard(
                title: "Active Products",
                value:
                    snapshot.hasData
                        ? snapshot.data!.docs.length.toString()
                        : "0",
                icon: Icons.inventory,
                color: const Color(0xFF2196F3),
                isFullWidth: true,
              );
            },
          ),

          const SizedBox(height: 32),

          // Recent Orders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _onItemTapped(3),
                child: const Text(
                  "View All",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('orders')
                    .where('sellerId', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final order = snapshot.data!.docs[index];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight.withOpacity(
                          0.2,
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Status: ${order['status'] ?? 'pending'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Text(
                        '₹${order['total'] ?? '0'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.list_alt, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No pending orders",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "When buyers purchase your products, they will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
