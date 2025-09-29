# 📱 **RIFA APPLIANCES - Android Deployment Guide**

## 🚀 **Ready for Android Testing!**

Your RIFA APPLIANCES billing system is now configured to work with your Android device!

### ✅ **What's Configured:**

1. **Backend API**: Running on codespace with public access
2. **Flutter App**: Updated to connect to codespace backend
3. **Database**: MongoDB with sample data (invoices, products, users)
4. **Android SDK**: Configured on your Windows machine

---

## 📋 **Step-by-Step Deployment**

### **1. Clone/Update Repository on Windows**

⚠️ **Important**: Run these commands on your **Windows machine**, not in the codespace!

**If you haven't cloned yet:**
```bash
git clone https://github.com/syedthufel/Billing-System.git
cd Billing-System/frontend/appliances_billing
```

**If you already have it cloned:**
```bash
cd Billing-System
git pull origin main
cd frontend/appliances_billing
```

### **2. Install Flutter Dependencies (On Windows)**

⚠️ **Run on Windows Command Prompt/PowerShell:**

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### **3. Connect Your Android Device**

1. **Enable Developer Options** on your Android phone:
   - Settings → About Phone → Tap "Build Number" 7 times
   
2. **Enable USB Debugging**:
   - Settings → Developer Options → USB Debugging (ON)
   
3. **Connect via USB** and allow debugging when prompted

### **4. Verify Device Connection (On Windows)**

⚠️ **Run on Windows where Android device is connected:**

```bash
flutter devices
```

You should see your Android device listed (not just Linux desktop).

### **5. Deploy to Device (On Windows)**

⚠️ **Run on Windows with Android device connected:**

```bash
flutter run
```

**Alternative - Build APK for Manual Installation:**
```bash
flutter build apk --release
```
Then install: `build/app/outputs/flutter-apk/app-release.apk`

---

## ⚠️ **Important Notes**

- **Codespace Environment**: The GitHub Codespace (Linux) cannot directly connect to your Android device
- **Windows Required**: You must run Flutter commands on your Windows machine where:
  - Android Studio is installed
  - Android SDK is configured  
  - Your Android device is connected via USB
- **Backend Connection**: The Flutter app will connect to the codespace backend automatically

---

## 🎯 **Test Credentials**

**Admin User:**
- Email: `admin@rifa.com` 
- Password: `password123`

**Regular User:**
- Email: `test@example.com`
- Password: `password123`

---

## 🏪 **Sample Data Available**

### **Products:**
1. **50mfd Capacitor** - ₹950 (Stock: 8)
2. **Gas Top-Up** - ₹1,500 (Stock: 10)
3. **Outdoor Fan Motor Capacitor** - ₹450 (Stock: 8)
4. **AC Indoor Service** - ₹1,000 (Stock: 10)

### **Sample Invoices:**
- 4 invoices already created with different payment methods
- Total sales: ₹6,254 (Cash: ₹2,242, UPI: ₹2,832, Card: ₹1,180)

---

## 📲 **App Features to Test**

1. **🔐 Login with Biometric Authentication**
2. **📊 Dashboard with Real Sales Data**
3. **🧾 Create New Invoices with GST Calculation**
4. **📋 Product Selection from Inventory**
5. **💳 Multiple Payment Methods (Cash/Card/UPI)**
6. **📄 PDF Invoice Generation**
7. **📈 Daily Sales Tally**

---

## 🌐 **API Configuration**

The app is configured to connect to:
```
https://stunning-cod-974455r54gp4cxjp4-5000.app.github.dev/api
```

This connects your Android app to the backend running in the GitHub Codespace!

---

## 🔧 **Troubleshooting**

**If connection fails:**
1. Ensure codespace is still running
2. Check if MongoDB container is active
3. Verify port 5000 is public in codespace

**If biometric auth fails:**
- Enable fingerprint/face unlock in phone settings
- Grant biometric permissions to the app

---

## 🎉 **Ready to Go!**

Your RIFA APPLIANCES billing system is now ready for real-world testing on Android! 
Test all features including biometric login, invoice creation, and PDF generation.

**Enjoy your mobile billing solution!** 📱✨