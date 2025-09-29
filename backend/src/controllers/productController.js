const Product = require('../models/productModel');
const StockMovement = require('../models/stockMovementModel');

// @desc    Get all products
// @route   GET /api/products
// @access  Private
const getProducts = async (req, res) => {
  try {
    const products = await Product.find({});
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get single product
// @route   GET /api/products/:id
// @access  Private
const getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (product) {
      res.json(product);
    } else {
      res.status(404).json({ message: 'Product not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Create a product
// @route   POST /api/products
// @access  Private/Admin
const createProduct = async (req, res) => {
  try {
    const {
      name,
      description,
      brand,
      category,
      price,
      gstRate,
      stock,
      minStockLevel,
      sku,
    } = req.body;

    const product = await Product.create({
      name,
      description,
      brand,
      category,
      price,
      gstRate,
      stock,
      minStockLevel,
      sku,
    });

    // Record initial stock movement if stock > 0
    if (stock > 0) {
      await StockMovement.create({
        product: product._id,
        type: 'in',
        quantity: stock,
        previousStock: 0,
        newStock: stock,
        remarks: 'Initial stock',
        createdBy: req.user._id,
      });
    }

    res.status(201).json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update product stock
// @route   PUT /api/products/:id/stock
// @access  Private/Admin
const updateStock = async (req, res) => {
  try {
    const { quantity, type, remarks } = req.body;
    
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    const previousStock = product.stock;
    let newStock;

    if (type === 'in') {
      newStock = previousStock + quantity;
    } else if (type === 'out') {
      if (quantity > previousStock) {
        return res.status(400).json({ message: 'Insufficient stock' });
      }
      newStock = previousStock - quantity;
    }

    // Create stock movement record
    await StockMovement.create({
      product: product._id,
      type,
      quantity,
      previousStock,
      newStock,
      remarks,
      createdBy: req.user._id,
    });

    // Update product stock
    product.stock = newStock;
    await product.save();

    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get stock movement history for a product
// @route   GET /api/products/:id/stock-history
// @access  Private
const getStockHistory = async (req, res) => {
  try {
    const stockHistory = await StockMovement.find({ product: req.params.id })
      .populate('createdBy', 'name')
      .sort({ createdAt: -1 });

    res.json(stockHistory);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a product
// @route   PUT /api/products/:id
// @access  Private/Admin
const updateProduct = async (req, res) => {
  try {
    const {
      name,
      description,
      brand,
      category,
      price,
      gstRate,
      minStockLevel,
      sku,
    } = req.body;

    const product = await Product.findById(req.params.id);

    if (product) {
      product.name = name || product.name;
      product.description = description || product.description;
      product.brand = brand || product.brand;
      product.category = category || product.category;
      product.price = price || product.price;
      product.gstRate = gstRate || product.gstRate;
      product.minStockLevel = minStockLevel || product.minStockLevel;
      product.sku = sku || product.sku;

      const updatedProduct = await product.save();
      res.json(updatedProduct);
    } else {
      res.status(404).json({ message: 'Product not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a product
// @route   DELETE /api/products/:id
// @access  Private/Admin
const deleteProduct = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);

    if (product) {
      await product.deleteOne();
      res.json({ message: 'Product removed' });
    } else {
      res.status(404).json({ message: 'Product not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
  updateStock,
  getStockHistory,
};