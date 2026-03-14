import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kisanbazaar/theme/app_colors.dart';
import 'package:kisanbazaar/widgets/kisan_image.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailsScreen({super.key, required this.productData});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  double get _totalPrice {
    double price = widget.productData['price'] != null 
        ? double.tryParse(widget.productData['price'].toString()) ?? 0.0 
        : 0.0;
    return price * _quantity;
  }

  void _addToCart({bool goToCart = false}) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot existing = await firestore
        .collection('cart')
        .where('buyerId', isEqualTo: userId)
        .where('productId', isEqualTo: widget.productData['productId'])
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({'quantity': (existing.docs.first['quantity'] ?? 0) + _quantity});
    } else {
      await firestore.collection('cart').add({
        'buyerId': userId, 'productId': widget.productData['productId'], 'name': widget.productData['name'], 'price': widget.productData['price'],
        'quantity': _quantity, 'unit': widget.productData['unit'], 'image': widget.productData['imageUrl'] ?? widget.productData['image'] ?? '',
        'sellerName': widget.productData['seller_name'], 'sellerId': widget.productData['sellerId'] ?? "",
      });
    }

    Fluttertoast.showToast(msg: "${widget.productData['name']} added to cart!", backgroundColor: AppColors.primary);
    if (goToCart) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.productData['name'] ?? 'Fresh Produce';
    final price = widget.productData['price']?.toString() ?? '0';
    final unit = widget.productData['unit'] ?? 'kg';
    final imageUrl = widget.productData['imageUrl'] ?? widget.productData['image'] ?? '';
    final category = widget.productData['category'] ?? 'General';
    final description = widget.productData['description'] ?? 'No description available.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 350,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.arrow_back, color: AppColors.textPrimary)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.favorite_border, color: AppColors.textPrimary)),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.share, color: AppColors.textPrimary)),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_${widget.productData['productId']}',
                child: KisanImage(
                  imageSource: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(category.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text("₹$price", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      Text(" / $unit", style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      const Text("4.8", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const Text(" (120)", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                  
                  // Farmer Card
                  const Text("Sold by", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 24, backgroundColor: AppColors.primaryLight, child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.productData['seller_name'] ?? 'Local Farmer', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              const Text("Trustworthy Seller • 2.5 km", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text("About the product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text(description, style: TextStyle(fontSize: 15, color: AppColors.textPrimary.withOpacity(0.8), height: 1.6)),
                  
                  const SizedBox(height: 120), // Bottom padding for floating bar
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        height: 110,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  IconButton(onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1), icon: const Icon(Icons.remove, color: AppColors.primary)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text("$_quantity", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
                  IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _addToCart(goToCart: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("ADD TO CART", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    Text("Total: ₹${_totalPrice.toStringAsFixed(0)}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
