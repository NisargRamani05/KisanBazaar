import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderReceivedScreen extends StatefulWidget {
  const OrderReceivedScreen({super.key});

  @override
  State<OrderReceivedScreen> createState() => _OrderReceivedScreenState();
}

class _OrderReceivedScreenState extends State<OrderReceivedScreen> {
  String? sellerId = FirebaseAuth.instance.currentUser?.uid;

  void _updateOrderStatus(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection("sellers")
          .doc(sellerId)
          .collection("orders")
          .doc(orderId)
          .update({"status": "Success"});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order status updated to Success!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orders Received")),
      body:
          sellerId == null
              ? const Center(child: Text("User not authenticated"))
              : StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection("sellers")
                        .doc(sellerId)
                        .collection("orders")
                        .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No orders received yet"));
                  }

                  var orders = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var doc = orders[index];
                      var order = doc.data() as Map<String, dynamic>;

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection("users")
                                .doc(order['buyerId'])
                                .get(),
                        builder: (context, buyerSnapshot) {
                          if (buyerSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!buyerSnapshot.hasData ||
                              !buyerSnapshot.data!.exists) {
                            return const Center(
                              child: Text("Buyer details not found"),
                            );
                          }

                          String buyerMobile =
                              buyerSnapshot.data!['phone'] ?? "Unknown";

                          String orderDate =
                              order['orderDate'] != null
                                  ? DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(order['orderDate'].toDate())
                                  : "";

                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                10,
                              ), // Add padding to the card
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Leading Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child:
                                        order['image'] != null &&
                                                order['image'].isNotEmpty
                                            ? (order['image'].startsWith('http')
                                                ? Image.network(
                                                  order['image'], // Handle image URLs
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                )
                                                : Image.memory(
                                                  base64Decode(order['image']),
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                ))
                                            : const Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ), // Add spacing between image and content
                                  // Main Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Product: ${order['productName']}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text("Qty: ${order['quantity']}"),
                                        Text("Total: ₹${order['totalAmount']}"),
                                        Text("Buyer Mobile: $buyerMobile"),
                                        Text(
                                          "Payment: ${order['paymentMethod']}",
                                        ),
                                        Text("Order Date: $orderDate"),
                                      ],
                                    ),
                                  ),
                                  // Trailing Status and Button
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Status: ${order['status']}",
                                        style: TextStyle(
                                          color:
                                              order['status'] == 'Pending'
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      if (order['status'] == 'Pending')
                                        ElevatedButton(
                                          onPressed:
                                              () => _updateOrderStatus(doc.id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                          ),
                                          child: const Text(
                                            "Mark as Success",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }
}
