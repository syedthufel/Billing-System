const express = require('express');
const {
  createInvoice,
  getInvoices,
  getInvoiceById,
  updatePaymentStatus,
} = require('../controllers/invoiceController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router
  .route('/')
  .get(protect, getInvoices)
  .post(protect, createInvoice);

router
  .route('/:id')
  .get(protect, getInvoiceById);

router
  .route('/:id/payment')
  .put(protect, updatePaymentStatus);

module.exports = router;