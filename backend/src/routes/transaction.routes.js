const express = require('express');
const { protect } = require('../middlewares/auth.middleware');
const {
  getTransactions,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  syncTransactions,
} = require('../controllers/transaction.controller');

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getTransactions)
  .post(createTransaction);

router.post('/sync', syncTransactions);

router.route('/:id')
  .put(updateTransaction)
  .delete(deleteTransaction);

module.exports = router;
