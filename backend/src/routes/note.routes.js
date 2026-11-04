const express = require('express');
const {
  getNotes,
  createNote,
  updateNote,
  deleteNote,
  syncNotes,
} = require('../controllers/note.controller');
const { protect } = require('../middlewares/auth.middleware');

const router = express.Router();

router.use(protect);

router
  .route('/')
  .get(getNotes)
  .post(createNote);

router.post('/sync', syncNotes);

router
  .route('/:id')
  .put(updateNote)
  .delete(deleteNote);

module.exports = router;
