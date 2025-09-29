const Tally = require('../models/tallyModel');

// @desc    Get daily tally
// @route   GET /api/tally/daily
// @access  Private
const getDailyTally = async (req, res) => {
  try {
    const { date } = req.query;
    const searchDate = date ? new Date(date) : new Date();
    searchDate.setHours(0, 0, 0, 0);

    const tally = await Tally.findOne({ date: searchDate })
      .populate('invoices')
      .populate('closedBy', 'name');

    if (tally) {
      res.json(tally);
    } else {
      // If no tally exists for the date, create a new one
      const newTally = await Tally.create({
        date: searchDate,
      });
      res.json(newTally);
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Add expense to daily tally
// @route   POST /api/tally/expense
// @access  Private
const addExpense = async (req, res) => {
  try {
    const { date, description, amount, category, paymentMethod } = req.body;

    const searchDate = new Date(date);
    searchDate.setHours(0, 0, 0, 0);

    let tally = await Tally.findOne({ date: searchDate });

    if (!tally) {
      tally = await Tally.create({
        date: searchDate,
      });
    }

    tally.expenses.push({
      description,
      amount,
      category,
      paymentMethod,
    });

    // Update total expenses
    tally.totalExpenses = tally.expenses.reduce((sum, exp) => sum + exp.amount, 0);
    
    // Update net amount
    tally.netAmount = tally.sales.total - tally.totalExpenses;

    const updatedTally = await tally.save();
    res.json(updatedTally);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Close daily tally
// @route   PUT /api/tally/close
// @access  Private/Admin
const closeDailyTally = async (req, res) => {
  try {
    const { date, remarks } = req.body;

    const searchDate = new Date(date);
    searchDate.setHours(0, 0, 0, 0);

    const tally = await Tally.findOne({ date: searchDate });

    if (!tally) {
      return res.status(404).json({ message: 'Tally not found for the specified date' });
    }

    if (tally.isClosed) {
      return res.status(400).json({ message: 'Tally is already closed for this date' });
    }

    tally.isClosed = true;
    tally.closedBy = req.user._id;
    if (remarks) {
      tally.remarks = remarks;
    }

    const updatedTally = await tally.save();
    res.json(updatedTally);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get tally report by date range
// @route   GET /api/tally/report
// @access  Private
const getTallyReport = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const start = new Date(startDate);
    start.setHours(0, 0, 0, 0);

    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const tallies = await Tally.find({
      date: {
        $gte: start,
        $lte: end,
      },
    }).sort({ date: 1 });

    // Calculate summary
    const summary = tallies.reduce((acc, tally) => {
      acc.totalSales += tally.sales.total;
      acc.totalExpenses += tally.totalExpenses;
      acc.netAmount += tally.netAmount;
      
      // Payment method breakdown
      acc.salesByMethod.cash += tally.sales.cash;
      acc.salesByMethod.card += tally.sales.card;
      acc.salesByMethod.upi += tally.sales.upi;
      acc.salesByMethod.other += tally.sales.other;

      // Expense category breakdown
      tally.expenses.forEach(expense => {
        acc.expensesByCategory[expense.category] = 
          (acc.expensesByCategory[expense.category] || 0) + expense.amount;
      });

      return acc;
    }, {
      totalSales: 0,
      totalExpenses: 0,
      netAmount: 0,
      salesByMethod: {
        cash: 0,
        card: 0,
        upi: 0,
        other: 0,
      },
      expensesByCategory: {},
    });

    res.json({
      tallies,
      summary,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getDailyTally,
  addExpense,
  closeDailyTally,
  getTallyReport,
};