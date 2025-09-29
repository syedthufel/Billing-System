const express = require('express');
const Invoice = require('../models/Invoice');
const Product = require('../models/Product');
const Stock = require('../models/Stock');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

const router = express.Router();

// Get all invoices with filtering and pagination
router.get('/', authMiddleware, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      paymentStatus,
      startDate,
      endDate,
      customer,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const query = {};

    // Apply filters
    if (status) query.status = status;
    if (paymentStatus) query.paymentStatus = paymentStatus;
    if (customer) {
      query.$or = [
        { 'customerInfo.name': new RegExp(customer, 'i') },
        { 'customerInfo.phone': new RegExp(customer, 'i') },
        { 'customerInfo.email': new RegExp(customer, 'i') }
      ];
    }

    // Date range filter
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const options = {
      page: parseInt(page),
      limit: parseInt(limit),
      sort: { [sortBy]: sortOrder === 'desc' ? -1 : 1 }
    };

    const invoices = await Invoice.find(query)
      .populate('createdBy', 'username email')
      .sort(options.sort)
      .limit(options.limit * 1)
      .skip((options.page - 1) * options.limit);

    const total = await Invoice.countDocuments(query);

    res.json({
      invoices,
      totalPages: Math.ceil(total / options.limit),
      currentPage: options.page,
      total
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get single invoice by ID
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const invoice = await Invoice.findById(req.params.id)
      .populate('createdBy', 'username email')
      .populate('items.product', 'name brand model');

    if (!invoice) {
      return res.status(404).json({ error: 'Invoice not found' });
    }

    res.json(invoice);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Create new invoice
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { customerInfo, items, paymentMethod, notes } = req.body;

    // Validate and calculate totals
    let subtotal = 0;
    let totalGST = 0;
    let totalDiscount = 0;
    const processedItems = [];

    for (const item of items) {
      const product = await Product.findById(item.productId);
      if (!product) {
        return res.status(400).json({ 
          error: `Product not found: ${item.productId}` 
        });
      }

      // Check stock availability
      const stock = await Stock.findOne({ product: product._id });
      if (!stock || stock.currentStock < item.quantity) {
        return res.status(400).json({
          error: `Insufficient stock for ${product.name}. Available: ${stock?.currentStock || 0}`
        });
      }

      const itemSubtotal = product.basePrice * item.quantity;
      const itemGST = itemSubtotal * (product.gstRate / 100);
      const itemDiscount = item.discount || 0;
      const itemTotal = itemSubtotal + itemGST - itemDiscount;

      processedItems.push({
        product: product._id,
        productName: product.name,
        sku: product.sku,
        quantity: item.quantity,
        unitPrice: product.basePrice,
        gstRate: product.gstRate,
        gstAmount: itemGST,
        totalAmount: itemTotal,
        discount: itemDiscount
      });

      subtotal += itemSubtotal;
      totalGST += itemGST;
      totalDiscount += itemDiscount;
    }

    const grandTotal = subtotal + totalGST - totalDiscount;

    const invoice = new Invoice({
      customerInfo,
      items: processedItems,
      subtotal,
      totalGST,
      totalDiscount,
      grandTotal,
      paymentMethod,
      notes,
      createdBy: req.user._id
    });

    await invoice.save();

    // Update stock for each item
    for (const item of processedItems) {
      const stock = await Stock.findOne({ product: item.product });
      stock.addMovement('out', item.quantity, `Invoice: ${invoice.invoiceNumber}`, invoice.invoiceNumber, req.user._id);
      await stock.save();
    }

    res.status(201).json(invoice);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Update invoice
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const invoice = await Invoice.findById(req.params.id);
    if (!invoice) {
      return res.status(404).json({ error: 'Invoice not found' });
    }

    // Only allow updates to certain fields and only if invoice is in draft
    if (invoice.status !== 'draft') {
      return res.status(400).json({ 
        error: 'Only draft invoices can be updated' 
      });
    }

    const allowedUpdates = ['customerInfo', 'paymentMethod', 'notes', 'status', 'paymentStatus'];
    const updates = {};
    
    Object.keys(req.body).forEach(key => {
      if (allowedUpdates.includes(key)) {
        updates[key] = req.body[key];
      }
    });

    Object.assign(invoice, updates);
    await invoice.save();

    res.json(invoice);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Cancel invoice
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const invoice = await Invoice.findById(req.params.id);
    if (!invoice) {
      return res.status(404).json({ error: 'Invoice not found' });
    }

    if (invoice.status === 'paid') {
      return res.status(400).json({ 
        error: 'Cannot cancel paid invoices' 
      });
    }

    // Restore stock if invoice was not draft
    if (invoice.status !== 'draft') {
      for (const item of invoice.items) {
        const stock = await Stock.findOne({ product: item.product });
        if (stock) {
          stock.addMovement('in', item.quantity, `Invoice cancelled: ${invoice.invoiceNumber}`, invoice.invoiceNumber, req.user._id);
          await stock.save();
        }
      }
    }

    invoice.status = 'cancelled';
    await invoice.save();

    res.json({ message: 'Invoice cancelled successfully', invoice });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get invoice statistics
router.get('/stats/summary', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const dateFilter = {};
    
    if (startDate || endDate) {
      dateFilter.createdAt = {};
      if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
      if (endDate) dateFilter.createdAt.$lte = new Date(endDate);
    }

    const stats = await Invoice.aggregate([
      { $match: dateFilter },
      {
        $group: {
          _id: null,
          totalInvoices: { $sum: 1 },
          totalRevenue: { $sum: '$grandTotal' },
          totalGST: { $sum: '$totalGST' },
          avgInvoiceValue: { $avg: '$grandTotal' },
          paidInvoices: {
            $sum: { $cond: [{ $eq: ['$paymentStatus', 'paid'] }, 1, 0] }
          },
          pendingInvoices: {
            $sum: { $cond: [{ $eq: ['$paymentStatus', 'pending'] }, 1, 0] }
          }
        }
      }
    ]);

    res.json(stats[0] || {
      totalInvoices: 0,
      totalRevenue: 0,
      totalGST: 0,
      avgInvoiceValue: 0,
      paidInvoices: 0,
      pendingInvoices: 0
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;