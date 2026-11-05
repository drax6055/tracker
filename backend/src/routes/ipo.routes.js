const express = require('express');
const {
  getIpos,
  createIpo,
  updateIpo,
  deleteIpo,
  syncIpos,
  getCaReport,
} = require('../controllers/ipo.controller');
const { protect } = require('../middlewares/auth.middleware');

const router = express.Router();

router.use(protect);

router
  .route('/')
  .get(getIpos)
  .post(createIpo);

router.post('/sync', syncIpos);
router.get('/ca-report', getCaReport);

router
  .route('/:id')
  .put(updateIpo)
  .delete(deleteIpo);

module.exports = router;
