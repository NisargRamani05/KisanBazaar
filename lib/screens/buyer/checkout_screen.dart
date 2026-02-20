

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  Future<void> placeOrder() async {
    try {
      String? buyerId = FirebaseAuth.instance.currentUser?.uid;
      if (buyerId == null) throw Exception("User not logged in");

      FirebaseFirestore firestore = FirebaseFirestore.instance;

      for (var item in widget.cartItems) {
        String productId = item['productId'];
        String sellerId = item['sellerId'] ?? "";
        String productName = item['name'];
        int orderedQuantity = item['quantity'];
        double price = item['price'];

        var retry2 = retry(() async {
          return await firestore.collection("products").doc(productId).get();
        });
        DocumentSnapshot productSnapshot = await retry2;

        if (!productSnapshot.exists) {
          debugPrint("Product not found for productId: $productId");
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Product not found: $productName"),
              backgroundColor: Colors.orange,
            ),
          );
          continue; // Skip this product and move to the next one
        }

        Map<String, dynamic> productData =
            productSnapshot.data() as Map<String, dynamic>;
        int currentStock = productData['quantity'] ?? 0;

        if (currentStock < orderedQuantity) {
          throw Exception("Not enough stock available for $productName");
        }

        int updatedStock = currentStock - orderedQuantity;
        bool isAvailable = updatedStock > 0;

        await firestore.collection("products").doc(productId).update({
          "quantity": updatedStock,
          "isAvailable": isAvailable,
        });

        Map<String, dynamic> orderData = {
          "buyerId": buyerId,
          "sellerId": sellerId,
          "productId": productId,
          "productName": productName,
          "quantity": orderedQuantity,
          "totalAmount": price * orderedQuantity,
          "paymentMethod": _selectedPaymentMethod,
          "status": "Pending",
          "timestamp": FieldValue.serverTimestamp(),
        };

        // Retry logic for network failures
        await retry(() async {
          await firestore
              .collection("users")
              .doc(buyerId)
              .collection("orders")
              .add(orderData);
          await firestore
              .collection("sellers")
              .doc(sellerId)
              .collection("orders")
              .add(orderData);
        });

        QuerySnapshot cartSnapshot =
            await firestore
                .collection("cart")
                .where("buyerId", isEqualTo: buyerId)
                .get();

        for (var doc in cartSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order placed successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to place order: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Retry function
  Future<T> retry<T>(Future<T> Function() action, {int retries = 3}) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt >= retries) rethrow;
        await Future.delayed(Duration(seconds: 2));
      }
    }
    throw Exception("Retry failed after $retries attempts");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  var item = widget.cartItems[index];
                  return ListTile(
                    leading:
                        item['image'] != null && item['image'].isNotEmpty
                            ? Image.memory(
                              base64Decode(item['image'].split(',').last),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : const Icon(Icons.image, size: 50),
                    title: Text(item['name']),
                    subtitle: Text(
                      "Qty: ${item['quantity']} | Price: ₹${item['price']}",
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text("Cash on Delivery"),
              leading: Radio(
                value: "Cash on Delivery",
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value.toString();
                  });
                },
              ),
            ),
            // Add more payment options here if needed
            const SizedBox(height: 10),
            Text(
              "Total: ₹${widget.totalAmount}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: placeOrder,
                child: const Text(
                  "Place Order",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// void addToCart(BuildContext context, Map<String, dynamic> productData) async {
//   String? userId = FirebaseAuth.instance.currentUser?.uid;
//   if (userId == null) return;

//   await FirebaseFirestore.instance.collection('products').add({
//     'buyerId': userId,
//     'productId': productData['productId'], // Use the correct product ID
//     'name': productData['name'],
//     'price': productData['price'],
//     'quantity': productData['quantity'], // Default quantity added to cart
//     'image': productData['image'],
//     'sellerName': productData['seller_name'],
//     'sellerId': productData['sellerId'] ?? "",
//   });

//   Fluttertoast.showToast(
//     msg: "${productData['name']} added to cart!",
//     toastLength: Toast.LENGTH_SHORT,
//     gravity: ToastGravity.BOTTOM,
//     backgroundColor: Colors.green,
//     textColor: Colors.white,
//     fontSize: 16.0,
//   );
// }
