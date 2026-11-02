const Transaction = require('../models/transaction.model');
const Account = require('../models/account.model');
const ApiResponse = require('../utils/apiResponse');
const AppError = require('../utils/appError');
const asyncHandler = require('../utils/asyncHandler');

const formatTransaction = (doc) => {
  const obj = doc.toObject ? doc.toObject() : doc;
  obj.id = obj._id.toString();
  return obj;
};

// GET /api/v1/transactions
const getTransactions = asyncHandler(async (req, res) => {
  const transactions = await Transaction.find({ userId: req.user._id }).sort({ timestamp: -1 });
  return ApiResponse.success(res, transactions.map(formatTransaction), 'Transactions retrieved successfully');
});

// POST /api/v1/transactions
const createTransaction = asyncHandler(async (req, res) => {
  const { title, type, category, account, accountId, amount, date, timestamp, note } = req.body;

  if (!title || !type || !category || !account || amount === undefined) {
    throw new AppError('Title, type, category, account, and amount are required', 400);
  }

  const numAmount = Number(amount);
  const tx = await Transaction.create({
    userId: req.user._id,
    title,
    type,
    category,
    account,
    accountId: accountId || '',
    amount: numAmount,
    date: date || '',
    timestamp: timestamp ? new Date(timestamp) : new Date(),
    note: note || '',
  });

  // Dynamically update account balance in MongoDB
  if (type === 'TRANSFER' && account.contains && account.contains('->')) {
    const parts = account.split('->').map((e) => e.trim());
    if (parts.length >= 2) {
      const fromAcc = await Account.findOne({ title: parts[0], userId: req.user._id });
      const toAcc = await Account.findOne({ title: parts[1], userId: req.user._id });
      if (fromAcc) {
        fromAcc.balance -= numAmount;
        await fromAcc.save();
      }
      if (toAcc) {
        toAcc.balance += numAmount;
        await toAcc.save();
      }
    }
  } else {
    let targetAcc;
    if (accountId && accountId.length === 24) {
      targetAcc = await Account.findOne({ _id: accountId, userId: req.user._id });
    }
    if (!targetAcc) {
      targetAcc = await Account.findOne({ title: account, userId: req.user._id });
    }
    if (targetAcc) {
      if (type === 'EXPENSE') {
        targetAcc.balance -= numAmount;
      } else if (type === 'INCOME') {
        targetAcc.balance += numAmount;
      }
      await targetAcc.save();
    }
  }

  return ApiResponse.created(res, formatTransaction(tx), 'Transaction recorded successfully');
});

// PUT /api/v1/transactions/:id
const updateTransaction = asyncHandler(async (req, res) => {
  const tx = await Transaction.findOne({ _id: req.params.id, userId: req.user._id });
  if (!tx) {
    throw new AppError('Transaction not found', 404);
  }

  const allowedFields = ['title', 'type', 'category', 'account', 'accountId', 'amount', 'date', 'timestamp', 'note'];
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) {
      tx[field] = req.body[field];
    }
  });

  await tx.save();
  return ApiResponse.success(res, formatTransaction(tx), 'Transaction updated successfully');
});

// DELETE /api/v1/transactions/:id
const deleteTransaction = asyncHandler(async (req, res) => {
  const tx = await Transaction.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
  if (!tx) {
    throw new AppError('Transaction not found', 404);
  }

  return ApiResponse.success(res, null, 'Transaction deleted successfully');
});

// POST /api/v1/transactions/sync (bulk sync from client storage)
const syncTransactions = asyncHandler(async (req, res) => {
  const { transactions } = req.body;
  if (!Array.isArray(transactions)) {
    throw new AppError('Transactions must be an array', 400);
  }

  const results = [];
  for (const item of transactions) {
    let tx;
    if (item._id || (item.id && item.id.length === 24)) {
      tx = await Transaction.findOne({ _id: item._id || item.id, userId: req.user._id });
    }
    if (!tx) {
      tx = await Transaction.create({
        userId: req.user._id,
        title: item.title,
        type: item.type,
        category: item.category,
        account: item.account,
        accountId: item.accountId || '',
        amount: Number(item.amount),
        date: item.date || '',
        timestamp: item.timestamp ? new Date(item.timestamp) : new Date(),
        note: item.note || '',
      });
    }
    results.push(formatTransaction(tx));
  }

  return ApiResponse.success(res, results, 'Transactions synced successfully');
});

module.exports = {
  getTransactions,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  syncTransactions,
};
