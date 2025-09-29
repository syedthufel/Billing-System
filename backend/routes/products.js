const express = require('express');
const Product = require('../models/Product');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

const router = express.Router();

// Get all products with filtering, sorting, and pagination
router.get('/', authMiddleware, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      category,
      brand,
      search,
      minPrice,
      maxPrice,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      isActive = true
    } = req.query;

    const query = { isActive: isActive === 'true' };

    // Apply filters
    if (category) query.category = category;
    if (brand) query.brand = new RegExp(brand, 'i');
    if (minPrice || maxPrice) {
      query.sellingPrice = {};
      if (minPrice) query.sellingPrice.$gte = Number(minPrice);
      if (maxPrice) query.sellingPrice.$lte = Number(maxPrice);
    }

    // Search functionality
    if (search) {
      query.$text = { $search: search };
    }

    const options = {
      page: parseInt(page),
      limit: parseInt(limit),
      sort: { [sortBy]: sortOrder === 'desc' ? -1 : 1 }
    };

    const products = await Product.find(query)
      .sort(options.sort)
      .limit(options.limit * 1)
      .skip((options.page - 1) * options.limit);

    const total = await Product.countDocuments(query);

    res.json({
      products,
      totalPages: Math.ceil(total / options.limit),
      currentPage: options.page,
      total
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get single product by ID
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }
    res.json(product);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Create new product (admin only)
router.post('/', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const product = new Product({
      ...req.body,
      createdBy: req.user._id
    });
    
    await product.save();
    res.status(201).json(product);
  } catch (error) {
    if (error.code === 11000) {
      res.status(400).json({ error: 'Product with this SKU already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
});

// Update product (admin only)
router.put('/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { ...req.body, updatedAt: new Date() },
      { new: true, runValidators: true }
    );
    
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    res.json(product);
  } catch (error) {
    if (error.code === 11000) {
      res.status(400).json({ error: 'Product with this SKU already exists' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
});

// Delete product (admin only)
router.delete('/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true }
    );
    
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    res.json({ message: 'Product deactivated successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get products by category
router.get('/category/:category', authMiddleware, async (req, res) => {
  try {
    const { category } = req.params;
    const { page = 1, limit = 10 } = req.query;

    const products = await Product.find({
      category,
      isActive: true
    })
    .limit(limit * 1)
    .skip((page - 1) * limit)
    .sort({ createdAt: -1 });

    const total = await Product.countDocuments({ category, isActive: true });

    res.json({
      products,
      totalPages: Math.ceil(total / limit),
      currentPage: parseInt(page),
      total
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Search products
router.get('/search/:query', authMiddleware, async (req, res) => {
  try {
    const { query } = req.params;
    const { page = 1, limit = 10 } = req.query;

    const products = await Product.find({
      $text: { $search: query },
      isActive: true
    })
    .limit(limit * 1)
    .skip((page - 1) * limit)
    .sort({ score: { $meta: 'textScore' } });

    res.json({
      products,
      query,
      total: products.length
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;