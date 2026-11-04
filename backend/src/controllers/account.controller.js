const Account = require('../models/account.model');
const ApiResponse = require('../utils/apiResponse');
const AppError = require('../utils/appError');
const asyncHandler = require('../utils/asyncHandler');

const DEMO_ACCOUNT_TITLES = [
  'HDFC Salaried Account',
  'Physical Cash Vault',
  'Infinia Metal Card',
  'Vehicle Loan #49281',
];

const isDemoUser = (email) => {
  const norm = (email || '').toLowerCase().trim();
  return norm === 'bruce@wayne.corp' || norm === 'bruce@wayn.corp';
};

// Map mongo document to client format with clean `id`
const formatAccount = (doc) => {
  const obj = doc.toObject ? doc.toObject() : doc;
  obj.id = obj._id.toString();
  return obj;
};

// GET /api/v1/accounts
const getAccounts = asyncHandler(async (req, res) => {
  const query = { userId: req.user._id };
  if (!isDemoUser(req.user.email)) {
    query.title = { $nin: DEMO_ACCOUNT_TITLES };
  }
  const accounts = await Account.find(query).sort({ createdAt: 1 });
  return ApiResponse.success(res, accounts.map(formatAccount), 'Accounts retrieved successfully');
});

// POST /api/v1/accounts
const createAccount = asyncHandler(async (req, res) => {
  const {
    title,
    bankName,
    subtitle,
    balance,
    type,
    digits,
    creditLimit,
    emiAmount,
    emiDueDay,
    isClosed,
    includeInNetWorth,
    subtext,
  } = req.body;

  if (!title) {
    throw new AppError('Account title is required', 400);
  }

  // Reject demo accounts for non-demo users
  if (!isDemoUser(req.user.email) && DEMO_ACCOUNT_TITLES.includes(title)) {
    throw new AppError('Cannot create demo account on standard user profile', 400);
  }

  const account = await Account.create({
    userId: req.user._id,
    title,
    bankName: bankName || '',
    subtitle: subtitle || '',
    balance: balance !== undefined ? Number(balance) : 0,
    type: type || 'BANK',
    digits: digits || '',
    creditLimit: creditLimit ? Number(creditLimit) : null,
    emiAmount: emiAmount ? Number(emiAmount) : null,
    emiDueDay: emiDueDay ? Number(emiDueDay) : null,
    isClosed: Boolean(isClosed),
    includeInNetWorth: includeInNetWorth !== undefined ? Boolean(includeInNetWorth) : true,
    subtext: subtext || null,
  });

  return ApiResponse.created(res, formatAccount(account), 'Account created successfully');
});

// PUT /api/v1/accounts/:id
const updateAccount = asyncHandler(async (req, res) => {
  const account = await Account.findOne({ _id: req.params.id, userId: req.user._id });

  if (!account) {
    throw new AppError('Account not found', 404);
  }

  const allowedFields = [
    'title',
    'bankName',
    'subtitle',
    'balance',
    'type',
    'digits',
    'creditLimit',
    'emiAmount',
    'emiDueDay',
    'isClosed',
    'includeInNetWorth',
    'subtext',
  ];

  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) {
      account[field] = req.body[field];
    }
  });

  await account.save();

  return ApiResponse.success(res, formatAccount(account), 'Account updated successfully');
});

// DELETE /api/v1/accounts/:id
const deleteAccount = asyncHandler(async (req, res) => {
  const account = await Account.findOneAndDelete({ _id: req.params.id, userId: req.user._id });

  if (!account) {
    throw new AppError('Account not found', 404);
  }

  return ApiResponse.success(res, null, 'Account deleted successfully');
});

// POST /api/v1/accounts/sync (bulk sync from local client storage)
const syncAccounts = asyncHandler(async (req, res) => {
  const { accounts } = req.body;
  if (!Array.isArray(accounts)) {
    throw new AppError('Accounts list must be an array', 400);
  }

  if (accounts.length > 500) {
    throw new AppError('Too many accounts in sync payload (max 500)', 400);
  }

  const userIsDemo = isDemoUser(req.user.email);
  const filteredAccounts = userIsDemo
    ? accounts
    : accounts.filter((item) => !DEMO_ACCOUNT_TITLES.includes(item.title));

  const results = [];
  for (const item of filteredAccounts) {
    let acc;
    if (item._id || (item.id && item.id.length === 24)) {
      acc = await Account.findOne({ _id: item._id || item.id, userId: req.user._id });
    }
    if (!acc) {
      acc = await Account.findOne({ title: item.title, userId: req.user._id });
    }

    if (acc) {
      acc.balance = item.balance !== undefined ? Number(item.balance) : acc.balance;
      acc.subtitle = item.subtitle || acc.subtitle;
      acc.bankName = item.bankName || acc.bankName;
      acc.digits = item.digits || acc.digits;
      acc.creditLimit = item.creditLimit !== undefined ? item.creditLimit : acc.creditLimit;
      acc.emiAmount = item.emiAmount !== undefined ? item.emiAmount : acc.emiAmount;
      acc.emiDueDay = item.emiDueDay !== undefined ? item.emiDueDay : acc.emiDueDay;
      acc.isClosed = item.isClosed !== undefined ? item.isClosed : acc.isClosed;
      acc.includeInNetWorth = item.includeInNetWorth !== undefined ? item.includeInNetWorth : acc.includeInNetWorth;
      acc.subtext = item.subtext !== undefined ? item.subtext : acc.subtext;
      await acc.save();
    } else {
      acc = await Account.create({
        userId: req.user._id,
        title: item.title,
        bankName: item.bankName || '',
        subtitle: item.subtitle || '',
        balance: item.balance !== undefined ? Number(item.balance) : 0,
        type: item.type || 'BANK',
        digits: item.digits || '',
        creditLimit: item.creditLimit ? Number(item.creditLimit) : null,
        emiAmount: item.emiAmount ? Number(item.emiAmount) : null,
        emiDueDay: item.emiDueDay ? Number(item.emiDueDay) : null,
        isClosed: Boolean(item.isClosed),
        includeInNetWorth: item.includeInNetWorth !== undefined ? Boolean(item.includeInNetWorth) : true,
        subtext: item.subtext || null,
      });
    }
    results.push(formatAccount(acc));
  }

  return ApiResponse.success(res, results, 'Accounts synced successfully');
});

module.exports = {
  getAccounts,
  createAccount,
  updateAccount,
  deleteAccount,
  syncAccounts,
};
