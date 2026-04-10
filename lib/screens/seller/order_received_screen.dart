import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kisanbazaar/theme/app_colors.dart';
import 'package:kisanbazaar/widgets/kisan_image.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _showDeclineDialog(String orderId) async {
    TextEditingController reasonController = TextEditingController();
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Decline Order", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Why are you declining this order?"),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A reason is required to decline")));
                  return;
                }
                confirmed = true;
                Navigator.pop(context);
              },
              child: const Text("Decline", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed) {
      try {
        await FirebaseFirestore.instance.collection("orders").doc(orderId).update({
          "status": "declined",
          "cancelReason": reasonController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order declined"), backgroundColor: AppColors.error),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to decline order: $e"), backgroundColor: AppColors.error),
          );
        }
      }
    }
    return false;
  }

  void _updateOrderStatus(String orderId, String newStatus, {Map<String, dynamic>? orderData}) async {
    try {
      Map<String, dynamic> updateFields = {"status": newStatus.toLowerCase()};

      // Also save buyer info into the order document so it persists across status changes
      if (orderData != null) {
        if (orderData['buyerName'] != null && orderData['buyerName'].toString().trim().isNotEmpty) {
          updateFields['buyerName'] = orderData['buyerName'];
        }
        if (orderData['buyerPhone'] != null && orderData['buyerPhone'].toString().trim().isNotEmpty) {
          updateFields['buyerPhone'] = orderData['buyerPhone'];
        }
      }

      await FirebaseFirestore.instance
          .collection("orders")
          .doc(orderId)
          .update(updateFields);

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
      body: Column(
        children: [
          // Premium Header with Tabs
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF43A047)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Management',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('orders')
                                    .where('sellerId', isEqualTo: sellerId)
                                    .where('status', isEqualTo: 'pending')
                                    .snapshots(),
                                builder: (context, snap) {
                                  int count = snap.hasData ? snap.data!.docs.length : 0;
                                  return Text(
                                    count > 0 ? '$count pending order${count != 1 ? 's' : ''}' : 'All caught up!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.75),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppColors.primaryDark,
                      unselectedLabelColor: Colors.white.withOpacity(0.8),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(text: "Pending"),
                        Tab(text: "Delivered"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Order List
          Expanded(
            child: sellerId == null
                ? const Center(child: Text("User not authenticated"))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList("Pending", "Delivered"),
                      _buildOrderList("Delivered", null),
                    ],
                  ),
          ),
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

            bool isPending = currentStatus.toLowerCase() == "pending";

            if (nextStatus != null || isPending) {
              return Dismissible(
                key: Key(doc.id),
                direction: isPending ? DismissDirection.horizontal : DismissDirection.endToStart,
                background: isPending ? Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.close, color: Colors.white),
                      SizedBox(width: 8),
                      Text("DECLINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ) : Container(),
                secondaryBackground: Container(
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
                      Text(nextStatus ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Colors.white),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd && isPending) {
                    return await _showDeclineDialog(doc.id);
                  }
                  // For endToStart (mark as delivered), update status and return false
                  // Let the StreamBuilder handle UI removal when Firestore updates
                  if (direction == DismissDirection.endToStart && nextStatus != null) {
                    _updateOrderStatus(doc.id, nextStatus, orderData: order);
                  }
                  return false; // Don't dismiss - StreamBuilder will remove it automatically
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
    // Check if buyer info is already in the order document
    final bool hasBuyerName = order['buyerName'] != null && order['buyerName'].toString().trim().isNotEmpty;
    final bool hasBuyerPhone = order['buyerPhone'] != null && order['buyerPhone'].toString().trim().isNotEmpty;

    String buyerName = hasBuyerName ? order['buyerName'] : "Buyer";
    String buyerPhone = hasBuyerPhone ? order['buyerPhone'] : "";

    // For old orders without buyer info, try to extract phone from deliveryAddress
    // (deliveryAddress often contains phone on a new line)
    if (!hasBuyerPhone && order['deliveryAddress'] != null) {
      String address = order['deliveryAddress'].toString();
      List<String> lines = address.split('\n');
      if (lines.length > 1) {
        // Last line might be the phone number
        String possiblePhone = lines.last.trim();
        if (possiblePhone.startsWith('+') || RegExp(r'^[\d\s\-]{7,}').hasMatch(possiblePhone)) {
          buyerPhone = possiblePhone;
        }
      }
    }

    // If we still don't have a phone, show N/A
    if (buyerPhone.isEmpty) {
      buyerPhone = "N/A";
    }

    return _buildOrderCardContent(
      orderId,
      order,
      buyerName,
      buyerPhone,
    );
  }

  Widget _buildOrderCardContent(
    String orderId,
    Map<String, dynamic> order,
    String buyerName,
    String buyerMobile, {
    bool isLoading = false,
  }) {
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
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : Text(buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(buyerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(buyerMobile, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(orderDate, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
              // Delivery Details Section
              if (order['deliveryAddress'] != null && order['deliveryAddress'].toString().isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Delivery details", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(order['deliveryAddress'] ?? "No Address", style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              // Bottom Section (Product Details)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: KisanImage(
                        imageSource: order['imageUrl'] ?? order['image'] ?? '',
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
  }
}
