# Billing-System
# Appliances Shop Billing Application

A mobile-friendly **billing application** built with **Flutter** for an appliances shop. It supports **GST billing, stock management, tally tracking, and biometric admin login**. Data is stored in **MongoDB (local via Compass)** and managed through a **Node.js/Express backend**.

---

## 🚀 Features

* GST-inclusive **billing system**
* **Stock management**: add, update, and track inventory
* **Tally tracking** for daily/weekly/monthly sales
* **Admin login** with biometric authentication (fingerprint/Face ID)
* **Clean Flutter UI** optimized for mobile

---

## 🛠️ Tech Stack

* **Frontend**: Flutter (Dart)
* **Backend**: Node.js + Express
* **Database**: MongoDB (local via Compass)
* **State Management**: Provider / Riverpod

---

## 📂 Project Structure

```
billing-app/
 ├── backend/               # Node.js + Express API
 │    ├── models/           # Mongoose schemas (Products, Invoices, Stock)
 │    ├── routes/           # API routes
 │    └── server.js         # Backend entry point
 ├── flutter_app/           # Flutter mobile app
 │    ├── lib/
 │    │    ├── models/      # Dart models
 │    │    ├── screens/     # UI screens
 │    │    └── services/    # API integration
 └── README.md
```

---

## ⚙️ Setup Instructions

### 1. Backend Setup

1. Install dependencies:

   ```bash
   cd backend
   npm install
   ```
2. Start MongoDB locally and connect using MongoDB Compass.
3. Run the backend:

   ```bash
   node server.js
   ```

### 2. Flutter App Setup

1. Install Flutter dependencies:

   ```bash
   cd flutter_app
   flutter pub get
   ```
2. Run the app:

   ```bash
   flutter run
   ```

---

## 📊 Database Models

* **Products**: name, price, stock quantity, GST rate
* **Invoices**: items, total, GST amount, date
* **Tally**: daily/weekly/monthly sales records

---

## 🔒 Authentication

* Admin login via **biometric authentication**
* JWT-based session handling between Flutter and backend

---

## 📌 Future Enhancements

* Cloud MongoDB (Atlas) option
* Multi-user roles (cashier, manager)
* Export reports (PDF/Excel)

---

## 👨‍💻 Author

Developed by Syed Thufel ✨
