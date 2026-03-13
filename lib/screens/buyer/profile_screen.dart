import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kisanbazaar/screens/auth/login_screen.dart';

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
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          debugPrint("User Data: ${userDoc.data()}");
          setState(() {
            name = userDoc['fullName'];
            email = userDoc['email'];
            _mobileController.text = userDoc['phone'] ?? '';
            _addressController.text = userDoc['address'] ?? '';
            imageUrl = userDoc['image'] ?? '';
            isLoading = false;
          });
        } else {
          debugPrint("User document not found.");
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String userId = _auth.currentUser!.uid;
      Reference storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/$userId.jpg',
      );

      await storageRef.putFile(imageFile);
      String downloadUrl = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'image': downloadUrl,
      });
      setState(() {
        imageUrl = downloadUrl;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      String userId = _auth.currentUser!.uid;

      await _firestore.collection('users').doc(userId).update({
        'phone': _mobileController.text,
        'address': _addressController.text,
      });

      Fluttertoast.showToast(
        msg: "Profile updated successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update profile: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();

      // Clear saved preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('buyer_selectedIndex');

      if (!mounted) return;

      // Navigate to Login Screen and clear navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error logging out: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Buyer Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  imageUrl != null && imageUrl!.isNotEmpty
                                      ? NetworkImage(imageUrl!)
                                      : null,
                              backgroundColor: Colors.grey.shade300,
                              child:
                                  (imageUrl == null || imageUrl!.isEmpty)
                                      ? Text(
                                        name?.isNotEmpty == true
                                            ? name!
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // User Details Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name ?? 'Name',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                email ?? 'Email',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Mobile Number Field
                      TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Address Field
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const SizedBox(height: 20),

                      // Update Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Update Profile',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Logout',
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
