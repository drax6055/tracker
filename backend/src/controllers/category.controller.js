const Category = require('../models/category.model');
const ApiResponse = require('../utils/apiResponse');
const AppError = require('../utils/appError');
const asyncHandler = require('../utils/asyncHandler');

// GET /api/v1/categories
const getCategories = asyncHandler(async (req, res) => {
  const categories = await Category.find({ userId: req.user._id }).sort({ name: 1 });
  const names = categories.map((c) => c.name);
  return ApiResponse.success(res, names, 'Categories retrieved successfully');
});

// POST /api/v1/categories
const createCategory = asyncHandler(async (req, res) => {
  const { name } = req.body;
  if (!name) {
    throw new AppError('Category name is required', 400);
  }

  const existing = await Category.findOne({ userId: req.user._id, name: name.trim() });
  if (existing) {
    return ApiResponse.success(res, existing.name, 'Category already exists');
  }

  const cat = await Category.create({ userId: req.user._id, name: name.trim() });
  return ApiResponse.created(res, cat.name, 'Category created successfully');
});

// POST /api/v1/categories/sync
const syncCategories = asyncHandler(async (req, res) => {
  const { categories } = req.body;
  if (!Array.isArray(categories)) {
    throw new AppError('Categories must be an array', 400);
  }

  for (const name of categories) {
    if (name && name.trim()) {
      await Category.findOneAndUpdate(
        { userId: req.user._id, name: name.trim() },
        { userId: req.user._id, name: name.trim() },
        { upsert: true }
      );
    }
  }

  const all = await Category.find({ userId: req.user._id }).sort({ name: 1 });
  return ApiResponse.success(res, all.map((c) => c.name), 'Categories synced successfully');
});

module.exports = {
  getCategories,
  createCategory,
  syncCategories,
};
