const Debt = require('../models/debt.model');
const ApiResponse = require('../utils/apiResponse');
const AppError = require('../utils/appError');
const asyncHandler = require('../utils/asyncHandler');

const DEMO_DEBT_PERSONS = ['Peter Parker', 'Tony Stark', 'Clark Kent'];

const isDemoUser = (email) => {
  const norm = (email || '').toLowerCase().trim();
  return norm === 'bruce@wayne.corp' || norm === 'bruce@wayn.corp';
};

const formatDebt = (doc) => {
  const obj = doc.toObject ? doc.toObject() : doc;
  obj.id = obj._id.toString();
  return obj;
};

// GET /api/v1/debts
const getDebts = asyncHandler(async (req, res) => {
  const query = { userId: req.user._id };
  if (!isDemoUser(req.user.email)) {
    query.personName = { $nin: DEMO_DEBT_PERSONS };
  }
  const debts = await Debt.find(query).sort({ createdAt: -1 });
  return ApiResponse.success(res, debts.map(formatDebt), 'Debts retrieved successfully');
});

// POST /api/v1/debts
const createDebt = asyncHandler(async (req, res) => {
  const { personName, amount, remainingAmount, type, dueDate, note, status } = req.body;

  if (!personName || amount === undefined || !type) {
    throw new AppError('Person name, amount, and type are required', 400);
  }

  if (!isDemoUser(req.user.email) && DEMO_DEBT_PERSONS.includes(personName)) {
    throw new AppError('Cannot create demo debt record on standard user profile', 400);
  }

  const numAmount = Number(amount);
  const debt = await Debt.create({
    userId: req.user._id,
    personName,
    amount: numAmount,
    remainingAmount: remainingAmount !== undefined ? Number(remainingAmount) : numAmount,
    type,
    dueDate: dueDate || '',
    note: note || '',
    status: status || 'ACTIVE',
  });

  return ApiResponse.created(res, formatDebt(debt), 'Debt created successfully');
});

// PUT /api/v1/debts/:id
const updateDebt = asyncHandler(async (req, res) => {
  const debt = await Debt.findOne({ _id: req.params.id, userId: req.user._id });
  if (!debt) {
    throw new AppError('Debt not found', 404);
  }

  const allowedFields = ['personName', 'amount', 'remainingAmount', 'type', 'dueDate', 'note', 'status'];
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) {
      debt[field] = req.body[field];
    }
  });

  await debt.save();
  return ApiResponse.success(res, formatDebt(debt), 'Debt updated successfully');
});

// DELETE /api/v1/debts/:id
const deleteDebt = asyncHandler(async (req, res) => {
  const debt = await Debt.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
  if (!debt) {
    throw new AppError('Debt not found', 404);
  }

  return ApiResponse.success(res, null, 'Debt deleted successfully');
});

// POST /api/v1/debts/sync
const syncDebts = asyncHandler(async (req, res) => {
  const { debts } = req.body;
  if (!Array.isArray(debts)) {
    throw new AppError('Debts list must be an array', 400);
  }

  if (debts.length > 500) {
    throw new AppError('Too many debts in sync payload (max 500)', 400);
  }

  const userIsDemo = isDemoUser(req.user.email);
  const filteredDebts = userIsDemo
    ? debts
    : debts.filter((d) => {
        const name = d.personName || d.person;
        return !DEMO_DEBT_PERSONS.includes(name);
      });

  const results = [];
  for (const item of filteredDebts) {
    let debt;
    if (item._id || (item.id && item.id.length === 24)) {
      debt = await Debt.findOne({ _id: item._id || item.id, userId: req.user._id });
    }

    const personName = item.personName || item.person || 'Unknown';
    const amount = Number(item.amount || item.originalAmount || 0);
    const remaining = item.remainingAmount !== undefined ? Number(item.remainingAmount) : amount;

    if (debt) {
      // UPDATE existing record
      debt.personName = personName;
      debt.amount = amount;
      debt.remainingAmount = remaining;
      debt.type = item.type || debt.type;
      debt.dueDate = item.dueDate !== undefined ? item.dueDate : debt.dueDate;
      debt.note = item.note !== undefined ? (item.note || item.notes || '') : debt.note;
      debt.status = item.status || debt.status;
      await debt.save();
    } else {
      debt = await Debt.create({
        userId: req.user._id,
        personName,
        amount,
        remainingAmount: remaining,
        type: item.type || 'LENT',
        dueDate: item.dueDate || '',
        note: item.note || item.notes || '',
        status: item.status || 'ACTIVE',
      });
    }
    results.push(formatDebt(debt));
  }

  return ApiResponse.success(res, results, 'Debts synced successfully');
});

module.exports = {
  getDebts,
  createDebt,
  updateDebt,
  deleteDebt,
  syncDebts,
};
