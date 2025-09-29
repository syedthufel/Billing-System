const mongoose = require('mongoose');

const tallySchema = new mongoose.Schema({
  date: {
    type: Date,
    required: true,
    unique: true,
  },
  sales: {
    total: {
      type: Number,
      required: true,
      default: 0,
    },
    cash: {
      type: Number,
      required: true,
      default: 0,
    },
    card: {
      type: Number,
      required: true,
      default: 0,
    },
    upi: {
      type: Number,
      required: true,
      default: 0,
    },
    other: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  expenses: [{
    description: {
      type: String,
      required: true,
    },
    amount: {
      type: Number,
      required: true,
    },
    category: {
      type: String,
      required: true,
      enum: ['utilities', 'rent', 'salary', 'inventory', 'maintenance', 'other'],
    },
    paymentMethod: {
      type: String,
      required: true,
      enum: ['cash', 'card', 'upi', 'other'],
    },
  }],
  totalExpenses: {
    type: Number,
    required: true,
    default: 0,
  },
  netAmount: {
    type: Number,
    required: true,
    default: 0,
  },
  invoices: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Invoice',
  }],
  remarks: String,
  closedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  isClosed: {
    type: Boolean,
    default: false,
  },
}, {
  timestamps: true,
});

// Calculate totals before saving
tallySchema.pre('save', function(next) {
  // Calculate total sales
  this.sales.total = this.sales.cash + this.sales.card + this.sales.upi + this.sales.other;

  // Calculate total expenses
  this.totalExpenses = this.expenses.reduce((sum, expense) => sum + expense.amount, 0);

  // Calculate net amount
  this.netAmount = this.sales.total - this.totalExpenses;

  next();
});

const Tally = mongoose.model('Tally', tallySchema);

module.exports = Tally;