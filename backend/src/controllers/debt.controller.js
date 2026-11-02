const Debt = require('../models/debt.model');
const ApiResponse = require('../utils/apiResponse');
const AppError = require('../utils/appError');
const asyncHandler = require('../utils/asyncHandler');

const formatDebt = (doc) => {
  const obj = doc.toObject ? doc.toObject() : doc;
  obj.id = obj._id.toString();
  return obj;
};

// GET /api/v1/debts
const getDebts = asyncHandler(async (req, res) => {
  const debts = await Debt.find({ userId: req.user._id }).sort({ createdAt: -1 });
  return ApiResponse.success(res, debts.map(formatDebt), 'Debts retrieved successfully');
});

// POST /api/v1/debts
const createDebt = asyncHandler(async (req, res) => {
  const { personName, amount, remainingAmount, type, dueDate, note, status } = req.body;

  if (!personName || amount === undefined || !type) {
    throw new AppError('Person name, amount, and type are required', 400);
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
    throw new AppError('Debts must be an array', 400);
  }

  const results = [];
  for (const item of debts) {
    let d;
    if (item._id || (item.id && item.id.length === 24)) {
      d = await Debt.findOne({ _id: item._id || item.id, userId: req.user._id });
    }
    if (!d) {
      d = await Debt.create({
        userId: req.user._id,
        personName: item.personName,
        amount: Number(item.amount),
        remainingAmount: item.remainingAmount !== undefined ? Number(item.remainingAmount) : Number(item.amount),
        type: item.type,
        dueDate: item.dueDate || '',
        note: item.note || '',
        status: item.status || 'ACTIVE',
      });
    }
    results.push(formatDebt(d));
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
