const Ipo = require('../models/ipo.model');
const ApiResponse = require('../utils/apiResponse');
const AppError = require('../utils/appError');
const asyncHandler = require('../utils/asyncHandler');

const formatIpo = (doc) => {
  const obj = doc.toObject ? doc.toObject() : doc;
  obj.id = obj._id ? obj._id.toString() : obj.id;
  return obj;
};

// Calculate Indian Financial Year (e.g. 2026-2027)
const computeFinancialYear = (dateStr) => {
  const date = dateStr ? new Date(dateStr) : new Date();
  if (isNaN(date.getTime())) return '2026-2027';
  const year = date.getFullYear();
  const month = date.getMonth(); // 0-indexed: Jan=0, Mar=2, Apr=3
  if (month >= 3) {
    return `${year}-${year + 1}`;
  } else {
    return `${year - 1}-${year}`;
  }
};

// Auto-compute financial fields based on status
const calculateIpoFields = (data) => {
  const appliedLots = Number(data.appliedLots) || 1;
  const sharesPerLot = Number(data.sharesPerLot) || 1;
  const bidPrice = Number(data.bidPrice) || 0;
  const totalAmountBlocked = appliedLots * sharesPerLot * bidPrice;

  let allottedLots = Number(data.allottedLots) || 0;
  let allottedShares = Number(data.allottedShares) || 0;
  let allottedAmount = Number(data.allottedAmount) || 0;
  let refundAmount = Number(data.refundAmount) || 0;

  if (data.status === 'ALLOTTED') {
    if (allottedLots <= 0) allottedLots = appliedLots;
    allottedShares = allottedLots * sharesPerLot;
    allottedAmount = allottedShares * bidPrice;
    refundAmount = Math.max(0, totalAmountBlocked - allottedAmount);
  } else if (data.status === 'NOT_ALLOTTED') {
    allottedLots = 0;
    allottedShares = 0;
    allottedAmount = 0;
    refundAmount = totalAmountBlocked;
  } else if (data.status === 'BLOCKED') {
    allottedLots = 0;
    allottedShares = 0;
    allottedAmount = 0;
    refundAmount = 0;
  }

  // Exit calculation
  let exitShares = Number(data.exitShares) || allottedShares;
  let exitPrice = Number(data.exitPrice) || 0;
  let dpCharges = Number(data.dpCharges) !== undefined ? Number(data.dpCharges) : 15.93;
  let grossProceeds = exitPrice * exitShares;
  let sttCharges = grossProceeds > 0 ? Math.round(grossProceeds * 0.001) : 0; // 0.1% STT on equity sale
  let buyCost = exitShares * bidPrice;
  let netGain = grossProceeds > 0 ? (grossProceeds - buyCost - dpCharges - sttCharges) : 0;

  let gainType = 'STCG';
  if (data.allotmentDate && data.exitDate) {
    const d1 = new Date(data.allotmentDate);
    const d2 = new Date(data.exitDate);
    const diffDays = (d2.getTime() - d1.getTime()) / (1000 * 3600 * 24);
    if (diffDays > 365) {
      gainType = 'LTCG';
    }
  }

  const effectiveDate = data.exitDate || data.listingDate || data.allotmentDate || new Date().toISOString();
  const financialYear = data.financialYear || computeFinancialYear(effectiveDate);

  return {
    ...data,
    appliedLots,
    sharesPerLot,
    bidPrice,
    totalAmountBlocked,
    allottedLots,
    allottedShares,
    allottedAmount,
    refundAmount,
    exitShares,
    exitPrice,
    grossProceeds,
    dpCharges,
    sttCharges,
    netGain: Math.round(netGain * 100) / 100,
    gainType,
    financialYear,
  };
};

// GET /api/v1/ipos
const getIpos = asyncHandler(async (req, res) => {
  const { status, fy, applicant } = req.query;
  const filter = { userId: req.user._id };

  if (status && status !== 'ALL') filter.status = status;
  if (fy && fy !== 'ALL') filter.financialYear = fy;
  if (applicant && applicant !== 'ALL') filter.applicantName = applicant;

  const ipos = await Ipo.find(filter).sort({ createdAt: -1 });
  return ApiResponse.success(res, ipos.map(formatIpo), 'IPOs retrieved successfully');
});

// POST /api/v1/ipos
const createIpo = asyncHandler(async (req, res) => {
  const payload = calculateIpoFields({
    ...req.body,
    userId: req.user._id,
  });

  const ipo = await Ipo.create(payload);
  return ApiResponse.created(res, formatIpo(ipo), 'IPO application tracked successfully');
});

// PUT /api/v1/ipos/:id
const updateIpo = asyncHandler(async (req, res) => {
  const ipo = await Ipo.findOne({ _id: req.params.id, userId: req.user._id });
  if (!ipo) {
    throw new AppError('IPO application not found', 404);
  }

  const updatedData = calculateIpoFields({
    ...ipo.toObject(),
    ...req.body,
  });

  delete updatedData._id;
  delete updatedData.id;
  delete updatedData.userId;

  Object.assign(ipo, updatedData);
  await ipo.save();

  return ApiResponse.success(res, formatIpo(ipo), 'IPO application updated successfully');
});

// DELETE /api/v1/ipos/:id
const deleteIpo = asyncHandler(async (req, res) => {
  const ipo = await Ipo.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
  if (!ipo) {
    throw new AppError('IPO application not found', 404);
  }

  return ApiResponse.success(res, null, 'IPO application deleted successfully');
});

