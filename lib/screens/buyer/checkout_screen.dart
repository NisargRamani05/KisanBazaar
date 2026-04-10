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
  int _selectedAddressIndex = 0;
  bool _isLoading = false;

  // Multiple addresses
  List<Map<String, dynamic>> _addresses = [];
  String _userPhone = "";
  String _buyerName = "";
  String _buyerPhone = "";

  @override
  void initState() {
    super.initState();
    _fetchUserAddresses();
  }

  Future<void> _fetchUserAddresses() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists && mounted) {
          final data = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            _userPhone = data?['phone'] ?? '';
            _buyerName = data?['fullName'] ?? data?['name'] ?? 'Buyer';
            _buyerPhone = data?['phone'] ?? '';

            if (data?['addresses'] != null && data!['addresses'] is List && (data['addresses'] as List).isNotEmpty) {
              _addresses = List<Map<String, dynamic>>.from(
                (data['addresses'] as List).map((e) => Map<String, dynamic>.from(e)),
              );
              // Select the default address
              for (int i = 0; i < _addresses.length; i++) {
                if (_addresses[i]['isDefault'] == true) {
                  _selectedAddressIndex = i;
                  break;
                }
              }
            } else {
              // Legacy single address fallback
              String legacyAddress = data?['address'] ?? '';
              if (legacyAddress.isNotEmpty) {
                _addresses = [
                  {
                    'label': 'Home',
                    'address': legacyAddress,
                    'phone': _userPhone,
                    'isDefault': true,
                  }
                ];
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
    }
  }

  String _getSelectedDeliveryAddress() {
    if (_addresses.isEmpty) return 'No address set';
    final addr = _addresses[_selectedAddressIndex];
    String fullAddress = addr['address'] ?? '';
    String phone = addr['phone'] ?? _userPhone;
    if (phone.isNotEmpty) {
      fullAddress += '\n$phone';
    }
    return fullAddress;
  }

  void _showAddAddressBottomSheet() {
    final addressController = TextEditingController();
    final phoneController = TextEditingController(text: _userPhone);
    String selectedLabel = 'Home';
    final labels = ['Home', 'Office', 'Work', 'Other'];
    final customLabelController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Add New Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    const Text("Address Type", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: labels.map((label) {
                        bool selected = selectedLabel == label;
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          selectedColor: AppColors.primaryLight.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color: selected ? AppColors.primary : Colors.grey[700],
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) => setModalState(() => selectedLabel = label),
                        );
                      }).toList(),
                    ),
                    if (selectedLabel == 'Other') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customLabelController,
                        decoration: InputDecoration(
                          labelText: "Custom Label",
                          hintText: "e.g. Grandma's House",
                          prefixIcon: const Icon(Icons.label_outline, color: AppColors.primary),
                          filled: true, fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Full Address *",
                        hintText: "House No, Street, City, PIN",
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.location_on_rounded, color: AppColors.primary),
                        ),
                        filled: true, fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                        filled: true, fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (addressController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter an address"), backgroundColor: AppColors.error),
                            );
                            return;
                          }

                          String finalLabel = selectedLabel == 'Other'
                              ? (customLabelController.text.trim().isEmpty ? 'Other' : customLabelController.text.trim())
                              : selectedLabel;

                          final newAddress = {
                            'label': finalLabel,
                            'address': addressController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'isDefault': _addresses.isEmpty,
                          };

                          setState(() {
                            _addresses.add(newAddress);
                            _selectedAddressIndex = _addresses.length - 1;
                          });

                          // Also save to Firestore
                          try {
                            final userId = FirebaseAuth.instance.currentUser?.uid;
                            if (userId != null) {
                              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                                'addresses': _addresses,
                              });
                            }
                          } catch (e) {
                            debugPrint('Error saving address: $e');
                          }

                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text("Add & Use This Address", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> placeOrder() async {
    if (widget.totalAmount <= 0) return;
    if (_addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a delivery address first"), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isLoading = true);
    await _processOrder();
  }

  Future<void> _processOrder() async {
    setState(() => _isLoading = true);
    try {
      String? buyerId = FirebaseAuth.instance.currentUser?.uid;
      if (buyerId == null) throw Exception("User not logged in");

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String deliveryAddress = _getSelectedDeliveryAddress();

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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Product not found: $productName. Recording as unavailable."), backgroundColor: Colors.orange),
          );
          final placeholderOrder = {
            "buyerId": buyerId,
            "buyerName": _buyerName,
            "buyerPhone": _buyerPhone,
            "sellerId": sellerId,
            "productId": productId,
            "productName": "$productName (Unavailable)",
            "quantity": orderedQuantity,
            "totalAmount": price * orderedQuantity,
            "total": price * orderedQuantity,
            "paymentMethod": _selectedPaymentMethod,
            "deliveryAddress": deliveryAddress,
            "status": "pending",
            "image": item['imageUrl'] ?? item['image'] ?? '',
            "imageUrl": item['imageUrl'] ?? item['image'] ?? '',
            "timestamp": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp(),
            "orderDate": FieldValue.serverTimestamp(),
          };
          await retry(() async {
            await firestore.collection("orders").add(placeholderOrder);
          });
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
          "buyerName": _buyerName,
          "buyerPhone": _buyerPhone,
          "sellerId": sellerId,
          "productId": productId,
          "productName": productName,
          "quantity": orderedQuantity,
          "totalAmount": price * orderedQuantity,
          "total": price * orderedQuantity,
          "paymentMethod": _selectedPaymentMethod,
          "deliveryAddress": deliveryAddress,
          "status": "pending",
          "image": item['imageUrl'] ?? item['image'] ?? '',
          "imageUrl": item['imageUrl'] ?? item['image'] ?? '',
          "timestamp": FieldValue.serverTimestamp(),
          "createdAt": FieldValue.serverTimestamp(),
          "orderDate": FieldValue.serverTimestamp(),
        };

        await retry(() async {
          await firestore.collection("orders").add(orderData);
        });

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
                      Navigator.pop(context);
                      Navigator.pop(context);
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
                // Delivery Address section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Delivery Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    if (_addresses.length > 1)
                      TextButton(
                        onPressed: () => _showAddressSelector(),
                        child: const Text("Change", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_addresses.isEmpty)
                  GestureDetector(
                    onTap: _showAddAddressBottomSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_location_alt_outlined, size: 36, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          const Text("Add Delivery Address", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("Tap to add your address", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  _buildSelectedAddressCard(),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _showAddAddressBottomSheet,
                    icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                    label: const Text("Add New Address", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),

                const SizedBox(height: 16),

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
                      )),
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

  Widget _buildSelectedAddressCard() {
    final addr = _addresses[_selectedAddressIndex];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            addr['label'] == 'Home'
                ? Icons.home_rounded
                : addr['label'] == 'Office' || addr['label'] == 'Work'
                    ? Icons.business_rounded
                    : Icons.location_on_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(addr['label'] ?? 'Address', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(addr['address'] ?? '', style: TextStyle(color: Colors.grey[600], height: 1.5)),
                if (addr['phone'] != null && addr['phone'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text("📞 ${addr['phone']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ],
            ),
          ),
          if (_addresses.length > 1)
            GestureDetector(
              onTap: _showAddressSelector,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Choose Delivery Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...List.generate(_addresses.length, (index) {
                final addr = _addresses[index];
                bool isSelected = _selectedAddressIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAddressIndex = index);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          addr['label'] == 'Home'
                              ? Icons.home_rounded
                              : addr['label'] == 'Office' || addr['label'] == 'Work'
                                  ? Icons.business_rounded
                                  : Icons.location_on_rounded,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(addr['label'] ?? 'Address',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (addr['isDefault'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text("Default", style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(addr['address'] ?? '', style: TextStyle(color: Colors.grey[600], height: 1.4, fontSize: 13)),
                              if (addr['phone'] != null && addr['phone'].toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text("📞 ${addr['phone']}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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
