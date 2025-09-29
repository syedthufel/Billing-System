const express = require('express');
const Invoice = require('../models/Invoice');
const Product = require('../models/Product');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

const router = express.Router();

// Get daily sales tally
router.get('/daily/:date', authMiddleware, async (req, res) => {
  try {
    const { date } = req.params;
    const startDate = new Date(date);
    const endDate = new Date(date);
    endDate.setDate(endDate.getDate() + 1);

    const dailySales = await Invoice.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate, $lt: endDate },
          status: { $ne: 'cancelled' }
        }
      },
      {
        $group: {
          _id: null,
          totalInvoices: { $sum: 1 },
          totalRevenue: { $sum: '$grandTotal' },
          totalGST: { $sum: '$totalGST' },
          totalDiscount: { $sum: '$totalDiscount' },
          paidAmount: {
            $sum: {
              $cond: [
                { $eq: ['$paymentStatus', 'paid'] },
                '$grandTotal',
                0
              ]
            }
          },
          pendingAmount: {
            $sum: {
              $cond: [
                { $eq: ['$paymentStatus', 'pending'] },
                '$grandTotal',
                0
              ]
            }
          }
        }
      }
    ]);

    const result = dailySales[0] || {
      totalInvoices: 0,
      totalRevenue: 0,
      totalGST: 0,
      totalDiscount: 0,
      paidAmount: 0,
      pendingAmount: 0
    };

    res.json({
      date,
      ...result,
      netRevenue: result.totalRevenue - result.totalGST
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get monthly sales tally
router.get('/monthly/:year/:month', authMiddleware, async (req, res) => {
  try {
    const { year, month } = req.params;
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 1);

    const monthlySales = await Invoice.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate, $lt: endDate },
          status: { $ne: 'cancelled' }
        }
      },
      {
        $group: {
          _id: { $dayOfMonth: '$createdAt' },
          date: { $first: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } } },
          totalInvoices: { $sum: 1 },
          totalRevenue: { $sum: '$grandTotal' },
          totalGST: { $sum: '$totalGST' },
          paidAmount: {
            $sum: {
              $cond: [
                { $eq: ['$paymentStatus', 'paid'] },
                '$grandTotal',
                0
              ]
            }
          }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // Calculate monthly totals
    const monthlyTotals = await Invoice.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate, $lt: endDate },
          status: { $ne: 'cancelled' }
        }
      },
      {
        $group: {
          _id: null,
          totalInvoices: { $sum: 1 },
          totalRevenue: { $sum: '$grandTotal' },
          totalGST: { $sum: '$totalGST' },
          totalDiscount: { $sum: '$totalDiscount' },
          paidAmount: {
            $sum: {
              $cond: [
                { $eq: ['$paymentStatus', 'paid'] },
                '$grandTotal',
                0
              ]
            }
          }
        }
      }
    ]);

    res.json({
      year: parseInt(year),
      month: parseInt(month),
      dailyBreakdown: monthlySales,
      monthlyTotals: monthlyTotals[0] || {
        totalInvoices: 0,
        totalRevenue: 0,
        totalGST: 0,
        totalDiscount: 0,
        paidAmount: 0
      }
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get GST report
router.get('/gst/:startDate/:endDate', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate } = req.params;
    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setDate(end.getDate() + 1);

    const gstReport = await Invoice.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lt: end },
          status: { $ne: 'cancelled' }
        }
      },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.gstRate',
          totalTaxableAmount: { $sum: '$items.unitPrice' },
          totalGSTAmount: { $sum: '$items.gstAmount' },
          totalTransactions: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    const totalGST = await Invoice.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lt: end },
          status: { $ne: 'cancelled' }
        }
      },
      {
        $group: {
          _id: null,
          totalGSTCollected: { $sum: '$totalGST' },
          totalTaxableAmount: { $sum: '$subtotal' },
          totalInvoices: { $sum: 1 }
        }
      }
    ]);

    res.json({
      period: { startDate, endDate },
      gstBreakdown: gstReport,
      summary: totalGST[0] || {
        totalGSTCollected: 0,
        totalTaxableAmount: 0,
        totalInvoices: 0
      }
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get product-wise sales report
router.get('/products/:startDate/:endDate', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate } = req.params;
    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setDate(end.getDate() + 1);

    const productSales = await Invoice.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lt: end },
          status: { $ne: 'cancelled' }
        }
      },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.product',
          productName: { $first: '$items.productName' },
          sku: { $first: '$items.sku' },
          totalQuantity: { $sum: '$items.quantity' },
          totalRevenue: { $sum: '$items.totalAmount' },
          totalGST: { $sum: '$items.gstAmount' },
          averagePrice: { $avg: '$items.unitPrice' },
          transactionCount: { $sum: 1 }
        }
      },
      { $sort: { totalRevenue: -1 } }
    ]);

    // Get additional product details
    const enrichedResults = await Product.populate(productSales, {
      path: '_id',
      select: 'name brand category'
    });

    res.json({
      period: { startDate, endDate },
      productSales: enrichedResults,
      totalProducts: enrichedResults.length
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get payment method wise analysis
router.get('/payments/:startDate/:endDate', authMiddleware, async (req, res) => {
  try {
    const { startDate, endDate } = req.params;
    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setDate(end.getDate() + 1);

    const paymentAnalysis = await Invoice.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lt: end },
          status: { $ne: 'cancelled' }
        }
      },
      {
        $group: {
          _id: '$paymentMethod',
          totalAmount: { $sum: '$grandTotal' },
          transactionCount: { $sum: 1 },
          averageAmount: { $avg: '$grandTotal' },
          paidTransactions: {
            $sum: {
              $cond: [
                { $eq: ['$paymentStatus', 'paid'] },
                1,
                0
              ]
            }
          },
          paidAmount: {
            $sum: {
              $cond: [
                { $eq: ['$paymentStatus', 'paid'] },
                '$grandTotal',
                0
              ]
            }
          }
        }
      },
      { $sort: { totalAmount: -1 } }
    ]);

    res.json({
      period: { startDate, endDate },
      paymentMethods: paymentAnalysis
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get top customers report
router.get('/customers/top/:limit?', authMiddleware, async (req, res) => {
  try {
    const limit = parseInt(req.params.limit) || 10;
    const { startDate, endDate } = req.query;

    let matchStage = { status: { $ne: 'cancelled' } };
    
    if (startDate || endDate) {
      matchStage.createdAt = {};
      if (startDate) matchStage.createdAt.$gte = new Date(startDate);
      if (endDate) {
        const end = new Date(endDate);
        end.setDate(end.getDate() + 1);
        matchStage.createdAt.$lt = end;
      }
    }

    const topCustomers = await Invoice.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: {
            phone: '$customerInfo.phone',
            name: '$customerInfo.name',
            email: '$customerInfo.email'
          },
          totalPurchases: { $sum: '$grandTotal' },
          totalInvoices: { $sum: 1 },
          averagePurchase: { $avg: '$grandTotal' },
          lastPurchase: { $max: '$createdAt' },
          totalGSTSaved: { $sum: '$totalGST' }
        }
      },
      { $sort: { totalPurchases: -1 } },
      { $limit: limit }
    ]);

    res.json({
      topCustomers,
      period: startDate || endDate ? { startDate, endDate } : 'All time'
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get comprehensive dashboard data
router.get('/dashboard', authMiddleware, async (req, res) => {
  try {
    const today = new Date();
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const startOfYear = new Date(today.getFullYear(), 0, 1);

    // Today's data
    const todayStart = new Date(today.setHours(0, 0, 0, 0));
    const todayEnd = new Date(today.setHours(23, 59, 59, 999));

    const [todayStats, monthStats, yearStats] = await Promise.all([
      // Today's statistics
      Invoice.aggregate([
        {
          $match: {
            createdAt: { $gte: todayStart, $lte: todayEnd },
            status: { $ne: 'cancelled' }
          }
        },
        {
          $group: {
            _id: null,
            totalSales: { $sum: '$grandTotal' },
            totalInvoices: { $sum: 1 },
            totalGST: { $sum: '$totalGST' }
          }
        }
      ]),

      // This month's statistics
      Invoice.aggregate([
        {
          $match: {
            createdAt: { $gte: startOfMonth },
            status: { $ne: 'cancelled' }
          }
        },
        {
          $group: {
            _id: null,
            totalSales: { $sum: '$grandTotal' },
            totalInvoices: { $sum: 1 },
            totalGST: { $sum: '$totalGST' }
          }
        }
      ]),

      // This year's statistics
      Invoice.aggregate([
        {
          $match: {
            createdAt: { $gte: startOfYear },
            status: { $ne: 'cancelled' }
          }
        },
        {
          $group: {
            _id: null,
            totalSales: { $sum: '$grandTotal' },
            totalInvoices: { $sum: 1 },
            totalGST: { $sum: '$totalGST' }
          }
        }
      ])
    ]);

    res.json({
      today: todayStats[0] || { totalSales: 0, totalInvoices: 0, totalGST: 0 },
      thisMonth: monthStats[0] || { totalSales: 0, totalInvoices: 0, totalGST: 0 },
      thisYear: yearStats[0] || { totalSales: 0, totalInvoices: 0, totalGST: 0 },
      generatedAt: new Date()
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;