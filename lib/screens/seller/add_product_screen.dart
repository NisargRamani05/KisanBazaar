// ignore_for_file: use_build_context_synchronously

import 'dart:convert' show base64Encode;
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kisanbazaar/theme/app_colors.dart';
import 'package:kisanbazaar/screens/seller/seller_dashboard.dart';
import 'package:intl/intl.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _harvestDateController = TextEditingController();

  String? _selectedCategory;
  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Dairy',
    'Grains',
    'Other',
  ];

  String _selectedUnit = '/kg';
  final List<String> _units = ['/kg', '/gm', '/dozen', '/pc'];

  File? _image;
  Uint8List? _imageBytes;
  final picker = ImagePicker();
  bool _isLoading = false;
  bool _showSuccessAnimation = false;

  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _harvestDateController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      debugPrint('Picked image size: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
      setState(() {
        _imageBytes = bytes;
        if (!kIsWeb) {
          _image = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _harvestDateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload a product image"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a category"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Convert image bytes to base64 string (already compressed at pick time)
      final String imageBase64 = base64Encode(_imageBytes!);
      debugPrint('Image base64 length: ${imageBase64.length} chars (${(_imageBytes!.length / 1024).toStringAsFixed(1)} KB)');
      
      // Check if base64 image is too large for Firestore (max ~700KB of base64 to stay safe)
      if (imageBase64.length > 700000) {
        throw Exception('Image is too large. Please pick a smaller image.');
      }

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      String sellerName = 'Unknown Seller';
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data['fullName'] != null) {
          sellerName = data['fullName'].toString();
        }
      }

      final String productName = _nameController.text.trim();
      final String description = _descriptionController.text.trim();
      final String priceText = _priceController.text.trim().replaceAll(RegExp(r'[^0-9.]'), '');
      final String quantityText = _quantityController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      
      final double? parsedPrice = double.tryParse(priceText);
      final int? parsedQuantity = int.tryParse(quantityText);

      if (parsedPrice == null || parsedPrice.isNaN || parsedPrice.isInfinite || parsedPrice <= 0) {
        throw Exception('Invalid price value. Please enter a valid number.');
      }
      if (parsedQuantity == null || parsedQuantity <= 0) {
        throw Exception('Invalid quantity value. Please enter a valid number.');
      }

      final String unit = _selectedUnit;
      final String category = _selectedCategory ?? 'Other';
      final String harvestDate = _harvestDateController.text.trim();
      final String sellerId = currentUser.uid;

      final Map<String, dynamic> productData = <String, dynamic>{
        'name': productName,
        'description': description,
        'price': parsedPrice,
        'unit': unit,
        'quantity': parsedQuantity,
        'category': category,
        'seller_name': sellerName,
        'image': imageBase64,
        'sellerId': sellerId,
        'created_at': FieldValue.serverTimestamp(),
      };

      if (harvestDate.isNotEmpty) {
        productData['harvest_date'] = harvestDate;
      }

      debugPrint('Product data fields: name=$productName, price=$parsedPrice, qty=$parsedQuantity, category=$category, imageLen=${imageBase64.length}');

      debugPrint('Adding product to Firestore...');
      await FirebaseFirestore.instance.collection('products').add(productData);
      debugPrint('Product added successfully!');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _showSuccessAnimation = true;
      });

      _successController.forward();

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _showSuccessAnimation = false;
        _successController.reset();
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _quantityController.clear();
        _harvestDateController.clear();
        _selectedCategory = null;
        _selectedUnit = '/kg';
        _image = null;
        _imageBytes = null;
      });

      // After publishing, navigate back to SellerDashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SellerDashboard()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding product: $e"),
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
        title: const Text(
          "Add New Product",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Upload Area
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              _imageBytes == null
                                  ? AppColors.divider
                                  : AppColors.primary,
                          width: _imageBytes == null ? 1 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child:
                          _imageBytes == null
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Upload Product Photo",
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "High-quality images sell faster",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                              : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildLabel("Product Name *"),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration("e.g. Fresh Organic Tomatoes"),
                    validator:
                        (value) => value!.isEmpty ? "Enter product name" : null,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Category *"),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedCategory,
                              decoration: _inputDecoration("Select"),
                              items:
                                  _categories
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c, overflow: TextOverflow.ellipsis),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (val) =>
                                      setState(() => _selectedCategory = val),
                              validator:
                                  (value) => value == null ? "Select" : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Unit *"),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedUnit,
                              decoration: _inputDecoration("Unit"),
                              items:
                                  _units
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(u, overflow: TextOverflow.ellipsis),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (val) => setState(() => _selectedUnit = val!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Price *"),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                "₹ 0.00",
                              ).copyWith(prefixText: "₹ "),
                              validator:
                                  (value) => value!.isEmpty ? "Req" : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Quantity *"),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration("e.g. 50"),
                              validator:
                                  (value) => value!.isEmpty ? "Req" : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Harvest Date (Optional)"),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _harvestDateController,
                        decoration: _inputDecoration("Select date").copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Description *"),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      "Describe your product concisely...",
                    ),
                    validator:
                        (value) => value!.isEmpty ? "Enter description" : null,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _uploadProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withOpacity(0.5),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "Publish Product",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          if (_showSuccessAnimation)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Product Published!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
