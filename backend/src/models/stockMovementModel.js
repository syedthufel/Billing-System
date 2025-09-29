const mongoose = require('mongoose');

const stockMovementSchema = new mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
  type: {
    type: String,
    required: true,
    enum: ['in', 'out'],
  },
  quantity: {
    type: Number,
    required: true,
  },
  reference: {
    type: String, // Can be invoice number or purchase order number
  },
  previousStock: {
    type: Number,
    required: true,
  },
  newStock: {
    type: Number,
    required: true,
  },
  remarks: String,
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
}, {
  timestamps: true,
});

const StockMovement = mongoose.model('StockMovement', stockMovementSchema);

module.exports = StockMovement;