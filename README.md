# KisanBazaar 🌾  
### A Farmer-to-Buyer Marketplace App

KisanBazaar is a Flutter-based marketplace application that connects **farmers directly with buyers**.  
The goal of the project is to remove middlemen, provide fair pricing to farmers, and make fresh farm products easily accessible to consumers.

Farmers can list products, manage pricing, and handle incoming orders. Buyers can browse items, add them to cart, and place orders from their mobile device.

---

# 📌 Table of Contents

- [About the Project](#about-the-project)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Screens / Modules](#screens--modules)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Firebase Setup](#firebase-setup)
- [How to Run](#how-to-run)
- [How to Build](#how-to-build)
- [Run on Web with Docker](#run-on-web-with-docker)
- [Environment / Configuration Notes](#environment--configuration-notes)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [License](#license)

---

# About the Project

KisanBazaar is designed to bridge the gap between **farmers** and **customers** by creating a digital agricultural marketplace.

This project helps:
- Farmers sell products at their own price
- Buyers purchase directly from farmers
- Reduce dependency on intermediaries
- Enable a transparent buying and selling flow

---

# Features

## 👨‍🌾 For Farmers / Sellers
- Add product listings
- Upload product images
- Set custom prices
- Edit existing products
- Delete products
- Receive orders
- Update order status
- Manage their own product catalog

## 🛒 For Buyers
- Browse available farm products
- View product details
- Add items to cart
- Place orders
- Track order flow such as:
  - Pending
  - Shipped
  - Delivered

## 🔐 Authentication
- User login
- User registration
- Role-based flow for buyer and seller

## 🔔 Extra Features
- Notifications
- Toast messages
- Splash screen
- Firebase-backed storage and data handling

---

# Tech Stack

## Frontend
- Flutter
- Dart

## Backend / Cloud
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

## Packages Used
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `image_picker`
- `shared_preferences`
- `fluttertoast`
- `flutter_local_notifications`
- `intl`
- `google_fonts`
- `http`
- `confetti`

---

# Project Structure

```bash
KisanBazaar/
│── android/
│── ios/
│── web/
│── windows/
│── linux/
│── macos/
│── assets/
│   └── images/
│── lib/
│   ├── models/
│   │   ├── order_model.dart
│   │   ├── product_model.dart
│   │   └── user_model.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── buyer/
│   │   ├── seller/
│   │   ├── splash/
│   │   └── examples/
│   ├── theme/
│   ├── widgets/
│   
│   └── main.dart
│── test/
│── pubspec.yaml
│── pubspec.lock
│── 
│── Dockerfile
│── README.md


1. Clone the Repository
git clone https://github.com/NisargRamani05/KisanBazaar.git
cd KisanBazaar

2. Install Dependencies
flutter pub get
