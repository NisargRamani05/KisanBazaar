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

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  void _listenForNewProducts() {
    FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snapshot) {
      if (_isInitialLoad) {
        _isInitialLoad = false;
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            String productName = data['name'] ?? 'A new product';
            String sellerName = data['seller_name'] ?? 'A seller';
            _showNotification(productName, sellerName);
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
      if (_isInitialLoad) return; // Wait until initial data is loaded to avoid spam

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          var data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            String status = data['status'] ?? '';
            String productName = data['productName'] ?? 'Your order';
            String reason = data['cancelReason'] ?? '';

            if (status.isNotEmpty) {
               String body = 'Order status updated to ${status.toUpperCase()}';
               if ((status.toLowerCase() == 'declined' || status.toLowerCase() == 'cancelled') && reason.isNotEmpty) {
                 body += '. Reason: $reason';
               }
               _showNotification(productName, body, title: 'Order Update');
            }
          }
        }
      }
    });
  }

  Future<void> _showNotification(String titleOrProductName, String bodyOrSellerName, {String? title}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'order_updates_channel',
      'Order Updates',
      channelDescription: 'Notifications for order updates',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title ?? 'New Product!',
      body: title != null ? bodyOrSellerName : '$bodyOrSellerName has added $titleOrProductName.',
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
          if (mounted) {
            setState(() {
              _cartCount = snapshot.docs.length;
            });
          }
        });
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    int savedIndex = prefs.getInt('buyer_selectedIndex') ?? 0;

    // Validate index to prevent RangeError
    if (savedIndex >= _pages.length || savedIndex < 0) {
      savedIndex = 0;
    }

    setState(() {
      _selectedIndex = savedIndex;
    });
  }

  Future<void> _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('buyer_selectedIndex', index);
  }

  List<Widget> get _pages => [
    BuyerDashboardHome(onTabChange: _onItemTapped),
    const Center(child: Text("Categories")), // Placeholder for Categories
    const CartScreen(),
    const MyOrdersScreen(), // My Orders Screen
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _saveSelectedIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Home",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view),
                label: "Explore",
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text('$_cartCount'),
                  isLabelVisible: _cartCount > 0,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                activeIcon: Badge(
                  label: Text('$_cartCount'),
                  isLabelVisible: _cartCount > 0,
                  child: const Icon(Icons.shopping_cart),
                ),
                label: "Cart",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: "Orders",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
            elevation: 0,
            backgroundColor: Colors.white,
          ),
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
  final List<String> _categories = [
    "All",
    "Vegetables",
    "Fruits",
    "Dairy",
    "Grains",
    "Other",
  ];

  String _address = "Fetching address...";
  String _profileImage = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists && mounted) {
              setState(() {
                _address =
                    snapshot.data()?['address'] ??
                    "Add your address in profile";
                _profileImage = snapshot.data()?['image'] ?? "";
              });
            }
          });
    }
  }

  void addToCart(BuildContext context, Map<String, dynamic> productData) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Check if the product is already in the cart
    QuerySnapshot existingCartItem =
        await firestore
            .collection('cart')
            .where('buyerId', isEqualTo: userId)
            .where('productId', isEqualTo: productData['productId'])
            .get();

    if (existingCartItem.docs.isNotEmpty) {
      // If the product is already in the cart, update the quantity
      DocumentSnapshot cartItem = existingCartItem.docs.first;
      int currentQuantity = cartItem['quantity'] ?? 0;
      await cartItem.reference.update({
        'quantity': currentQuantity + 1, // Increment quantity
      });
    } else {
      await firestore.collection('cart').add({
        'buyerId': userId,
        'productId': productData['productId'],
        'name': productData['name'],
        'price': productData['price'],
        'quantity': 1,
        'unit': productData['unit'],
        'image': productData['image'],
        'sellerName': productData['seller_name'],
        'sellerId': productData['sellerId'] ?? "",
      });
    }

    Fluttertoast.showToast(
      msg: "${productData['name']} added to cart!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App Bar with Location & Profile
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Delivering to",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _address.isNotEmpty
                                    ? _address
                                    : "Select Location",
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      if (widget.onTabChange != null) {
                        widget.onTabChange!(4); // Switch to Profile tab
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                      backgroundImage:
                          _profileImage.isNotEmpty
                              ? NetworkImage(_profileImage)
                              : null,
                      child:
                          _profileImage.isEmpty
                              ? const Icon(
                                Icons.person,
                                color: AppColors.primary,
                              )
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search fresh vegetables, fruits...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: const Icon(Icons.mic, color: AppColors.primary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ),

          // Seasonal Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "SEASONAL",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Mango Season Sale!",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Up to 20% off on fresh Ratnagiri",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Center(
                        child: Text("🥭", style: TextStyle(fontSize: 60)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Categories",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // "Today's Fresh Picks" Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Fresh Picks",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "See All",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Product Grid
          StreamBuilder(
            stream:
                FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "No products available",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              // Filter products based on category
              var products =
                  snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (_selectedCategory == "All") return true;
                    return data['category'] == _selectedCategory;
                  }).toList();

              if (products.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No $_selectedCategory available",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var doc = products[index];
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    data['productId'] = doc.id;

                    return ProductCard(
                      data: data,
                      onAdd: () => addToCart(context, data),
                    );
                  }, childCount: products.length),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAdd;

  const ProductCard({super.key, required this.data, required this.onAdd});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => kisanbazaar.ProductDetailsScreen(
                    productData: widget.data,
                  ),
            ),
          );
        },
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      isHovered
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.black.withOpacity(0.05),
                  blurRadius: isHovered ? 15 : 10,
                  offset: Offset(0, isHovered ? 8 : 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Container
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child:
                            (widget.data['image'] != null &&
                                    widget.data['image'].isNotEmpty)
                                ? (widget.data['image'].startsWith('http')
                                    ? Image.network(
                                        widget.data['image'],
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.memory(
                                        base64Decode(widget.data['image']),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ))
                                : Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                ),
                      ),
                      // Distance Badge (Mock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                "2.5 km",
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Details
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data['name'] ?? "Unknown",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "By ${widget.data['seller_name'] ?? 'Farmer'}",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const Text(
                            " 4.8",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹${widget.data['price'] ?? '0'}",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "per ${widget.data['unit'] ?? 'kg'}",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              _controller.forward().then(
                                (_) => _controller.reverse(),
                              );
                              widget.onAdd();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
