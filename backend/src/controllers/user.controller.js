const User = require('../models/user.model');
const Account = require('../models/account.model');
const Transaction = require('../models/transaction.model');
const Category = require('../models/category.model');
const Debt = require('../models/debt.model');
const Note = require('../models/note.model');
const TokenService = require('../services/token.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const AppError = require('../utils/appError');

class UserController {
  static getMe = asyncHandler(async (req, res) => {
    // Return user from request (already populated by protect middleware)
    return ApiResponse.success(res, { user: req.user }, 'User profile fetched successfully');
  });

  static updateMe = asyncHandler(async (req, res) => {
    const allowedUpdates = ['name', 'currency', 'currencySymbol'];
    const updates = {};

    allowedUpdates.forEach((field) => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true,
    });

    return ApiResponse.success(res, { user }, 'User profile updated successfully');
  });

  static deleteMe = asyncHandler(async (req, res) => {
    const userId = req.user._id;

    // Cascade-delete all user data before removing account
    await Promise.all([
      Account.deleteMany({ userId }),
      Transaction.deleteMany({ userId }),
      Category.deleteMany({ userId }),
      Debt.deleteMany({ userId }),
      Note.deleteMany({ userId }),
      TokenService.revokeAllUserRefreshTokens(userId),
    ]);

    // Delete user
    await User.findByIdAndDelete(userId);

    return ApiResponse.success(res, null, 'Account deleted successfully');
  });
}

module.exports = UserController;
