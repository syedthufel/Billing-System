const express = require('express');
const {
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
  updateStock,
  getStockHistory,
} = require('../controllers/productController');
const { protect, admin } = require('../middleware/authMiddleware');

const router = express.Router();

router
  .route('/')
  .get(protect, getProducts)
  .post(protect, admin, createProduct);

router
  .route('/:id')
  .get(protect, getProductById)
  .put(protect, admin, updateProduct)
  .delete(protect, admin, deleteProduct);

router
  .route('/:id/stock')
  .put(protect, admin, updateStock);

router
  .route('/:id/stock-history')
  .get(protect, getStockHistory);

module.exports = router;