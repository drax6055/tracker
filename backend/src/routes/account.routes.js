const express = require('express');
const { protect } = require('../middlewares/auth.middleware');
const {
  getAccounts,
  createAccount,
  updateAccount,
  deleteAccount,
  syncAccounts,
} = require('../controllers/account.controller');

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getAccounts)
  .post(createAccount);

router.post('/sync', syncAccounts);

router.route('/:id')
  .put(updateAccount)
  .delete(deleteAccount);

module.exports = router;
