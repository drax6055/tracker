const express = require('express');
const { protect } = require('../middlewares/auth.middleware');
const {
  getDebts,
  createDebt,
  updateDebt,
  deleteDebt,
  syncDebts,
} = require('../controllers/debt.controller');

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getDebts)
  .post(createDebt);

router.post('/sync', syncDebts);

router.route('/:id')
  .put(updateDebt)
  .delete(deleteDebt);

module.exports = router;
