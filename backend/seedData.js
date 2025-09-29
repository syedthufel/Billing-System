const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('./models/User');
const Product = require('./models/Product');
const Stock = require('./models/Stock');

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/billing_system', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('Connected to MongoDB'))
.catch((error) => console.error('MongoDB connection error:', error));

const seedData = async () => {
  try {
    console.log('Starting to seed database...');

    // Clear existing data
    await User.deleteMany({});
    await Product.deleteMany({});
    await Stock.deleteMany({});

    console.log('Cleared existing data');

    // Create admin user
    const adminUser = new User({
      username: 'admin',
      email: 'admin@billingsystem.com',
      password: 'admin123',
      role: 'admin',
      biometricEnabled: false
    });
    await adminUser.save();
    console.log('Created admin user');

    // Create regular user
    const regularUser = new User({
      username: 'cashier',
      email: 'cashier@billingsystem.com',
      password: 'cashier123',
      role: 'user',
      biometricEnabled: false
    });
    await regularUser.save();
    console.log('Created cashier user');

    // Create sample products
    const products = [
      {
        name: 'Samsung 32" Smart TV',
        brand: 'Samsung',
        model: 'UA32T4400',
        category: 'television',
        description: '32 inch LED Smart TV with built-in WiFi',
        basePrice: 15000,
        gstRate: 28,
        sellingPrice: 19200,
        costPrice: 12000,
        sku: 'SAM-TV-32-001',
        warranty: 24,
        specifications: {
          'Screen Size': '32 inches',
          'Resolution': '1920x1080',
          'Smart TV': 'Yes',
          'Connectivity': 'WiFi, HDMI, USB'
        }
      },
      {
        name: 'LG 190L Refrigerator',
        brand: 'LG',
        model: 'GL-B201ASPY',
        category: 'refrigerator',
        description: 'Single door refrigerator with direct cool technology',
        basePrice: 12000,
        gstRate: 18,
        sellingPrice: 14160,
        costPrice: 10000,
        sku: 'LG-REF-190-001',
        warranty: 12,
        specifications: {
          'Capacity': '190 Liters',
          'Type': 'Single Door',
          'Cooling': 'Direct Cool',
          'Energy Rating': '3 Star'
        }
      },
      {
        name: 'Whirlpool 7kg Washing Machine',
        brand: 'Whirlpool',
        model: 'WHITEMAGIC ROYAL 7.0',
        category: 'washing-machine',
        description: 'Semi-automatic washing machine with lint filter',
        basePrice: 8000,
        gstRate: 28,
        sellingPrice: 10240,
        costPrice: 6500,
        sku: 'WP-WM-7KG-001',
        warranty: 24,
        specifications: {
          'Capacity': '7 kg',
          'Type': 'Semi Automatic',
          'Wash Programs': '3',
          'Material': 'Plastic Body'
        }
      },
      {
        name: 'Voltas 1.5 Ton AC',
        brand: 'Voltas',
        model: '183V DZA',
        category: 'air-conditioner',
        description: 'Split AC with copper condenser and R32 refrigerant',
        basePrice: 25000,
        gstRate: 28,
        sellingPrice: 32000,
        costPrice: 22000,
        sku: 'VOL-AC-1.5T-001',
        warranty: 12,
        specifications: {
          'Capacity': '1.5 Ton',
          'Type': 'Split AC',
          'Refrigerant': 'R32',
          'Energy Rating': '3 Star',
          'Condenser': 'Copper'
        }
      },
      {
        name: 'IFB 20L Microwave',
        brand: 'IFB',
        model: '20SC2',
        category: 'microwave',
        description: 'Solo microwave with multiple power levels',
        basePrice: 5000,
        gstRate: 18,
        sellingPrice: 5900,
        costPrice: 4200,
        sku: 'IFB-MW-20L-001',
        warranty: 12,
        specifications: {
          'Capacity': '20 Liters',
          'Type': 'Solo',
          'Power': '700W',
          'Control': 'Mechanical'
        }
      }
    ];

    const createdProducts = [];
    for (const productData of products) {
      const product = new Product(productData);
      await product.save();
      createdProducts.push(product);
    }
    console.log(`Created ${createdProducts.length} products`);

    // Create stock for each product
    for (const product of createdProducts) {
      const stock = new Stock({
        product: product._id,
        currentStock: Math.floor(Math.random() * 50) + 10, // Random stock between 10-60
        minimumStock: 5,
        maximumStock: 100,
        reorderLevel: 15,
        location: {
          warehouse: 'Main',
          section: ['A', 'B', 'C'][Math.floor(Math.random() * 3)],
          shelf: String(Math.floor(Math.random() * 10) + 1)
        },
        movements: [{
          type: 'in',
          quantity: Math.floor(Math.random() * 50) + 10,
          reason: 'Initial stock',
          performedBy: adminUser._id,
          timestamp: new Date()
        }]
      });
      await stock.save();
    }
    console.log(`Created stock entries for ${createdProducts.length} products`);

    console.log('\n=== SEED DATA COMPLETE ===');
    console.log('Admin credentials:');
    console.log('  Username: admin');
    console.log('  Password: admin123');
    console.log('');
    console.log('Cashier credentials:');
    console.log('  Username: cashier');
    console.log('  Password: cashier123');
    console.log('');
    console.log(`Created ${createdProducts.length} products with stock data`);
    console.log('Server is ready for testing!');

  } catch (error) {
    console.error('Error seeding database:', error);
  } finally {
    mongoose.connection.close();
  }
};

seedData();