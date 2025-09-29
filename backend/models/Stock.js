const mongoose = require('mongoose');

const stockMovementSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['in', 'out', 'adjustment'],
    required: true
  },
  quantity: {
    type: Number,
    required: true
  },
  reason: {
    type: String,
    required: true,
    trim: true
  },
  reference: {
    type: String, // Invoice number, PO number, etc.
    trim: true
  },
  performedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
});

const stockSchema = new mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
    unique: true
  },
  currentStock: {
    type: Number,
    required: true,
    min: 0,
    default: 0
  },
  minimumStock: {
    type: Number,
    required: true,
    min: 0,
    default: 10
  },
  maximumStock: {
    type: Number,
    required: true,
    min: 0,
    default: 1000
  },
  reorderLevel: {
    type: Number,
    required: true,
    min: 0,
    default: 20
  },
  location: {
    warehouse: {
      type: String,
      default: 'Main'
    },
    section: {
      type: String,
      default: 'A'
    },
    shelf: {
      type: String,
      default: '1'
    }
  },
  movements: [stockMovementSchema],
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Virtual for stock status
stockSchema.virtual('stockStatus').get(function() {
  if (this.currentStock <= 0) return 'out-of-stock';
  if (this.currentStock <= this.reorderLevel) return 'low-stock';
  if (this.currentStock <= this.minimumStock) return 'minimum-reached';
  if (this.currentStock >= this.maximumStock) return 'overstock';
  return 'in-stock';
});

// Virtual for days since last movement
stockSchema.virtual('daysSinceLastMovement').get(function() {
  if (this.movements.length === 0) return null;
  const lastMovement = this.movements[this.movements.length - 1];
  const now = new Date();
  const diffTime = Math.abs(now - lastMovement.timestamp);
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
});

// Method to add stock movement
stockSchema.methods.addMovement = function(type, quantity, reason, reference, performedBy) {
  this.movements.push({
    type,
    quantity,
    reason,
    reference,
    performedBy,
    timestamp: new Date()
  });
  
  if (type === 'in') {
    this.currentStock += quantity;
  } else if (type === 'out') {
    this.currentStock = Math.max(0, this.currentStock - quantity);
  } else if (type === 'adjustment') {
    this.currentStock = quantity; // For adjustments, quantity is the new stock level
  }
  
  this.lastUpdated = new Date();
};

// Ensure virtual fields are serialized
stockSchema.set('toJSON', { virtuals: true });

// Indexes for better query performance
stockSchema.index({ product: 1 });
stockSchema.index({ currentStock: 1 });
stockSchema.index({ 'movements.timestamp': -1 });
stockSchema.index({ isActive: 1 });

module.exports = mongoose.model('Stock', stockSchema);