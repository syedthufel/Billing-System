const Invoice = require('../models/invoiceModel');
const Product = require('../models/productModel');
const StockMovement = require('../models/stockMovementModel');
const Tally = require('../models/tallyModel');

// @desc    Create new invoice
// @route   POST /api/invoices
// @access  Private
const createInvoice = async (req, res) => {
  try {
    const {
      customer,
      items,
      paymentMethod,
      paymentStatus,
    } = req.body;

    // Calculate totals
    let subtotal = 0;
    let totalGST = 0;
    let total = 0;

    // Validate stock and prepare stock updates
    for (const item of items) {
      const product = await Product.findById(item.product);
      if (!product) {
        return res.status(404).json({ message: `Product ${item.product} not found` });
      }
      if (product.stock < item.quantity) {
        return res.status(400).json({ message: `Insufficient stock for ${product.name}` });
      }

      // Calculate item totals
      const itemSubtotal = item.price * item.quantity;
      const itemGST = (itemSubtotal * item.gstRate) / 100;
      const itemTotal = itemSubtotal + itemGST;

      // Update running totals
      subtotal += itemSubtotal;
      totalGST += itemGST;
      total += itemTotal;

      // Update item with calculated values
      item.gstAmount = itemGST;
      item.total = itemTotal;
    }

    // Generate invoice number
    const count = await Invoice.countDocuments();
    const invoiceNumber = `INV${new Date().getFullYear()}${String(count + 1).padStart(6, '0')}`;

    // Create invoice
    const invoice = await Invoice.create({
      invoiceNumber,
      customer,
      items,
      subtotal,
      totalGST,
      total,
      paymentMethod,
      paymentStatus,
      createdBy: req.user._id,
    });

    // Update stock and create stock movements
    for (const item of items) {
      const product = await Product.findById(item.product);
      const previousStock = product.stock;
      const newStock = previousStock - item.quantity;

      // Create stock movement
      await StockMovement.create({
        product: product._id,
        type: 'out',
        quantity: item.quantity,
        previousStock,
        newStock,
        reference: invoice.invoiceNumber,
        remarks: `Sale: ${invoice.invoiceNumber}`,
        createdBy: req.user._id,
      });

      // Update product stock
      product.stock = newStock;
      await product.save();
    }

    // Update or create daily tally
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tally = await Tally.findOne({ date: today });
    if (tally) {
      tally.sales[paymentMethod] += total;
      tally.invoices.push(invoice._id);
      await tally.save();
    } else {
      await Tally.create({
        date: today,
        sales: {
          [paymentMethod]: total,
        },
        invoices: [invoice._id],
      });
    }

    res.status(201).json(invoice);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all invoices
// @route   GET /api/invoices
// @access  Private
const getInvoices = async (req, res) => {
  try {
    const invoices = await Invoice.find({})
      .populate('createdBy', 'name')
      .sort({ createdAt: -1 });
    res.json(invoices);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get invoice by ID
// @route   GET /api/invoices/:id
// @access  Private
const getInvoiceById = async (req, res) => {
  try {
    const invoice = await Invoice.findById(req.params.id)
      .populate('items.product')
      .populate('createdBy', 'name');

    if (invoice) {
      res.json(invoice);
    } else {
      res.status(404).json({ message: 'Invoice not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update invoice payment status
// @route   PUT /api/invoices/:id/payment
// @access  Private
const updatePaymentStatus = async (req, res) => {
  try {
    const { paymentStatus, paymentMethod } = req.body;

    const invoice = await Invoice.findById(req.params.id);

    if (invoice) {
      // If payment method is being changed, update tally
      if (paymentMethod && paymentMethod !== invoice.paymentMethod) {
        const date = new Date(invoice.createdAt);
        date.setHours(0, 0, 0, 0);

        const tally = await Tally.findOne({ date });
        if (tally) {
          // Subtract from old payment method
          tally.sales[invoice.paymentMethod] -= invoice.total;
          // Add to new payment method
          tally.sales[paymentMethod] += invoice.total;
          await tally.save();
        }

        invoice.paymentMethod = paymentMethod;
      }

      invoice.paymentStatus = paymentStatus;
      const updatedInvoice = await invoice.save();

      res.json(updatedInvoice);
    } else {
      res.status(404).json({ message: 'Invoice not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createInvoice,
  getInvoices,
  getInvoiceById,
  updatePaymentStatus,
};