const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  description: {
    type: String,
  },
  brand: {
    type: String,
    required: true,
  },
  category: {
    type: String,
    required: true,
  },
  price: {
    type: Number,
    required: true,
  },
  gstRate: {
    type: Number,
    required: true,
    default: 18, // Default GST rate
  },
  stock: {
    type: Number,
    required: true,
    default: 0,
  },
  minStockLevel: {
    type: Number,
    required: true,
    default: 5,
  },
  sku: {
    type: String,
    required: true,
    unique: true,
  },
}, {
  timestamps: true,
});

const Product = mongoose.model('Product', productSchema);

module.exports = Product;