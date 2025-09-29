const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Register new user (admin only in production)
router.post('/register', async (req, res) => {
  try {
    const { username, email, password, role = 'user' } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email }, { username }]
    });

    if (existingUser) {
      return res.status(400).json({
        error: 'User with this email or username already exists'
      });
    }

    // Create new user
    const user = new User({
      username,
      email,
      password,
      role
    });

    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'default_secret',
      { expiresIn: '24h' }
    );

    res.status(201).json({
      message: 'User registered successfully',
      user,
      token
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    // Find user by username or email
    const user = await User.findOne({
      $or: [{ username }, { email: username }],
      isActive: true
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'default_secret',
      { expiresIn: '24h' }
    );

    res.json({
      message: 'Login successful',
      user,
      token
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Biometric login verification
router.post('/biometric-login', async (req, res) => {
  try {
    const { userId, biometricData } = req.body;

    // Find user and check if biometric is enabled
    const user = await User.findOne({
      _id: userId,
      isActive: true,
      biometricEnabled: true
    });

    if (!user) {
      return res.status(401).json({ error: 'Biometric authentication not enabled' });
    }

    // In a real implementation, you would verify the biometric data
    // For this demo, we'll assume the biometric verification is successful
    if (biometricData && biometricData.verified) {
      // Update last login
      user.lastLogin = new Date();
      await user.save();

      // Generate JWT token
      const token = jwt.sign(
        { userId: user._id },
        process.env.JWT_SECRET || 'default_secret',
        { expiresIn: '24h' }
      );

      res.json({
        message: 'Biometric login successful',
        user,
        token
      });
    } else {
      res.status(401).json({ error: 'Biometric verification failed' });
    }
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get current user profile
router.get('/profile', authMiddleware, async (req, res) => {
  res.json({ user: req.user });
});

// Enable/disable biometric authentication
router.put('/biometric', authMiddleware, async (req, res) => {
  try {
    const { enabled } = req.body;
    
    req.user.biometricEnabled = enabled;
    await req.user.save();

    res.json({
      message: `Biometric authentication ${enabled ? 'enabled' : 'disabled'}`,
      user: req.user
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Refresh token
router.post('/refresh', authMiddleware, async (req, res) => {
  try {
    const token = jwt.sign(
      { userId: req.user._id },
      process.env.JWT_SECRET || 'default_secret',
      { expiresIn: '24h' }
    );

    res.json({
      message: 'Token refreshed',
      token
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;