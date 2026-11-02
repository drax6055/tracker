const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
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
    },
    type: {
      type: String,
      enum: ['EXPENSE', 'INCOME', 'TRANSFER'],
      required: true,
    },
    category: {
      type: String,
      required: true,
      trim: true,
    },
    account: {
      type: String,
      required: true,
      trim: true,
    },
    accountId: {
      type: String,
      default: '',
    },
    amount: {
      type: Number,
      required: true,
    },
    date: {
      type: String,
      default: '',
    },
    timestamp: {
      type: Date,
      default: Date.now,
      index: true,
    },
    note: {
      type: String,
      trim: true,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

transactionSchema.index({ userId: 1, timestamp: -1 });

module.exports = mongoose.model('Transaction', transactionSchema);
