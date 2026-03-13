import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kisanbazaar/theme/app_colors.dart';
import 'package:kisanbazaar/screens/buyer/cart_screen.dart'; // Ensure it's reachable or imported if Buy Now goes there directly

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

    // Check if the product is already in the cart
    QuerySnapshot existingCartItem = await firestore
        .collection('cart')
        .where('buyerId', isEqualTo: userId)
        .where('productId', isEqualTo: widget.productData['productId'])
        .get();

    if (existingCartItem.docs.isNotEmpty) {
      // If the product is already in the cart, update the quantity
      DocumentSnapshot cartItem = existingCartItem.docs.first;
      int currentQuantity = cartItem['quantity'] ?? 0;
      await cartItem.reference.update({
        'quantity': currentQuantity + _quantity, // Increment quantity
      });
    } else {
      await firestore.collection('cart').add({
        'buyerId': userId,
        'productId': widget.productData['productId'],
        'name': widget.productData['name'],
        'price': widget.productData['price'],
        'quantity': _quantity,
        'unit': widget.productData['unit'],
        'image': widget.productData['image'],
        'sellerName': widget.productData['seller_name'],
        'sellerId': widget.productData['sellerId'] ?? "",
      });
    }

    Fluttertoast.showToast(
      msg: "${widget.productData['name']} added to cart!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    
    if (goToCart && mounted) {
      Navigator.pop(context); // Optional: close modal/screen or go to Cart Screen
      // Ideally navigate to CartScreen here
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = widget.productData['image'] != null && widget.productData['image'].isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage 
                ? (widget.productData['image'].startsWith('http')
                    ? Image.network(widget.productData['image'], fit: BoxFit.cover)
                    : Image.memory(base64Decode(widget.productData['image']), fit: BoxFit.cover))
                : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 80, color: Colors.grey)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.productData['name'] ?? 'Unknown Product',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${widget.productData['price'] ?? '0'}",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            "per ${widget.productData['unit'] ?? 'kg'}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                    ),
                    child: Text(
                      widget.productData['category'] ?? 'Category',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Farmer Profile Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          child: const Icon(Icons.person, color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.productData['seller_name'] ?? 'Farmer Name',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text("Rajkot Area • 2.5 km away", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("View Profile", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.productData['description'] ?? "No description available for this product.",
                    style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
                  ),
                  
                  const SizedBox(height: 24),

                  // Customer Reviews Placeholder
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Customer Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          SizedBox(width: 4),
                          Text("4.8 (120 reviews)", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Mock Review
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Ramesh P.", style: TextStyle(fontWeight: FontWeight.bold)),
                            Row(
                              children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 14)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text("Very fresh quality, completely satisfied! Will definitely buy again from this farmer.", style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            // Quantity Selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: AppColors.primary),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() => _quantity--);
                      }
                    },
                  ),
                  Text("$_quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _addToCart(goToCart: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Buy Now - ₹${_totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
