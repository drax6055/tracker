# tracker

Financial Ledger & Intelligence Application (Neo-Brutalist Design)

A personal finance management, ledger logging, and financial intelligence platform built with **Flutter** (Web & Mobile) and a secure **Node.js / Express** backend connected to **MongoDB Atlas**.

---

## 🚀 Features

- **Neo-Brutalist High-Contrast UI**: High visual impact with custom brutalist cards, typography, badges, and responsive layouts.
- **Ledger Logs (Transactions)**:
  - Income and expense tracking with real-time categorizations.
  - Interactive **Calendar Date Range Picker** with filter chips and reset controls.
- **Financial Intelligence & Reports**:
  - Breakdown by month, week, year, and custom date ranges.
  - Interactive category spending charts.
  - **PDF Export Engine**: Generate and print comprehensive financial reports directly from browser/app.
- **Preferences & Vault**:
  - Default currency selector (INR, USD, EUR).
  - **Daily Ledger Reminders**: Configurable daily notification alarm time with Master ON/OFF toggle.
  - Account security & password controls.
- **End-to-End Payload Cryptography**:
  - AES-256-CBC symmetric payload encryption & decryption across client and server.
  - Field-level database encryption for sensitive transaction data.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (3.27+), Flutter Riverpod, GoRouter, Dio, Printing/PDF, FlChart.
- **Backend**: Node.js, Express, MongoDB Atlas, Mongoose, JWT, Helmet, Rate Limiter.
- **Deployment**: Vercel Serverless Edge (Backend) & Vercel Web (Frontend).
