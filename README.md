# Billing System - Flutter App for Appliances Shop

A comprehensive billing system designed specifically for appliances shops, featuring GST billing, stock management, tally tracking, and biometric admin authentication. Built with Flutter for the frontend and Node.js/Express with MongoDB for the backend.

## Features

### 🔐 Authentication & Security
- **Biometric Authentication** for admin users (fingerprint/face recognition)
- **JWT-based Authentication** with secure token management
- **Role-based Access Control** (Admin/User roles)
- **Password Encryption** using bcrypt

### 📱 Flutter Mobile App
- **Modern Material Design UI** with responsive layout
- **Dashboard** with real-time sales and stock overview
- **Invoice Creation** with GST calculations
- **Stock Management** with low-stock alerts
- **Tally & Reports** with charts and analytics
- **Offline-capable** data models

### 🛒 Billing & Invoicing
- **GST Compliant Billing** with automatic tax calculations
- **Multi-item Invoices** with discount support
- **Customer Management** with contact details
- **Multiple Payment Methods** (Cash, Card, UPI, etc.)
- **Invoice Status Tracking** (Draft, Sent, Paid, etc.)

### 📦 Stock Management
- **Real-time Stock Tracking** with movement history
- **Low Stock Alerts** and reorder notifications
- **Stock Movements** (In/Out/Adjustments)
- **Location-based Storage** (Warehouse/Section/Shelf)
- **Automatic Stock Updates** on invoice creation

### 📊 Reports & Analytics
- **Daily/Monthly Sales Reports**
- **GST Reports** with rate-wise breakdown
- **Top Customers Analysis**
- **Product Sales Performance**
- **Payment Method Analytics**
- **Stock Summary Dashboard**

## Technology Stack

### Backend
- **Node.js** with Express.js framework
- **MongoDB** with Mongoose ODM
- **JWT** for authentication
- **bcryptjs** for password hashing
- **Helmet** for security headers
- **CORS** for cross-origin requests
- **Rate Limiting** for API protection

### Frontend (Flutter)
- **Flutter 3.0+** with Dart
- **Provider** for state management
- **HTTP** for API communication
- **Local Auth** for biometric authentication
- **FL Chart** for data visualization
- **Shared Preferences** for local storage
- **Material Design 3** components

### Database Models
- **Users** - Authentication and user management
- **Products** - Appliance catalog with specifications
- **Invoices** - Billing and customer data
- **Stock** - Inventory tracking and movements

## Project Structure

```
billing-system/
├── backend/                    # Node.js API Server
│   ├── models/                 # MongoDB/Mongoose models
│   │   ├── User.js            # User authentication model
│   │   ├── Product.js         # Product catalog model
│   │   ├── Invoice.js         # Invoice and billing model
│   │   └── Stock.js           # Stock management model
│   ├── routes/                 # API route handlers
│   │   ├── auth.js            # Authentication endpoints
│   │   ├── products.js        # Product CRUD operations
│   │   ├── invoices.js        # Invoice management
│   │   ├── stock.js           # Stock operations
│   │   └── tally.js           # Reports and analytics
│   ├── middleware/             # Custom middleware
│   │   └── auth.js            # JWT authentication middleware
│   ├── server.js              # Express server setup
│   ├── seedData.js            # Database seeding script
│   └── package.json           # Backend dependencies
│
└── flutter_app/               # Flutter Mobile Application
    ├── lib/
    │   ├── models/             # Data models
    │   │   ├── user.dart      # User model
    │   │   ├── product.dart   # Product model
    │   │   ├── invoice.dart   # Invoice model
    │   │   └── stock.dart     # Stock model
    │   ├── services/          # API and business logic
    │   │   ├── api_service.dart      # HTTP API client
    │   │   └── auth_service.dart     # Authentication service
    │   ├── screens/           # UI screens
    │   │   ├── login_screen.dart     # Login with biometric
    │   │   ├── dashboard_screen.dart # Main dashboard
    │   │   ├── billing_screen.dart   # Invoice creation
    │   │   ├── stock_screen.dart     # Stock management
    │   │   └── tally_screen.dart     # Reports and analytics
    │   └── main.dart          # App entry point
    └── pubspec.yaml          # Flutter dependencies
```

## Setup Instructions

