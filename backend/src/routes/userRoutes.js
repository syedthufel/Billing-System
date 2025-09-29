const express = require('express');
const {
  registerUser,
  loginUser,
  registerBiometric,
  loginWithBiometric,
  getCurrentUser,
} = require('../controllers/userController');
const { protect, admin } = require('../middleware/authMiddleware');

const router = express.Router();

router.route('/').post(registerUser);
router.post('/login', loginUser);
router.post('/login/biometric', loginWithBiometric);
router.route('/biometric').post(protect, registerBiometric);
router.route('/me').get(protect, getCurrentUser);

module.exports = router;