// POST /api/v1/ipos/sync
const syncIpos = asyncHandler(async (req, res) => {
  const { ipos } = req.body;
  if (!Array.isArray(ipos)) {
    throw new AppError('IPOs list must be an array', 400);
  }

  const results = [];
  for (const item of ipos) {
    let doc;
    if (item._id || (item.id && item.id.length === 24)) {
      doc = await Ipo.findOne({ _id: item._id || item.id, userId: req.user._id });
    }

    const calculated = calculateIpoFields(item);

    if (doc) {
      delete calculated._id;
      delete calculated.id;
      delete calculated.userId;
      Object.assign(doc, calculated);
      await doc.save();
    } else {
      doc = await Ipo.create({
        ...calculated,
        userId: req.user._id,
      });
    }
    results.push(formatIpo(doc));
  }

  return ApiResponse.success(res, results, 'IPOs synced successfully');
});

// GET /api/v1/ipos/ca-report
const getCaReport = asyncHandler(async (req, res) => {
  const { fy, applicant, pan } = req.query;
  const targetFy = fy || computeFinancialYear(new Date().toISOString());

  const filter = {
    userId: req.user._id,
    financialYear: targetFy,
  };

  if (applicant && applicant !== 'ALL') filter.applicantName = applicant;
  if (pan && pan !== 'ALL') filter.pan = pan.toUpperCase();

  const allRecords = await Ipo.find(filter).sort({ exitDate: -1, allotmentDate: -1 });
  const exitedRecords = allRecords.filter((r) => r.status === 'EXITED');

  let totalAppliedAmount = 0;
  let totalAllottedAmount = 0;
  let totalRefundAmount = 0;

  let grossSaleValue = 0;
  let grossBuyCost = 0;
  let totalDpCharges = 0;
  let totalSttCharges = 0;

  let netStcg = 0;
  let netLtcg = 0;

  for (const r of allRecords) {
    totalAppliedAmount += r.totalAmountBlocked || 0;
    totalAllottedAmount += r.allottedAmount || 0;
    totalRefundAmount += r.refundAmount || 0;
  }

  for (const r of exitedRecords) {
    const buyCost = (r.exitShares || 0) * (r.bidPrice || 0);
    const saleVal = r.grossProceeds || 0;
    grossBuyCost += buyCost;
    grossSaleValue += saleVal;
    totalDpCharges += r.dpCharges || 0;
    totalSttCharges += r.sttCharges || 0;

    if (r.gainType === 'LTCG') {
      netLtcg += r.netGain || 0;
    } else {
      netStcg += r.netGain || 0;
    }
  }

  // Tax calculations under Indian Income Tax Act
  // STCG @ 20% flat (Section 111A)
  const estimatedStcgTax = netStcg > 0 ? Math.round(netStcg * 0.20) : 0;
  // LTCG @ 12.5% on gains exceeding ₹1,25,000 (Section 112A)
  const taxableLtcg = Math.max(0, netLtcg - 125000);
  const estimatedLtcgTax = taxableLtcg > 0 ? Math.round(taxableLtcg * 0.125) : 0;
  const totalEstimatedTax = estimatedStcgTax + estimatedLtcgTax;

  // WhatsApp / Email formatted summary ready for CA
  const reportText = `*ANNUAL IPO TAX REPORT // FY ${targetFy}*
----------------------------------------
*Investor:* ${applicant || 'All Consolidated'} ${pan ? `(PAN: ${pan})` : ''}
*Assessment Year:* ${parseInt(targetFy.split('-')[0]) + 1}-${parseInt(targetFy.split('-')[1]) + 1}

*CAPITAL GAINS SUMMARY:*
• Total Applications: ${allRecords.length}
• Total Exits Realized: ${exitedRecords.length}
• Gross Sales Value: ₹${grossSaleValue.toLocaleString('en-IN')}
• Total Purchase Cost: ₹${grossBuyCost.toLocaleString('en-IN')}
• Total Deductible Charges: ₹${(totalDpCharges + totalSttCharges).toLocaleString('en-IN')}
• *Net STCG (u/s 111A @ 20%):* ₹${netStcg.toLocaleString('en-IN')}
• *Net LTCG (u/s 112A @ 12.5%):* ₹${netLtcg.toLocaleString('en-IN')}
• *Estimated Tax Payable:* ₹${totalEstimatedTax.toLocaleString('en-IN')}

*BANK ASBA RECONCILIATION:*
• Capital Applied (Blocked): ₹${totalAppliedAmount.toLocaleString('en-IN')}
• Capital Allotted (Debited): ₹${totalAllottedAmount.toLocaleString('en-IN')}
• Capital Refunded (Unblocked): ₹${totalRefundAmount.toLocaleString('en-IN')}
----------------------------------------
Generated via Ledger Track App`;

  return ApiResponse.success(
    res,
    {
      financialYear: targetFy,
      summary: {
        totalApplications: allRecords.length,
        totalExits: exitedRecords.length,
        totalAppliedAmount,
        totalAllottedAmount,
        totalRefundAmount,
        grossSaleValue,
        grossBuyCost,
        totalDpCharges,
        totalSttCharges,
        totalCharges: totalDpCharges + totalSttCharges,
        netStcg,
        netLtcg,
        taxableLtcg,
        estimatedStcgTax,
        estimatedLtcgTax,
        totalEstimatedTax,
      },
      records: allRecords.map(formatIpo),
      caShareableText: reportText,
    },
    'CA report generated successfully'
  );
});

module.exports = {
  getIpos,
  createIpo,
  updateIpo,
  deleteIpo,
  syncIpos,
  getCaReport,
};