### Prerequisites
- **Node.js** (v16 or higher)
- **MongoDB** (v5 or higher)
- **Flutter SDK** (v3.0 or higher)
- **Android Studio/VS Code** for Flutter development

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd billing-system/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Setup environment variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` file with your configuration:
   ```env
   PORT=3000
   MONGODB_URI=mongodb://localhost:27017/billing_system
   JWT_SECRET=your_secure_jwt_secret_here
   NODE_ENV=development
   ```

4. **Start MongoDB**
   ```bash
   # Using MongoDB Compass or command line
   mongod --dbpath /path/to/your/db
   ```

5. **Seed the database** (optional)
   ```bash
   node seedData.js
   ```

6. **Start the server**
   ```bash
   npm start
   # or for development with auto-restart
   npm run dev
   ```

### Flutter App Setup

1. **Navigate to Flutter directory**
   ```bash
   cd ../flutter_app
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Update API URL**
   Edit `lib/services/api_service.dart` and update the `baseUrl` to match your backend:
   ```dart
   static const String baseUrl = 'http://your-server-ip:3000/api';
   ```

4. **Run the app**
   ```bash
   # For debug mode
   flutter run
   
   # For release mode
   flutter run --release
   ```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/biometric-login` - Biometric authentication
- `POST /api/auth/register` - User registration
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/biometric` - Enable/disable biometric auth

### Products
- `GET /api/products` - Get all products (with pagination)
- `GET /api/products/:id` - Get single product
- `POST /api/products` - Create product (admin only)
- `PUT /api/products/:id` - Update product (admin only)
- `DELETE /api/products/:id` - Deactivate product (admin only)

### Invoices
- `GET /api/invoices` - Get all invoices
- `GET /api/invoices/:id` - Get single invoice
- `POST /api/invoices` - Create invoice
- `PUT /api/invoices/:id` - Update invoice
- `DELETE /api/invoices/:id` - Cancel invoice
- `GET /api/invoices/stats/summary` - Get invoice statistics

### Stock Management
- `GET /api/stock` - Get stock data
- `GET /api/stock/product/:id` - Get product stock
- `POST /api/stock` - Create stock entry (admin only)
- `PUT /api/stock/:id` - Update stock settings (admin only)
- `POST /api/stock/:id/movement` - Add stock movement
- `GET /api/stock/alerts/low-stock` - Get low stock alerts

### Reports & Analytics
- `GET /api/tally/daily/:date` - Daily sales report
- `GET /api/tally/monthly/:year/:month` - Monthly sales report
- `GET /api/tally/gst/:startDate/:endDate` - GST report
- `GET /api/tally/products/:startDate/:endDate` - Product sales report
- `GET /api/tally/customers/top/:limit` - Top customers
- `GET /api/tally/dashboard` - Dashboard analytics

## Default Credentials

After running the seed script, you can use these credentials:

**Admin User:**
- Username: `admin`
- Password: `admin123`
- Role: Administrator (full access)

**Cashier User:**
- Username: `cashier`
- Password: `cashier123`
- Role: User (limited access)

## GST Compliance

The system is designed to be GST compliant with:
- **Automatic GST calculation** based on product GST rates
- **GST-wise reporting** for tax filing
- **Invoice numbering** following GST guidelines
- **Customer GST details** capture
- **Tax summary reports** for accounting

## Security Features

- **JWT Authentication** with secure token storage
- **Password encryption** using bcryptjs
- **Biometric authentication** for enhanced security
- **Rate limiting** to prevent API abuse
- **Input validation** and sanitization
- **CORS protection** for API security
- **Environment-based configuration**

## Mobile App Features

### Dashboard
- Real-time sales overview
- Stock alerts and summaries
- Quick action buttons
- User profile management

### Billing Screen
- Product search and selection
- Real-time GST calculation
- Multiple payment methods
- Customer information capture
- Discount management

### Stock Management
- Current stock levels
- Low stock alerts
- Stock movement history
- Location tracking

### Reports & Analytics
- Sales performance charts
- GST reports
- Top customers
- Payment method analysis

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Check the API documentation
- Review the Flutter app documentation

## Roadmap

- [ ] **Invoice PDF Generation** with company branding
- [ ] **Barcode Scanning** for quick product selection
- [ ] **Customer Portal** for viewing purchase history
- [ ] **Multi-store Support** for chain operations
- [ ] **Advanced Analytics** with ML insights
- [ ] **Backup & Sync** functionality
- [ ] **Dark Mode** for the Flutter app
- [ ] **Push Notifications** for low stock alerts

---

**Built with ❤️ for appliances shop owners to streamline their billing and inventory management processes.**