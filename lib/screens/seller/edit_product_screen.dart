// ignore_for_file: use_build_context_synchronously

import 'dart:convert' show base64Encode, base64Decode;
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kisanbazaar/widgets/kisan_image.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditProductScreen({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController;
  late TextEditingController _sellerNameController;

  File? _image;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.productData['name'] ?? '');
    _priceController = TextEditingController(text: widget.productData['price']?.toString() ?? '');
    _quantityController = TextEditingController(text: widget.productData['quantity']?.toString() ?? '');
    _categoryController = TextEditingController(text: widget.productData['category'] ?? '');
    _sellerNameController = TextEditingController(text: widget.productData['seller_name'] ?? '');
    _existingImageUrl = widget.productData['imageUrl'] ?? widget.productData['image'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _sellerNameController.dispose();
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
      debugPrint('Edit: Picked image size: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
      setState(() {
        _imageBytes = bytes;
        _existingImageUrl = null; // Clear existing image when new one is picked
        if (!kIsWeb) {
          _image = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _updateProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _sellerNameController.text.isEmpty ||
        (_imageBytes == null && _existingImageUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and ensure an image is selected"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        },
      );

      // Upload new image to Storage if picked
      String finalImageUrl = _existingImageUrl ?? '';
      String finalImageBase64Fallback = widget.productData['image'] ?? ''; 

      if (_imageBytes != null) {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('product_images')
              .child('${DateTime.now().millisecondsSinceEpoch}_${currentUser?.uid ?? 'unknown'}.jpg');

          final uploadTask = storageRef.putData(
              _imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
          
          final snapshot = await uploadTask;
          finalImageUrl = await snapshot.ref.getDownloadURL();
          finalImageBase64Fallback = finalImageUrl; // Both fields can be url now
        } catch (e) {
          throw Exception('Failed to upload new image: $e');
        }
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'category': _categoryController.text,
        'seller_name': _sellerNameController.text,
        'imageUrl': finalImageUrl,
        'image': finalImageBase64Fallback, // Backward compatibility
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product updated successfully"),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating product: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Product",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFFF5F5F5)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Image picker section
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(75),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(75),
                                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                              )
                            : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(75),
                                    child: KisanImage(
                                      imageSource: _existingImageUrl!,
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: Color(0xFF4CAF50),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Change Image",
                                        style: TextStyle(
                                          color: Color(0xFF4CAF50),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Form Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Product Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          _nameController,
                          "Product Name",
                          Icons.shopping_cart_outlined,
                        ),

                        _buildTextField(
                          _priceController,
                          "Price (\$)",
                          Icons.attach_money,
                          TextInputType.number,
                        ),

                        // Quantity Field with KG suffix
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _quantityController,
                                "Quantity",
                                Icons.scale_outlined,
                                TextInputType.number,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "KG",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                          ],
                        ),

                        _buildTextField(
                          _categoryController,
                          "Category",
                          Icons.category_outlined,
                        ),

                        _buildTextField(
                          _sellerNameController,
                          "Seller Name",
                          Icons.person_outline,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Update Product Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Update Product",
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
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType keyboardType = TextInputType.text,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
          filled: true,
          fillColor: Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
