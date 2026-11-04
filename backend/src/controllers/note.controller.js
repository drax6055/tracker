const Note = require('../models/note.model');
const ApiResponse = require('../utils/apiResponse');
const AppError = require('../utils/appError');
const asyncHandler = require('../utils/asyncHandler');

const formatNote = (doc) => {
  const obj = doc.toObject ? doc.toObject() : doc;
  obj.id = obj._id.toString();
  return obj;
};

// GET /api/v1/notes
const getNotes = asyncHandler(async (req, res) => {
  const notes = await Note.find({ userId: req.user._id }).sort({ isPinned: -1, updatedAt: -1 });
  return ApiResponse.success(res, notes.map(formatNote), 'Notes retrieved successfully');
});

// POST /api/v1/notes
const createNote = asyncHandler(async (req, res) => {
  const { title, content, color, isPinned, createdAtClient } = req.body;

  const note = await Note.create({
    userId: req.user._id,
    title: (title || '').trim() || 'Untitled Note',
    content: content || '',
    color: ['yellow', 'lime', 'cyan', 'pink', 'orange', 'purple'].includes(color) ? color : 'yellow',
    isPinned: Boolean(isPinned),
    createdAtClient: createdAtClient || new Date().toISOString(),
  });

  return ApiResponse.created(res, formatNote(note), 'Note created successfully');
});

// PUT /api/v1/notes/:id
const updateNote = asyncHandler(async (req, res) => {
  const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
  if (!note) {
    throw new AppError('Note not found', 404);
  }

  const allowedFields = ['title', 'content', 'color', 'isPinned'];
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) {
      note[field] = req.body[field];
    }
  });

  await note.save();
  return ApiResponse.success(res, formatNote(note), 'Note updated successfully');
});

// DELETE /api/v1/notes/:id
const deleteNote = asyncHandler(async (req, res) => {
  const note = await Note.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
  if (!note) {
    throw new AppError('Note not found', 404);
  }

  return ApiResponse.success(res, null, 'Note deleted successfully');
});

// POST /api/v1/notes/sync
const syncNotes = asyncHandler(async (req, res) => {
  const { notes } = req.body;
  if (!Array.isArray(notes)) {
    throw new AppError('Notes list must be an array', 400);
  }

  if (notes.length > 500) {
    throw new AppError('Too many notes in sync payload (max 500)', 400);
  }

  const results = [];
  for (const item of notes) {
    let note;
    if (item._id || (item.id && item.id.length === 24)) {
      note = await Note.findOne({ _id: item._id || item.id, userId: req.user._id });
    }

    if (note) {
      note.title = item.title !== undefined ? item.title : note.title;
      note.content = item.content !== undefined ? item.content : note.content;
      note.color = item.color || note.color;
      note.isPinned = item.isPinned !== undefined ? Boolean(item.isPinned) : note.isPinned;
      await note.save();
    } else {
      note = await Note.create({
        userId: req.user._id,
        title: (item.title || '').trim() || 'Untitled Note',
        content: item.content || '',
        color: ['yellow', 'lime', 'cyan', 'pink', 'orange', 'purple'].includes(item.color)
          ? item.color
          : 'yellow',
        isPinned: Boolean(item.isPinned),
        createdAtClient: item.createdAt || item.createdAtClient || new Date().toISOString(),
      });
    }
    results.push(formatNote(note));
  }

  return ApiResponse.success(res, results, 'Notes synced successfully');
});

module.exports = {
  getNotes,
  createNote,
  updateNote,
  deleteNote,
  syncNotes,
};
