const mongoose = require('mongoose');

const accountSchema = new mongoose.Schema(
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
    bankName: {
      type: String,
      trim: true,
      default: '',
    },
    subtitle: {
      type: String,
      trim: true,
      default: '',
    },
    balance: {
      type: Number,
      required: true,
      default: 0.0,
    },
    type: {
      type: String,
      enum: ['BANK', 'CASH', 'CREDIT_CARD', 'LOAN'],
      default: 'BANK',
    },
    digits: {
      type: String,
      trim: true,
      default: '',
    },
    creditLimit: {
      type: Number,
      default: null,
    },
    emiAmount: {
      type: Number,
      default: null,
    },
    emiDueDay: {
      type: Number,
      default: null,
    },
    isClosed: {
      type: Boolean,
      default: false,
    },
    includeInNetWorth: {
      type: Boolean,
      default: true,
    },
    subtext: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

accountSchema.index({ userId: 1, title: 1 });

module.exports = mongoose.model('Account', accountSchema);
