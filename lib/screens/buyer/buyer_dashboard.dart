import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kisanbazaar/screens/auth/login_screen.dart';
import 'package:kisanbazaar/screens/buyer/profile_screen.dart';
import 'package:kisanbazaar/screens/buyer/cart_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisanbazaar/theme/app_colors.dart';
import 'package:kisanbazaar/screens/buyer/product_details_screen.dart'
    as kisanbazaar;
import 'package:kisanbazaar/screens/buyer/my_orders_screen.dart';
import 'package:kisanbazaar/widgets/modern_product_card.dart';
import 'package:kisanbazaar/widgets/modern_search_bar.dart';
import 'package:kisanbazaar/widgets/category_item.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _selectedIndex = 0;
  int _cartCount = 0;
  bool _isInitialLoad = true;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadSelectedIndex();
    _listenToCartCount();
    _initializeNotifications();
    _listenForNewProducts();
    _listenForOrderUpdates();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  void _listenForNewProducts() {
    FirebaseFirestore.instance.collection('products').snapshots().listen((snapshot) {
      if (_isInitialLoad) {
        _isInitialLoad = false;
        return;
      }
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data();
          if (data != null) {
            _showNotification(data['name'] ?? 'New Product', data['seller_name'] ?? 'A seller');
          }
        }
      }
    });
  }

  void _listenForOrderUpdates() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    FirebaseFirestore.instance
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (_isInitialLoad) return;
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          var data = change.doc.data();
          if (data != null) {
            String status = data['status'] ?? '';
            _showNotification(data['productName'] ?? 'Order Update', 'Status: ${status.toUpperCase()}', title: 'Order Update');
          }
        }
      }
    });
  }

  Future<void> _showNotification(String titleOrProductName, String bodyOrSellerName, {String? title}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'order_updates_channel', 'Order Updates', importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title ?? 'New Product!',
      body: title != null ? bodyOrSellerName : '$bodyOrSellerName added $titleOrProductName.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  void _listenToCartCount() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    FirebaseFirestore.instance
        .collection('cart')
        .where('buyerId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) setState(() => _cartCount = snapshot.docs.length);
    });
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedIndex = (prefs.getInt('buyer_selectedIndex') ?? 0).clamp(0, 4));
  }

  void _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('buyer_selectedIndex', index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          BuyerDashboardHome(onTabChange: _onItemTapped),
          const Center(child: Text("Explore Categories")),
          const CartScreen(),
          const MyOrdersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, "Home"),
                _buildNavItem(1, Icons.grid_view_rounded, "Explore"),
                _buildCartNavItem(2),
                _buildNavItem(3, Icons.receipt_long_rounded, "Orders"),
                _buildNavItem(4, Icons.person_rounded, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartNavItem(int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              label: Text('$_cartCount'),
              isLabelVisible: _cartCount > 0,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.shopping_cart_rounded, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
            ),
            const SizedBox(height: 4),
            Text("Cart", style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class BuyerDashboardHome extends StatefulWidget {
  final Function(int)? onTabChange;
  const BuyerDashboardHome({super.key, this.onTabChange});

  @override
  State<BuyerDashboardHome> createState() => _BuyerDashboardHomeState();
}

class _BuyerDashboardHomeState extends State<BuyerDashboardHome> {
  String _selectedCategory = "All";
  final List<Map<String, String>> _categories = [
    {"title": "All", "emoji": "🍱"},
    {"title": "Vegetables", "emoji": "🥦"},
    {"title": "Fruits", "emoji": "🍎"},
    {"title": "Dairy", "emoji": "🥛"},
    {"title": "Grains", "emoji": "🌾"},
    {"title": "Other", "emoji": "✨"},
  ];

  String _address = "Fetching address...";
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      FirebaseFirestore.instance.collection('users').doc(userId).snapshots().listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _address = snapshot.data()?['address'] ?? "Add your address in profile";
            _userName = snapshot.data()?['name'] ?? "User";
          });
        }
      });
    }
  }

  void addToCart(Map<String, dynamic> productData) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot existing = await firestore.collection('cart').where('buyerId', isEqualTo: userId).where('productId', isEqualTo: productData['productId']).get();
    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({'quantity': (existing.docs.first['quantity'] ?? 0) + 1});
    } else {
      await firestore.collection('cart').add({
        'buyerId': userId, 'productId': productData['productId'], 'name': productData['name'], 'price': productData['price'], 'quantity': 1, 'unit': productData['unit'],
        'image': productData['imageUrl'] ?? productData['image'] ?? '', 'sellerName': productData['seller_name'], 'sellerId': productData['sellerId'] ?? "",
      });
    }
    Fluttertoast.showToast(msg: "${productData['name']} added to cart!", backgroundColor: AppColors.primary);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
          backgroundColor: AppColors.surface,
          scrolledUnderElevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Freshly Picked for", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 4),
                            Flexible(child: Text(_address, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onTabChange?.call(4),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2)),
                      child: const CircleAvatar(backgroundColor: AppColors.lightGreenBg, child: Icon(Icons.person_outline_rounded, color: AppColors.primary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Sticky Search Bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _SearchBarDelegate(),
        ),

        // Promo Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Stack(
                children: [
                  Positioned(right: -20, bottom: -20, child: Opacity(opacity: 0.2, child: Icon(Icons.eco_rounded, size: 150, color: AppColors.primary))),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                          child: const Text("FARM FRESH", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 12),
                        const Text("20% Cash Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                        const Text("on your first organic order", style: TextStyle(fontSize: 14, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Categories Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Shop by Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                TextButton(onPressed: () {}, child: const Text("See All", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),

        // Categories List
        SliverToBoxAdapter(
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return CategoryItem(
                  title: cat['title']!,
                  emoji: cat['emoji']!,
                  isSelected: _selectedCategory == cat['title'],
                  onTap: () => setState(() => _selectedCategory = cat['title']!),
                );
              },
            ),
          ),
        ),

        // Products Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Text("Bestsellers in $_selectedCategory", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ),

        // Product Grid
        StreamBuilder(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
            var products = snapshot.data!.docs.where((doc) {
              if (_selectedCategory == "All") return true;
              return doc['category'] == _selectedCategory;
            }).toList();

            if (products.isEmpty) {
              return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40.0), child: Text("No products found in $_selectedCategory"))));
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    var data = products[index].data();
                    data['productId'] = products[index].id;
                    return ModernProductCard(data: data, onAdd: () => addToCart(data), index: index);
                  },
                  childCount: products.length,
                ),
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const ModernSearchBar(),
    );
  }

  @override
  double get maxExtent => 70;
  @override
  double get minExtent => 70;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
