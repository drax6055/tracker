const express = require('express');
const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');
const accountRoutes = require('./account.routes');
const transactionRoutes = require('./transaction.routes');
const categoryRoutes = require('./category.routes');
const debtRoutes = require('./debt.routes');
const noteRoutes = require('./note.routes');
const ipoRoutes = require('./ipo.routes');

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
router.use('/accounts', accountRoutes);
router.use('/transactions', transactionRoutes);
router.use('/categories', categoryRoutes);
router.use('/debts', debtRoutes);
router.use('/notes', noteRoutes);
router.use('/ipos', ipoRoutes);

module.exports = router;
