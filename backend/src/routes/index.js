const express = require('express');
const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');

const router = express.Router();

router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'LEDGER API is running healthy',
    timestamp: new Date().toISOString(),
  });
});

router.use('/auth', authRoutes);
router.use('/user', userRoutes);

module.exports = router;
