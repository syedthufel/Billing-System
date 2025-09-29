# Billing System Test Instructions

This document provides testing instructions for the Billing System application.

## Backend API Testing (with MongoDB)

### Prerequisites
1. Ensure MongoDB is running on your system
2. Install and start MongoDB Compass (optional but recommended)
3. The backend server should be running on port 3000

### 1. Test Server Health
```bash
curl http://localhost:3000/api/health
```
Expected response:
```json
{
  "message": "Billing System API is running",
  "timestamp": "2023-XX-XXTXX:XX:XX.XXXZ"
}
```

### 2. Seed Sample Data
```bash
cd backend
node seedData.js
```
This will create:
- Admin user (username: admin, password: admin123)
- Cashier user (username: cashier, password: cashier123)
- 5 sample products (TVs, refrigerators, washing machines, etc.)
- Stock entries for all products

### 3. Test Authentication

#### Register a new user:
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com", 
    "password": "test123",
    "role": "user"
  }'
```

#### Login:
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```
Save the token from the response for subsequent requests.

### 4. Test Products API

#### Get all products:
```bash
curl -X GET http://localhost:3000/api/products \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Get products with filters:
```bash
curl -X GET "http://localhost:3000/api/products?category=television&limit=5" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 5. Test Stock Management

#### Get stock data:
```bash
curl -X GET http://localhost:3000/api/stock \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Get low stock alerts:
```bash
curl -X GET http://localhost:3000/api/stock/alerts/low-stock \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 6. Test Invoice Creation

```bash
curl -X POST http://localhost:3000/api/invoices \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "customerInfo": {
      "name": "John Doe",
      "phone": "9876543210",
      "email": "john@example.com"
    },
    "items": [{
      "productId": "PRODUCT_ID_HERE",
      "quantity": 1,
      "discount": 0
    }],
    "paymentMethod": "cash",
    "notes": "Test invoice"
  }'
```

### 7. Test Reports

#### Get dashboard data:
```bash
curl -X GET http://localhost:3000/api/tally/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Get GST report:
```bash
curl -X GET http://localhost:3000/api/tally/gst/2023-01-01/2023-12-31 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Flutter App Testing

### Prerequisites
1. Flutter SDK installed and configured
2. Android emulator or physical device connected
3. Backend server running with sample data

### 1. Setup and Run

```bash
cd flutter_app
flutter pub get
flutter run
```

### 2. Test Authentication
- Try logging in with admin credentials (admin/admin123)
- Test biometric authentication setup (if device supports it)
- Try logging in with cashier credentials (cashier/cashier123)

### 3. Test Dashboard
- Verify sales summary displays correctly
- Check stock overview shows product counts
- Test navigation to different screens

### 4. Test Billing Screen
- Search for products
- Add products to cart
- Modify quantities and discounts  
- Fill customer information
- Create an invoice
- Verify GST calculations are correct

### 5. Test Stock Management
- View all stock items
- Check low stock alerts
- Add stock movements (if admin user)
- Verify stock levels update correctly

### 6. Test Tally & Reports
- View sales overview
- Check GST reports
- View top customers
- Verify charts display correctly

## Testing GST Calculations

### Sample Product with 18% GST:
- Base Price: ₹10,000
- GST (18%): ₹1,800
- Total: ₹11,800

### Sample Product with 28% GST:
- Base Price: ₹25,000
- GST (28%): ₹7,000
- Total: ₹32,000

### Multi-item Invoice Test:
1. Add TV (₹15,000 + 28% GST = ₹19,200)
2. Add Refrigerator (₹12,000 + 18% GST = ₹14,160)
3. Total: ₹33,360 (with ₹6,360 total GST)

## Common Issues and Solutions

### 1. MongoDB Connection Error
- Ensure MongoDB is running: `mongod`
- Check connection string in .env file
- Verify MongoDB is accessible on localhost:27017

### 2. JWT Token Expired
- Login again to get a fresh token
- Check JWT_SECRET is set in .env file

### 3. Flutter Dependencies Issue
- Run `flutter clean`
- Run `flutter pub get`
- Restart your IDE/editor

### 4. API Connection from Flutter
- Ensure backend server is running
- Update API base URL in `api_service.dart`
- For Android emulator, use `http://10.0.2.2:3000/api`
- For iOS simulator, use `http://localhost:3000/api`

### 5. Biometric Authentication Not Working
- Test on physical device (emulators may not support biometrics)
- Ensure device has biometric authentication set up
- Check app permissions for biometric access

## Performance Testing

### Load Testing with Apache Bench
```bash
# Test health endpoint
ab -n 1000 -c 10 http://localhost:3000/api/health

# Test authenticated endpoint (replace token)
ab -n 500 -c 5 -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/products
```

### Database Performance
- Monitor MongoDB performance using MongoDB Compass
- Check query execution times for complex reports
- Verify indexes are being used effectively

## Security Testing

### 1. Test Rate Limiting
```bash
# Send many requests quickly to trigger rate limiting
for i in {1..200}; do curl http://localhost:3000/api/health; done
```

### 2. Test Invalid JWT Tokens
```bash
curl -X GET http://localhost:3000/api/products \
  -H "Authorization: Bearer invalid_token_here"
```

### 3. Test SQL Injection Protection
```bash
curl -X GET "http://localhost:3000/api/products?search='; DROP TABLE products; --" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Sample Test Data

Use this data for testing invoice creation:

### Customer Data:
```json
{
  "name": "Rajesh Kumar",
  "phone": "9876543210",
  "email": "rajesh@example.com",
  "address": {
    "street": "123 Main Street",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001"
  }
}
```

### Sample Invoice Items:
```json
[
  {
    "productId": "SAMSUNG_TV_ID",
    "quantity": 1,
    "discount": 500
  },
  {
    "productId": "LG_REFRIGERATOR_ID", 
    "quantity": 1,
    "discount": 0
  }
]
```

This comprehensive testing guide should help verify all functionality of the Billing System application.