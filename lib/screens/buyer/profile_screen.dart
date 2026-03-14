import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisanbazaar/screens/auth/login_screen.dart';
import 'package:kisanbazaar/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? name, email, imageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists && mounted) {
          setState(() {
            name = userDoc['fullName'] ?? userDoc['name'] ?? 'User';
            email = userDoc['email'];
            _mobileController.text = userDoc['phone'] ?? '';
            _addressController.text = userDoc['address'] ?? '';
            imageUrl = userDoc['image'] ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String userId = _auth.currentUser!.uid;
      Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/$userId.jpg');
      await storageRef.putFile(imageFile);
      String downloadUrl = await storageRef.getDownloadURL();
      await _firestore.collection('users').doc(userId).update({'image': downloadUrl});
      setState(() => imageUrl = downloadUrl);
    }
  }

  Future<void> _updateProfile() async {
    try {
      String userId = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(userId).update({
        'phone': _mobileController.text,
        'address': _addressController.text,
      });
      Fluttertoast.showToast(msg: "Profile updated successfully!", backgroundColor: AppColors.primary);
    } catch (e) {
      Fluttertoast.showToast(msg: "Update failed: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('buyer_selectedIndex');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Contact Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  _buildTextField(_mobileController, "Mobile Number", Icons.phone_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_addressController, "Delivery Address", Icons.location_on_rounded),
                  const SizedBox(height: 32),
                  const Text("Account Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  _buildOptionTile(Icons.shopping_bag_rounded, "My Orders", () {}),
                  _buildOptionTile(Icons.notifications_rounded, "Notifications", () {}),
                  _buildOptionTile(Icons.help_center_rounded, "Help Center", () {}),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 54), foregroundColor: Colors.red),
                    child: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 4)),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.lightGreenBg,
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
                  child: imageUrl == null || imageUrl!.isEmpty ? Icon(Icons.person_rounded, size: 50, color: AppColors.primary.withOpacity(0.5)) : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(name ?? "User", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(email ?? "", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
    );
  }
}
