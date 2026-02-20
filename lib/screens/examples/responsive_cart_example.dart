import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/screens/buyer/checkout_screen.dart';
import 'package:kisanbazaar/theme/app_responsive.dart';
import 'package:kisanbazaar/theme/app_colors.dart';
import 'package:kisanbazaar/theme/app_text_styles.dart';
import 'package:kisanbazaar/theme/app_decorations.dart';

/// RESPONSIVE CART SCREEN EXAMPLE
/// This demonstrates how to use responsive design in KisanBazaar
class ResponsiveCartExample extends StatefulWidget {
  const ResponsiveCartExample({super.key});

  @override
  State<ResponsiveCartExample> createState() => _ResponsiveCartExampleState();
}

class _ResponsiveCartExampleState extends State<ResponsiveCartExample> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  void _removeFromCart(String cartItemId) async {
    await FirebaseFirestore.instance
        .collection('cart')
        .doc(cartItemId)
        .delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item removed from cart!")),
    );
  }

  double _calculateTotal(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      total += (data['price'] ?? 0) * (data['quantity'] ?? 1);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
        // Responsive actions based on screen size
        actions: [
          if (AppResponsive.isDesktop(context)) ...[
            TextButton.icon(
              icon: const Icon(Icons.shopping_bag, color: Colors.white),
              label: const Text(
                'Continue Shopping',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      // SafeArea prevents content from being hidden by notch/status bar
      body: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('cart')
              .where('buyerId', isEqualTo: userId)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyCart();
            }

            var cartItems = snapshot.data!.docs;
            double totalPrice = _calculateTotal(cartItems);

            // Responsive layout: different layouts for mobile vs desktop
            return ResponsiveLayout(
              mobile: _buildMobileLayout(cartItems, totalPrice),
              tablet: _buildTabletLayout(cartItems, totalPrice),
              desktop: _buildDesktopLayout(cartItems, totalPrice),
            );
          },
        ),
      ),
    );
  }

  /// Empty cart state
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: AppResponsive.responsiveValue(
              context,
              mobile: 100.0,
              tablet: 120.0,
              desktop: 150.0,
            ),
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Your cart is empty!',
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: AppResponsive.fontSize(context, 24),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  /// Mobile layout - single column
  Widget _buildMobileLayout(
    List<QueryDocumentSnapshot> cartItems,
    double totalPrice,
  ) {
    return Column(
      children: [
        // Cart items list - takes remaining space
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.allPadding(context),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              return _buildMobileCartItem(cartItems[index]);
            },
          ),
        ),
        // Bottom checkout section
        _buildCheckoutSection(totalPrice, cartItems),
      ],
    );
  }

  /// Tablet layout - similar to mobile but with more spacing
  Widget _buildTabletLayout(
    List<QueryDocumentSnapshot> cartItems,
    double totalPrice,
  ) {
    return Column(
      children: [
        Expanded(
          child: CenteredContent(
            maxWidth: 800,
            child: ListView.builder(
              padding: AppSpacing.allPadding(context),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return _buildTabletCartItem(cartItems[index]);
              },
            ),
          ),
        ),
        CenteredContent(
          maxWidth: 800,
          child: _buildCheckoutSection(totalPrice, cartItems),
        ),
      ],
    );
  }

  /// Desktop layout - two column (cart items + summary sidebar)
  Widget _buildDesktopLayout(
    List<QueryDocumentSnapshot> cartItems,
    double totalPrice,
  ) {
    return CenteredContent(
      maxWidth: 1200,
      child: Padding(
        padding: AppSpacing.allPadding(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Cart items (takes 2/3 of space)
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  return _buildDesktopCartItem(cartItems[index]);
                },
              ),
            ),
            SizedBox(width: AppSpacing.xl),
            // Right side - Order summary (takes 1/3 of space)
            Flexible(
              flex: 1,
              child: _buildOrderSummaryCard(totalPrice, cartItems),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile cart item card
  Widget _buildMobileCartItem(QueryDocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            // Product image - 20% of screen width
            ResponsiveContainer(
              widthPercent: 20,
              decoration: AppDecorations.cardDecoration,
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: AppDecorations.radiusSmall,
                  child: _buildProductImage(data['image']),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            // Product details - takes remaining space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? "No Name",
                    style: AppTextStyles.productName.copyWith(
                      fontSize: AppResponsive.fontSize(context, 16),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    "₹${data['price']}",
                    style: AppTextStyles.price.copyWith(
                      fontSize: AppResponsive.fontSize(context, 16),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    "Qty: ${data['quantity']} kg",
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _removeFromCart(doc.id),
            ),
          ],
        ),
      ),
    );
  }

  /// Tablet cart item card (larger with more details)
  Widget _buildTabletCartItem(QueryDocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Product image - fixed size
            Container(
              width: 100,
              height: 100,
              decoration: AppDecorations.cardDecoration,
              child: ClipRRect(
                borderRadius: AppDecorations.radiusMedium,
                child: _buildProductImage(data['image']),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? "No Name",
                    style: AppTextStyles.productName.copyWith(
                      fontSize: AppResponsive.fontSize(context, 18),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text("Price: ", style: AppTextStyles.bodyMedium),
                      Text(
                        "₹${data['price']}",
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    "Quantity: ${data['quantity']} kg",
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              iconSize: 28,
              onPressed: () => _removeFromCart(doc.id),
            ),
          ],
        ),
      ),
    );
  }

  /// Desktop cart item card (full details)
  Widget _buildDesktopCartItem(QueryDocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Product image
            Container(
              width: 120,
              height: 120,
              decoration: AppDecorations.cardDecoration,
              child: ClipRRect(
                borderRadius: AppDecorations.radiusMedium,
                child: _buildProductImage(data['image']),
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            // Product details - takes most space
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? "No Name",
                    style: AppTextStyles.headlineSmall,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    "Quantity: ${data['quantity']} kg",
                    style: AppTextStyles.bodyLarge,
                  ),
                ],
              ),
            ),
            // Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Price", style: AppTextStyles.labelMedium),
                  Text(
                    "₹${data['price']}",
                    style: AppTextStyles.price.copyWith(fontSize: 24),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              iconSize: 32,
              onPressed: () => _removeFromCart(doc.id),
            ),
          ],
        ),
      ),
    );
  }

  /// Product image widget
  Widget _buildProductImage(String? imageData) {
    if (imageData != null && imageData.isNotEmpty) {
      return Image.memory(
        base64Decode(imageData),
        fit: BoxFit.cover,
      );
    }
    return Container(
      color: AppColors.background,
      child: const Icon(
        Icons.image,
        size: 40,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Checkout section (mobile/tablet)
  Widget _buildCheckoutSection(
    double totalPrice,
    List<QueryDocumentSnapshot> cartItems,
  ) {
    return Container(
      padding: AppSpacing.allPadding(context),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: const [AppDecorations.shadowLarge],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total:", style: AppTextStyles.titleLarge),
              Text(
                "₹${totalPrice.toStringAsFixed(2)}",
                style: AppTextStyles.price.copyWith(fontSize: 24),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Full width button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _navigateToCheckout(cartItems, totalPrice),
              child: const Text("Proceed to Checkout"),
            ),
          ),
        ],
      ),
    );
  }

  /// Order summary card (desktop)
  Widget _buildOrderSummaryCard(
    double totalPrice,
    List<QueryDocumentSnapshot> cartItems,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order Summary", style: AppTextStyles.headlineSmall),
            SizedBox(height: AppSpacing.lg),
            _buildSummaryRow("Items", "${cartItems.length}"),
            SizedBox(height: AppSpacing.sm),
            _buildSummaryRow("Subtotal", "₹${totalPrice.toStringAsFixed(2)}"),
            SizedBox(height: AppSpacing.sm),
            _buildSummaryRow("Delivery", "Free"),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total", style: AppTextStyles.titleLarge),
                Text(
                  "₹${totalPrice.toStringAsFixed(2)}",
                  style: AppTextStyles.price.copyWith(fontSize: 24),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _navigateToCheckout(cartItems, totalPrice),
                child: const Text("Checkout"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyLarge),
        Text(value, style: AppTextStyles.bodyLarge),
      ],
    );
  }

  void _navigateToCheckout(
    List<QueryDocumentSnapshot> cartItems,
    double totalPrice,
  ) {
    List<Map<String, dynamic>> cartData = cartItems.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        'productId': doc.id,
        'name': data['name'],
        'price': data['price'],
        'quantity': data['quantity'],
        'sellerId': data['sellerId'],
        'image': data['image'],
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: cartData,
          totalAmount: totalPrice,
        ),
      ),
    );
  }
}
