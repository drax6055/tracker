const Transaction = require('../models/transaction.model');
const Account = require('../models/account.model');
const ApiResponse = require('../utils/apiResponse');
const AppError = require('../utils/appError');
const asyncHandler = require('../utils/asyncHandler');

const DEMO_TX_TITLES = [
  'Salary Credit',
  'Grocery & Supermarket',
  'Coffee & Bistro',
  'Cash Withdrawal',
  'Electricity Bill',
  'Freelance UI Design',
  'Netflix & Spotify',
  'Health Insurance EMI',
];

const isDemoUser = (email) => {
  const norm = (email || '').toLowerCase().trim();
  return norm === 'bruce@wayne.corp' || norm === 'bruce@wayn.corp';
};

const formatTransaction = (doc) => {
  const obj = doc.toObject ? doc.toObject() : doc;
  obj.id = obj._id.toString();
  return obj;
};

// GET /api/v1/transactions
const getTransactions = asyncHandler(async (req, res) => {
  // Pagination support
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const limit = Math.min(200, Math.max(1, parseInt(req.query.limit) || 50));
  const skip = (page - 1) * limit;

  const transactions = await Transaction.find({ userId: req.user._id })
    .sort({ timestamp: -1 })
    .skip(skip)
    .limit(limit);
  return ApiResponse.success(res, transactions.map(formatTransaction), 'Transactions retrieved successfully');
});

// POST /api/v1/transactions
const createTransaction = asyncHandler(async (req, res) => {
  const { title, type, category, account, accountId, amount, date, timestamp, note } = req.body;

  if (!title || !type || !category || !account || amount === undefined) {
    throw new AppError('Title, type, category, account, and amount are required', 400);
  }

  if (!isDemoUser(req.user.email) && DEMO_TX_TITLES.includes(title)) {
    throw new AppError('Cannot create demo transaction on standard user profile', 400);
  }

  const numAmount = Number(amount);
  if (!Number.isFinite(numAmount) || numAmount <= 0) {
    throw new AppError('Amount must be a positive number', 400);
  }

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
  if (type === 'TRANSFER' && account.includes('->')) {
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

  return ApiResponse.created(res, formatTransaction(tx), 'Transaction created successfully');
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

// POST /api/v1/transactions/sync
const syncTransactions = asyncHandler(async (req, res) => {
  const { transactions } = req.body;
  if (!Array.isArray(transactions)) {
    throw new AppError('Transactions list must be an array', 400);
  }

  if (transactions.length > 500) {
    throw new AppError('Too many transactions in sync payload (max 500)', 400);
  }

  const userIsDemo = isDemoUser(req.user.email);
  const filteredTxs = userIsDemo
    ? transactions
    : transactions.filter((t) => !DEMO_TX_TITLES.includes(t.title));

  const results = [];
  for (const item of filteredTxs) {
    let tx;
    if (item._id || (item.id && item.id.length === 24)) {
      tx = await Transaction.findOne({ _id: item._id || item.id, userId: req.user._id });
    }

    if (tx) {
      // UPDATE existing record
      tx.title = item.title || tx.title;
      tx.type = item.type || tx.type;
      tx.category = item.category || tx.category;
      tx.account = item.account || tx.account;
      tx.accountId = item.accountId !== undefined ? item.accountId : tx.accountId;
      tx.amount = item.amount !== undefined ? Number(item.amount) : tx.amount;
      tx.date = item.date !== undefined ? item.date : tx.date;
      tx.timestamp = item.timestamp ? new Date(item.timestamp) : tx.timestamp;
      tx.note = item.note !== undefined ? item.note : tx.note;
      await tx.save();
    } else {
      tx = await Transaction.create({
        userId: req.user._id,
        title: item.title,
        type: item.type || 'EXPENSE',
        category: item.category || 'General',
        account: item.account || 'Default Account',
        accountId: item.accountId || '',
        amount: item.amount !== undefined ? Number(item.amount) : 0,
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
