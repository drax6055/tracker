const mongoose = require('mongoose');

const debtSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    personName: {
      type: String,
      required: true,
      trim: true,
    },
    amount: {
      type: Number,
      required: true,
    },
    remainingAmount: {
      type: Number,
      required: true,
    },
    type: {
      type: String,
      enum: ['BORROWED', 'LENT'],
      required: true,
    },
    dueDate: {
      type: String,
      default: '',
    },
    note: {
      type: String,
      trim: true,
      default: '',
    },
    status: {
      type: String,
      enum: ['ACTIVE', 'PARTIALLY_PAID', 'SETTLED'],
      default: 'ACTIVE',
    },
  },
  {
    timestamps: true,
  }
);

debtSchema.index({ userId: 1 });

module.exports = mongoose.model('Debt', debtSchema);
