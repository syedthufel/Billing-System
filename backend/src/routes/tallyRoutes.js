const express = require('express');
const {
  getDailyTally,
  addExpense,
  closeDailyTally,
  getTallyReport,
} = require('../controllers/tallyController');
const { protect, admin } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/daily', protect, getDailyTally);
router.post('/expense', protect, admin, addExpense);
router.put('/close', protect, admin, closeDailyTally);
router.get('/report', protect, getTallyReport);

module.exports = router;