import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/theme/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = "Cash on Delivery";
  String _selectedAddress = "Home";
  bool _isLoading = false;
  String _userAddress = "Loading address...";
  String _userPhone = "";

  @override
  void initState() {
    super.initState();
    _fetchUserAddress();
  }

  Future<void> _fetchUserAddress() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists && mounted) {
          final data = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            _userAddress = data?['address'] ?? 'No address set. Please update in profile.';
            _userPhone = data?['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
      if (mounted) {
        setState(() {
          _userAddress = 'Could not load address';
        });
      }
    }
  }

  Future<void> placeOrder() async {
    if (widget.totalAmount <= 0) return;
    setState(() => _isLoading = true);

    // Payment gateway integration has been removed.
    // All orders will be processed as Cash on Delivery.
    await _processOrder();
  }

  Future<void> _processOrder() async {
    setState(() => _isLoading = true);
    try {
      String? buyerId = FirebaseAuth.instance.currentUser?.uid;
      if (buyerId == null) throw Exception("User not logged in");

      FirebaseFirestore firestore = FirebaseFirestore.instance;

      for (var item in widget.cartItems) {
        String productId = item['productId'];
        String sellerId = item['sellerId'] ?? "";
        String productName = item['name'];
        int orderedQuantity = item['quantity'];
        double price = double.tryParse(item['price'].toString()) ?? 0.0;

        var retry2 = retry(() async {
          return await firestore.collection("products").doc(productId).get();
        });
        DocumentSnapshot productSnapshot = await retry2;

        if (!productSnapshot.exists) {
          // Product missing – still record the order with a placeholder so the flow continues
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Product not found: $productName. Recording as unavailable."), backgroundColor: Colors.orange),
          );
          // Create a minimal order entry using placeholder data
          final placeholderOrder = {
            "buyerId": buyerId,
            "sellerId": sellerId,
            "productId": productId,
            "productName": "$productName (Unavailable)",
            "quantity": orderedQuantity,
            "totalAmount": price * orderedQuantity,
            "total": price * orderedQuantity, // for seller dashboard
            "paymentMethod": _selectedPaymentMethod,
            "deliveryAddress": _userAddress + (_userPhone.isNotEmpty ? '\n$_userPhone' : ''),
            "status": "pending", // lowercase for seller dashboard
            "image": item['imageUrl'] ?? item['image'] ?? '',
            "imageUrl": item['imageUrl'] ?? item['image'] ?? '',
            "timestamp": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp(), // for seller dashboard
            "orderDate": FieldValue.serverTimestamp(),
          };
          await retry(() async {
            await firestore.collection("orders").add(placeholderOrder);
          });
          // Skip stock update but continue to cart cleanup
          continue;
        }

        Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;
        int currentStock = productData['quantity'] ?? 0;

        if (currentStock < orderedQuantity) {
          throw Exception("Not enough stock available for $productName");
        }

        int updatedStock = currentStock - orderedQuantity;
        bool isAvailable = updatedStock > 0;

        try {
          await firestore.collection("products").doc(productId).update({
            "quantity": updatedStock,
            "isAvailable": isAvailable,
          });
        } catch (e) {
          debugPrint("Ignored permission error updating product stock: $e");
        }

        Map<String, dynamic> orderData = {
          "buyerId": buyerId,
          "sellerId": sellerId,
          "productId": productId,
          "productName": productName,
          "quantity": orderedQuantity,
          "totalAmount": price * orderedQuantity,
          "total": price * orderedQuantity, // for seller dashboard
          "paymentMethod": _selectedPaymentMethod,
          "deliveryAddress": _userAddress + (_userPhone.isNotEmpty ? '\n$_userPhone' : ''),
          "status": "pending", // lowercase for seller dashboard
          "image": item['imageUrl'] ?? item['image'] ?? '',
          "imageUrl": item['imageUrl'] ?? item['image'] ?? '',
          "timestamp": FieldValue.serverTimestamp(),
          "createdAt": FieldValue.serverTimestamp(), // for seller dashboard
          "orderDate": FieldValue.serverTimestamp(),
        };

        await retry(() async {
          await firestore.collection("orders").add(orderData);
        });

        // Ensure cart is cleared regardless of product availability
        QuerySnapshot cartSnapshot = await firestore.collection("cart").where("buyerId", isEqualTo: buyerId).get();
        for (var doc in cartSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text("Order Confirmed!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Thank you for supporting our local farmers.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to cart (which will be empty) or home
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text("Back to Home", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to place order: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<T> retry<T>(Future<T> Function() action, {int retries = 3}) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt >= retries) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception("Retry failed after $retries attempts");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Address
                const Text("Delivery Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _buildAddressCard("Home", _userAddress + (_userPhone.isNotEmpty ? '\n$_userPhone' : '')),
                const SizedBox(height: 24),

                // Order Summary Card
                const Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      ...widget.cartItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text("${item['quantity']}x ${item['name']}", style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500))),
                            Text("₹${(double.tryParse(item['price'].toString()) ?? 0.0) * item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )).toList(),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Subtotal"),
                          Text("₹${widget.totalAmount}"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Delivery Fee", style: TextStyle(color: AppColors.success)),
                          Text("Free", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total to Pay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("₹${widget.totalAmount}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Method
                const Text("Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _buildPaymentOption("Cash on Delivery", Icons.money),
                
                const SizedBox(height: 24),

                // Trust Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTrustIndicator(Icons.verified_user, "Secure Payment"),
                    _buildTrustIndicator(Icons.eco, "Direct from Farmer"),
                    _buildTrustIndicator(Icons.thumb_up, "Quality Assured"),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          // Bottom CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : placeOrder,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Confirm Order • ₹${widget.totalAmount}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String type, String address) {
    bool isSelected = _selectedAddress == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddress = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!, width: isSelected ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.home, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address, style: TextStyle(color: Colors.grey[600], height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPaymentOption(String name, IconData icon) {
    bool isSelected = _selectedPaymentMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 16),
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustIndicator(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
