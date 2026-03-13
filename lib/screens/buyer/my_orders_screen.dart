import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kisanbazaar/theme/app_colors.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final String? buyerId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (buyerId == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view your orders.")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't show back arrow if it's a tab
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: buyerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No Orders Yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text("You haven't placed any orders.", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          var orders = snapshot.data!.docs.toList();
          orders.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            Timestamp? aTime = aData['createdAt'] as Timestamp?;
            Timestamp? bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var doc = orders[index];
              var orderData = doc.data() as Map<String, dynamic>;

              String orderDate = orderData['createdAt'] != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format((orderData['createdAt'] as Timestamp).toDate())
                  : "Unknown date";
                  
              String status = orderData['status'] ?? "pending";
              String reason = orderData['cancelReason'] ?? "";
              
              Color statusColor;
              switch (status.toLowerCase()) {
                case 'delivered':
                  statusColor = AppColors.success;
                  break;
                case 'declined':
                case 'cancelled':
                  statusColor = AppColors.error;
                  break;
                case 'packed':
                  statusColor = Colors.orange;
                  break;
                default:
                  statusColor = AppColors.primary;
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: orderData['image'] != null && orderData['image'].isNotEmpty
                                ? (orderData['image'].startsWith('http')
                                    ? Image.network(orderData['image'], width: 70, height: 70, fit: BoxFit.cover)
                                    : Image.memory(base64Decode(orderData['image']), width: 70, height: 70, fit: BoxFit.cover))
                                : Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(orderData['productName'] ?? "Unknown Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(orderDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                      child: Text("Qty: ${orderData['quantity']}", style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text("₹${orderData['totalAmount'] ?? orderData['total'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.circle, size: 10, color: statusColor),
                              const SizedBox(width: 6),
                              Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          Text("Order #${doc.id.substring(0, 8)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      if ((status.toLowerCase() == 'declined' || status.toLowerCase() == 'cancelled') && reason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Text("Reason: $reason", style: const TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
