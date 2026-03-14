import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/screens/buyer/checkout_screen.dart';
import 'package:kisanbazaar/theme/app_colors.dart';
import 'package:kisanbazaar/widgets/kisan_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  void _removeFromCart(String cartItemId) async {
    await FirebaseFirestore.instance.collection('cart').doc(cartItemId).delete();
  }

  void _updateQuantity(String cartItemId, int newQuantity, String productId) async {
    if (newQuantity <= 0) {
      _removeFromCart(cartItemId);
      return;
    }
    await FirebaseFirestore.instance.collection('cart').doc(cartItemId).update({'quantity': newQuantity});
  }

  double _calculateTotal(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      double itemPrice = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
      int itemQuantity = data['quantity'] ?? 1;
      total += itemPrice * itemQuantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('cart').where('buyerId', isEqualTo: userId).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

          var cartItems = snapshot.data!.docs;
          double subtotal = _calculateTotal(cartItems);
          double deliveryFee = subtotal > 500 ? 0 : 40;
          double total = subtotal + deliveryFee;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...cartItems.map((doc) => _buildCartItem(doc)),
                    const SizedBox(height: 24),
                    _buildBillDetails(subtotal, deliveryFee, total),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              _buildBottomBar(total, cartItems),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.primary.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("Your cart is empty", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text("Add items to your cart to see them here", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCartItem(QueryDocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String imageUrl = data['image'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: KisanImage(
              imageSource: imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? "Product", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text("per ${data['unit'] ?? 'kg'}", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Text("₹${data['price']}", style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
          ),
          Container(
            height: 36,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _updateQuantity(doc.id, (data['quantity'] ?? 1) - 1, data['productId']),
                  icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                  padding: EdgeInsets.zero,
                ),
                Text("${data['quantity']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => _updateQuantity(doc.id, (data['quantity'] ?? 1) + 1, data['productId']),
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(width: 70, height: 70, color: AppColors.background, child: const Icon(Icons.eco_rounded, color: AppColors.primaryLight));

  Widget _buildBillDetails(double subtotal, double delivery, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bill Details", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 16),
          _billRow("Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
          const SizedBox(height: 8),
          _billRow("Delivery Fee", delivery == 0 ? "FREE" : "₹${delivery.toStringAsFixed(0)}", isFree: delivery == 0),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          _billRow("Total Pay", "₹${total.toStringAsFixed(0)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isFree = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500, fontSize: isTotal ? 16 : 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: isTotal ? 16 : 14, color: isFree ? AppColors.primary : AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildBottomBar(double total, List<QueryDocumentSnapshot> items) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TOTAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
              Text("₹${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                List<Map<String, dynamic>> cartData = items.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return {'productId': data['productId'] ?? doc.id, 'name': data['name'], 'price': data['price'], 'quantity': data['quantity'], 'unit': data['unit'], 'sellerId': data['sellerId'], 'image': data['image'] ?? ''};
                }).toList();
                Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(cartItems: cartData, totalAmount: total)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: const Text("PROCEED TO CHECKOUT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
