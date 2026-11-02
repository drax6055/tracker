const express = require('express');
const { protect } = require('../middlewares/auth.middleware');
const {
  getCategories,
  createCategory,
  syncCategories,
} = require('../controllers/category.controller');

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getCategories)
  .post(createCategory);

router.post('/sync', syncCategories);

module.exports = router;
