import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kisanbazaar/theme/app_colors.dart';

class OrderReceivedScreen extends StatefulWidget {
  const OrderReceivedScreen({super.key});

  @override
  State<OrderReceivedScreen> createState() => _OrderReceivedScreenState();
}

class _OrderReceivedScreenState extends State<OrderReceivedScreen> with SingleTickerProviderStateMixin {
  String? sellerId = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection("orders")
          .doc(orderId)
          .update({"status": newStatus.toLowerCase()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order moved to $newStatus"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Order Management", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Packed"),
            Tab(text: "Delivered"),
          ],
        ),
      ),
      body: sellerId == null
          ? const Center(child: Text("User not authenticated"))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList("Pending", "Packed"),
                _buildOrderList("Packed", "Delivered"),
                _buildOrderList("Delivered", null),
              ],
            ),
    );
  }

  Widget _buildOrderList(String currentStatus, String? nextStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("orders")
          .where("sellerId", isEqualTo: sellerId)
          .where("status", isEqualTo: currentStatus.toLowerCase())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "No $currentStatus Orders",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  "Orders with status '$currentStatus' will appear here.",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        var orders = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var doc = orders[index];
            var order = doc.data() as Map<String, dynamic>;
            
            Widget orderCard = _buildOrderCard(doc.id, order);

            if (nextStatus != null) {
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text("Mark as ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(nextStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Colors.white),
                    ],
                  ),
                ),
                onDismissed: (direction) {
                  _updateOrderStatus(doc.id, nextStatus);
                },
                child: orderCard,
              );
            }
            return orderCard;
          },
        );
      },
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> order) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(order['buyerId']).get(),
      builder: (context, buyerSnapshot) {
        String buyerName = "Processing...";
        String buyerMobile = "...";
        
        if (buyerSnapshot.hasData && buyerSnapshot.data!.exists) {
          buyerName = buyerSnapshot.data!['fullName'] ?? "Unknown Buyer";
          buyerMobile = buyerSnapshot.data!['phone'] ?? "No Phone";
        }

        String orderDate = order['orderDate'] != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(order['orderDate'].toDate())
            : "Unknown time";

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              // Top Section (Buyer Info & Actions)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                      child: Text(buyerName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(buyerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(orderDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Calling $buyerMobile...")));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Opening chat with $buyerName...")));
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Bottom Section (Product Details)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: order['image'] != null && order['image'].isNotEmpty
                          ? (order['image'].startsWith('http')
                              ? Image.network(order['image'], width: 70, height: 70, fit: BoxFit.cover)
                              : Image.memory(base64Decode(order['image']), width: 70, height: 70, fit: BoxFit.cover))
                          : Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['productName'] ?? "Unknown Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text("Qty: ${order['quantity']}", style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(order['paymentMethod'] ?? "Cash", style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("₹${order['totalAmount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                              if (order['status'] != 'Delivered')
                                Row(
                                  children: [
                                    Text("Swipe to ", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                    const Icon(Icons.swipe_left, size: 16, color: Colors.grey),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
