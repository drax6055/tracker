const mongoose = require('mongoose');

const ipoSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    companyName: {
      type: String,
      required: true,
      trim: true,
    },
    symbol: {
      type: String,
      trim: true,
      uppercase: true,
      default: '',
    },
    ipoType: {
      type: String,
      enum: ['MAINBOARD', 'SME'],
      default: 'MAINBOARD',
    },
    category: {
      type: String,
      enum: ['RETAIL', 'sHNI', 'bHNI', 'EMPLOYEE', 'SHAREHOLDER'],
      default: 'RETAIL',
    },
    applicantName: {
      type: String,
      trim: true,
      default: 'Self',
    },
    pan: {
      type: String,
      trim: true,
      uppercase: true,
      default: '',
    },
    dematBroker: {
      type: String,
      trim: true,
      default: 'Zerodha',
    },
    bankName: {
      type: String,
      trim: true,
      default: '',
    },
    upiId: {
      type: String,
      trim: true,
      default: '',
    },
    appliedLots: {
      type: Number,
      required: true,
      min: 1,
      default: 1,
    },
    sharesPerLot: {
      type: Number,
      required: true,
      min: 1,
      default: 1,
    },
    bidPrice: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },
    cutOff: {
      type: Boolean,
      default: true,
    },
    totalAmountBlocked: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },
    status: {
      type: String,
      enum: ['BLOCKED', 'ALLOTTED', 'NOT_ALLOTTED', 'EXITED'],
      default: 'BLOCKED',
      index: true,
    },
    allottedLots: {
      type: Number,
      min: 0,
      default: 0,
    },
    allottedShares: {
      type: Number,
      min: 0,
      default: 0,
    },
    allottedAmount: {
      type: Number,
      min: 0,
      default: 0,
    },
    refundAmount: {
      type: Number,
      min: 0,
      default: 0,
    },
    allotmentDate: {
      type: String,
      default: '',
    },
    listingDate: {
      type: String,
      default: '',
    },
    registrar: {
      type: String,
      trim: true,
      default: '',
    },
    registrarUrl: {
      type: String,
      trim: true,
      default: '',
    },
    gmp: {
      type: Number,
      default: 0,
    },
    expectedListingGain: {
      type: Number,
      default: 0,
    },
    // Exit & Tax fields
    exitDate: {
      type: String,
      default: '',
    },
    exitPrice: {
      type: Number,
      min: 0,
      default: 0,
    },
    exitShares: {
      type: Number,
      min: 0,
      default: 0,
    },
    grossProceeds: {
      type: Number,
      min: 0,
      default: 0,
    },
    dpCharges: {
      type: Number,
      default: 15.93,
    },
    sttCharges: {
      type: Number,
      default: 0,
    },
    netGain: {
      type: Number,
      default: 0,
    },
    gainType: {
      type: String,
      enum: ['STCG', 'LTCG', 'NONE'],
      default: 'STCG',
    },
    financialYear: {
      type: String,
      trim: true,
      default: '',
      index: true,
    },
    notes: {
      type: String,
      default: '',
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

ipoSchema.index({ userId: 1, status: 1, createdAt: -1 });
ipoSchema.index({ userId: 1, financialYear: 1, status: 1 });

module.exports = mongoose.model('Ipo', ipoSchema);

