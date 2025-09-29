const express = require('express');
const Stock = require('../models/Stock');
const Product = require('../models/Product');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

const router = express.Router();

// Get all stock with filtering and pagination
router.get('/', authMiddleware, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status, // 'low-stock', 'out-of-stock', etc.
      category,
      search,
      sortBy = 'currentStock',
      sortOrder = 'asc'
    } = req.query;

    let stockQuery = { isActive: true };
    let productQuery = { isActive: true };

    // Filter by category
    if (category) {
      productQuery.category = category;
    }

    // Search in product name, brand, or model
    if (search) {
      productQuery.$or = [
        { name: new RegExp(search, 'i') },
        { brand: new RegExp(search, 'i') },
        { model: new RegExp(search, 'i') }
      ];
    }

    const stocks = await Stock.find(stockQuery)
      .populate({
        path: 'product',
        match: productQuery,
        select: 'name brand model category sku basePrice sellingPrice'
      })
      .sort({ [sortBy]: sortOrder === 'desc' ? -1 : 1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    // Filter out stocks where product is null (due to category/search filter)
    const filteredStocks = stocks.filter(stock => stock.product !== null);

    // Apply status filter after population
    let finalStocks = filteredStocks;
    if (status) {
      finalStocks = filteredStocks.filter(stock => stock.stockStatus === status);
    }

    const total = finalStocks.length;

    res.json({
      stocks: finalStocks,
      totalPages: Math.ceil(total / limit),
      currentPage: parseInt(page),
      total
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get stock for a specific product
router.get('/product/:productId', authMiddleware, async (req, res) => {
  try {
    const stock = await Stock.findOne({ product: req.params.productId })
      .populate('product', 'name brand model sku category');

    if (!stock) {
      return res.status(404).json({ error: 'Stock not found for this product' });
    }

    res.json(stock);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Create stock entry for a product
router.post('/', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const {
      productId,
      currentStock,
      minimumStock,
      maximumStock,
      reorderLevel,
      location
    } = req.body;

    // Check if product exists
    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    // Check if stock already exists for this product
    const existingStock = await Stock.findOne({ product: productId });
    if (existingStock) {
      return res.status(400).json({ error: 'Stock already exists for this product' });
    }

    const stock = new Stock({
      product: productId,
      currentStock,
      minimumStock,
      maximumStock,
      reorderLevel,
      location,
      movements: [{
        type: 'in',
        quantity: currentStock,
        reason: 'Initial stock',
        performedBy: req.user._id,
        timestamp: new Date()
      }]
    });

    await stock.save();
    await stock.populate('product', 'name brand model sku category');

    res.status(201).json(stock);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Update stock levels
router.put('/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const {
      minimumStock,
      maximumStock,
      reorderLevel,
      location
    } = req.body;

    const stock = await Stock.findById(req.params.id);
    if (!stock) {
      return res.status(404).json({ error: 'Stock not found' });
    }

    // Update allowed fields
    if (minimumStock !== undefined) stock.minimumStock = minimumStock;
    if (maximumStock !== undefined) stock.maximumStock = maximumStock;
    if (reorderLevel !== undefined) stock.reorderLevel = reorderLevel;
    if (location !== undefined) stock.location = location;

    await stock.save();
    await stock.populate('product', 'name brand model sku category');

    res.json(stock);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Add stock movement (in/out/adjustment)
router.post('/:id/movement', authMiddleware, async (req, res) => {
  try {
    const { type, quantity, reason, reference } = req.body;

    if (!['in', 'out', 'adjustment'].includes(type)) {
      return res.status(400).json({ error: 'Invalid movement type' });
    }

    const stock = await Stock.findById(req.params.id);
    if (!stock) {
      return res.status(404).json({ error: 'Stock not found' });
    }

    stock.addMovement(type, quantity, reason, reference, req.user._id);
    await stock.save();
    await stock.populate('product', 'name brand model sku category');

    res.json({
      message: 'Stock movement added successfully',
      stock,
      movement: stock.movements[stock.movements.length - 1]
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get stock movements for a specific stock
router.get('/:id/movements', authMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const stock = await Stock.findById(req.params.id)
      .populate('movements.performedBy', 'username')
      .populate('product', 'name brand model sku');

    if (!stock) {
      return res.status(404).json({ error: 'Stock not found' });
    }

    // Sort movements by timestamp (newest first) and paginate
    const movements = stock.movements
      .sort((a, b) => b.timestamp - a.timestamp)
      .slice((page - 1) * limit, page * limit);

    res.json({
      movements,
      product: stock.product,
      totalMovements: stock.movements.length,
      currentPage: parseInt(page),
      totalPages: Math.ceil(stock.movements.length / limit)
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get low stock alerts
router.get('/alerts/low-stock', authMiddleware, async (req, res) => {
  try {
    const stocks = await Stock.find({ isActive: true })
      .populate('product', 'name brand model sku category');

    const lowStockItems = stocks.filter(stock => {
      return stock.product && (
        stock.currentStock <= stock.reorderLevel ||
        stock.currentStock <= stock.minimumStock
      );
    });

    res.json({
      alerts: lowStockItems.map(stock => ({
        _id: stock._id,
        product: stock.product,
        currentStock: stock.currentStock,
        reorderLevel: stock.reorderLevel,
        minimumStock: stock.minimumStock,
        status: stock.stockStatus,
        urgency: stock.currentStock <= stock.minimumStock ? 'high' : 'medium'
      })),
      count: lowStockItems.length
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get stock summary/dashboard data
router.get('/summary/dashboard', authMiddleware, async (req, res) => {
  try {
    const stocks = await Stock.find({ isActive: true })
      .populate('product', 'name brand category');

    const summary = {
      totalProducts: stocks.length,
      lowStockCount: 0,
      outOfStockCount: 0,
      overstockCount: 0,
      totalValue: 0,
      categories: {}
    };

    stocks.forEach(stock => {
      if (!stock.product) return;

      const status = stock.stockStatus;
      if (status === 'low-stock' || status === 'minimum-reached') {
        summary.lowStockCount++;
      } else if (status === 'out-of-stock') {
        summary.outOfStockCount++;
      } else if (status === 'overstock') {
        summary.overstockCount++;
      }

      // Category breakdown
      const category = stock.product.category;
      if (!summary.categories[category]) {
        summary.categories[category] = {
          count: 0,
          totalStock: 0
        };
      }
      summary.categories[category].count++;
      summary.categories[category].totalStock += stock.currentStock;
    });

    res.json(summary);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;