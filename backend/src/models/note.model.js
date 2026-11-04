const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      default: 'Untitled Note',
    },
    content: {
      type: String,
      default: '',
    },
    color: {
      type: String,
      enum: ['yellow', 'lime', 'cyan', 'pink', 'orange', 'purple'],
      default: 'yellow',
    },
    isPinned: {
      type: Boolean,
      default: false,
    },
    createdAtClient: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

noteSchema.index({ userId: 1, isPinned: -1, updatedAt: -1 });

module.exports = mongoose.model('Note', noteSchema);

