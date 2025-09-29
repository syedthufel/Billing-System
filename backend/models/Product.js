const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  brand: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50
  },
  model: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50
  },
  category: {
    type: String,
    required: true,
    enum: ['refrigerator', 'washing-machine', 'air-conditioner', 'television', 'microwave', 'other'],
    default: 'other'
  },
  description: {
    type: String,
    trim: true,
    maxlength: 500
  },
  basePrice: {
    type: Number,
    required: true,
    min: 0
  },
  gstRate: {
    type: Number,
    required: true,
    min: 0,
    max: 100,
    default: 18 // Default GST rate for appliances
  },
  sellingPrice: {
    type: Number,
    required: true,
    min: 0
  },
  costPrice: {
    type: Number,
    required: true,
    min: 0
  },
  sku: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  barcode: {
    type: String,
    trim: true
  },
  warranty: {
    type: Number, // in months
    default: 12
  },
  specifications: {
    type: Map,
    of: String
  },
  isActive: {
    type: Boolean,
    default: true
  },
  images: [{
    type: String // URLs to product images
  }],
  tags: [{
    type: String,
    trim: true
  }]
}, {
  timestamps: true
});

// Virtual for calculated selling price including GST
productSchema.virtual('priceWithGST').get(function() {
  return this.basePrice + (this.basePrice * this.gstRate / 100);
});

// Virtual for GST amount
productSchema.virtual('gstAmount').get(function() {
  return this.basePrice * this.gstRate / 100;
});

// Ensure virtual fields are serialized
productSchema.set('toJSON', { virtuals: true });

// Index for search functionality
productSchema.index({ name: 'text', brand: 'text', model: 'text', description: 'text' });
productSchema.index({ category: 1, isActive: 1 });
productSchema.index({ sku: 1 });

module.exports = mongoose.model('Product', productSchema);