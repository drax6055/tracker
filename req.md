# PROJECT: "LEDGER" - Personal Money Management App (Flutter + Node.js)

You are a senior full-stack engineer. Build a complete, production-structured
money management application with a Flutter mobile app and a Node.js REST API.
Generate the full code, folder structure, setup instructions, and .env examples.

---------------------------------------------------------------
## 1. TECH STACK
---------------------------------------------------------------
**Mobile:** Flutter (latest stable), Dart null-safety
- State management: Riverpod (or Bloc, pick one and stay consistent)
- Navigation: go_router
- HTTP: dio with interceptors (auth token attach, auto-refresh on 401)
- Secure storage: flutter_secure_storage for tokens
- Charts: fl_chart
- Forms/validation: reactive validation with clear inline errors
- Fonts: google_fonts (Space Grotesk / Space Mono / Archivo Black)

**Backend:** Node.js (LTS) + Express
- Database: MongoDB with Mongoose
- Auth: JWT access token (15 min) + refresh token (7 days, stored hashed in DB)
- Password hashing: bcrypt
- Validation: zod or Joi
- Email: Nodemailer (SMTP) for OTP / reset emails
- Security: helmet, cors, express-rate-limit, mongo-sanitize
- Structure: routes -> controllers -> services -> models, plus middleware
- Centralized error handler, consistent JSON response format
- Config via dotenv

---------------------------------------------------------------
## 2. AUTHENTICATION FEATURES
---------------------------------------------------------------
1. **Register:** name, email, password, confirm password.
   Password rules: min 8 chars, 1 number, 1 letter.
2. **Login:** email + password, "show/hide password" toggle,
   stay logged in via refresh token.
3. **Forgot password flow:**
   - Enter email -> backend sends a 6-digit OTP (valid 10 min, max 5 attempts)
   - Verify OTP screen with resend timer (30s)
   - Set new password screen
   - Invalidate all refresh tokens after reset
4. **Logout** (revokes refresh token) and **Change password** in Settings.
5. Auth guard: unauthenticated users can only see Login / Register / Forgot screens.
6. Splash screen checks stored token and routes accordingly.

---------------------------------------------------------------
## 3. CORE MONEY MODULES
---------------------------------------------------------------
### 3.1 Accounts (multiple of each type)
Account types:
- **Bank Account:** name, bank name, last 4 digits, current balance
- **Cash:** wallet name, balance
- **Credit Card:** name, bank, credit limit, outstanding balance,
  billing date, due date; show available credit and utilization %
- **Loan (I owe the bank):** lender, principal, interest rate, EMI amount,
  EMI date, tenure, remaining amount, remaining installments;
  allow marking an EMI as paid (which creates an expense transaction)

Every account has: icon/color tag, "include in net worth" toggle,
archive option (soft delete).

### 3.2 Borrowed & Receivable (people ledger)
- **Borrowed (I have to pay):** person name, amount, date taken, due date, notes
- **Lent (I have to receive):** person name, amount, date given, due date, notes
- Support **partial payments** with a history timeline per entry
- Status: Pending / Partially Paid / Settled / Overdue
- Dashboard shows "Total to Pay" and "Total to Receive"
- Local push reminders for due dates (flutter_local_notifications)

### 3.3 Transactions
Types: Income, Expense, Transfer (account to account),
Credit Card Payment (bank -> card), EMI Payment, Borrow/Lend settlement.
Fields: amount, type, category, account, date/time, note, tags, optional
attachment (receipt image), recurring flag (daily/weekly/monthly).
- Balances must update atomically (use MongoDB transactions/sessions).
- Editing or deleting a transaction must correctly reverse/reapply balance changes.
- Credit card expense increases outstanding; payment decreases it.
- Transfer creates linked entries that cannot go out of sync.

### 3.4 Categories
Default set (Food, Rent, Travel, Bills, Shopping, Health, Salary, Freelance,
Investment, etc.) plus user-created custom categories with icon + color.

### 3.5 Budgets (simple)
Monthly budget per category with progress bar and warning at 80% / 100%.

---------------------------------------------------------------
## 4. DASHBOARD & REPORTS
---------------------------------------------------------------
**Dashboard (home):**
- Net worth card = assets (bank + cash + receivable) - liabilities
  (credit card outstanding + loans + borrowed)
- This-month income, expense, savings
- Horizontal account cards (grouped by type)
- "To Pay" and "To Receive" summary strips with upcoming due items
- Last 10 transactions
- Quick-add FAB (big square button)

**Reports screen** with filters: This week / Month / Year / Custom range,
by account, by category.
Charts (fl_chart), all styled in brutalist style (see section 5):
1. Income vs Expense - grouped bar chart (monthly)
2. Expense by category - donut/pie with legend
3. Daily spending trend - line chart
4. Net worth over time - line chart
5. Account balance distribution - horizontal bars
6. Credit card utilization - progress bars
7. Loan payoff progress - progress bars
Also: summary table (total income, expense, savings rate, top 5 categories),
and **Export to CSV/PDF**.

---------------------------------------------------------------
## 5. UI / UX - DARK MODE + NEO-BRUTALISM (STRICT)
---------------------------------------------------------------
The app is **dark mode only**. Follow the neo-brutalism design language strictly:

**Colors**
- Background: #0D0D0D, surface/cards: #1A1A1A
- Borders and hard shadows: #FFFFFF or #F5F5F5
- Text primary: #FFFFFF, secondary: #B3B3B3
- Accent colors (flat, saturated, no gradients):
  Yellow #FFE600 (primary), Hot Pink #FF3EA5, Lime #B6FF00,
  Cyan #00E5FF, Orange #FF6B00, Red #FF3B3B (expense/danger),
  Green #00E676 (income)

**Shape & depth**
- Thick borders: 3px solid on cards, buttons, inputs, chips, dialogs
- Square or near-square corners (radius 0 to 4px max). No rounded pills
- Hard offset shadows with zero blur: e.g. offset (6, 6) in white or accent color
- No gradients, no glassmorphism, no soft shadows, no blur
- Pressed state: button shifts by the shadow offset and the shadow disappears
  (tactile "push" effect)

**Typography**
- Headings: Archivo Black or Space Grotesk Bold, UPPERCASE, tight letter-spacing
- Numbers/amounts: Space Mono bold, large and chunky
- Body: Space Grotesk regular
- Big oversized typography on dashboard figures

**Components to build as reusable widgets**
BrutalButton, BrutalCard, BrutalTextField, BrutalChip, BrutalDialog,
BrutalBottomNav (thick top border, active tab filled with accent color),
BrutalAppBar, BrutalProgressBar (blocky, segmented), BrutalToggle,
BrutalDropdown, BrutalToast/Snackbar, BrutalEmptyState.

**Layout details**
- Visible grid feel, generous spacing, strong alignment
- Cards can be slightly rotated (max 1 deg) only for decorative stickers/labels
- Use "sticker" labels (e.g. status tags like OVERDUE, PAID) with
  border + hard shadow
- Charts: flat solid fills, thick black/white strokes, no smooth gradients,
  square bar corners, bold axis labels in Space Mono
- Animations: minimal and snappy (150-200ms), no soft fades or springy motion
- Haptic feedback on key actions

**Accessibility:** maintain contrast ratio >= 4.5:1, min tap size 48px,
support large text scaling.

---------------------------------------------------------------
## 6. SCREENS LIST
---------------------------------------------------------------
Splash, Login, Register, Forgot Password (email), Verify OTP,
Reset Password, Dashboard, Accounts list, Add/Edit Account,
Account detail (with its transactions), Transactions list (search + filters),
Add/Edit Transaction, Borrowed/Lent list, Add/Edit entry + payment history,
Budgets, Reports, Categories manager, Settings
(profile, change password, currency, export data, logout, delete account).

---------------------------------------------------------------
## 7. API (REST, prefix /api/v1)
---------------------------------------------------------------
Auth: POST /auth/register, /auth/login, /auth/refresh, /auth/logout,
      /auth/forgot-password, /auth/verify-otp, /auth/reset-password,
      /auth/change-password
Accounts: CRUD /accounts
Transactions: CRUD /transactions (pagination, filters: date, type,
      account, category, search)
Transfers: POST /transfers
People ledger: CRUD /debts (type: borrowed|lent),
      POST /debts/:id/payments
Categories: CRUD /categories
Budgets: CRUD /budgets
Reports: GET /reports/summary, /reports/category-breakdown,
      /reports/monthly-trend, /reports/net-worth, /reports/export
Dashboard: GET /dashboard
User: GET/PATCH /user/me, DELETE /user/me

All protected routes require Bearer token. Paginate list endpoints.
Return `{ success, data, message }` format. Document with a Postman
collection or OpenAPI file.

---------------------------------------------------------------
## 8. DATA MODELS (Mongoose)
---------------------------------------------------------------
User, RefreshToken, PasswordResetOtp, Account (type enum, type-specific
fields), Transaction, Category, Debt (borrowed/lent), DebtPayment, Budget.
Add indexes on userId, date, accountId, categoryId. Use integer/paise or
Decimal128 for money, never floating point.

---------------------------------------------------------------
## 9. NON-FUNCTIONAL REQUIREMENTS
---------------------------------------------------------------
- Currency default INR (₹) with Indian number formatting (lakh/crore);
  currency selectable in settings
- Offline-friendly: cache last dashboard data locally (Hive/Isar),
  show stale data banner when offline
- Loading skeletons in brutalist style (flat blocks), proper error states
- Unit tests for balance calculation logic, auth service, and report aggregation
- Clean architecture, meaningful naming, comments only where useful
- ESLint + Prettier (Node), flutter analyze clean

---------------------------------------------------------------
## 10. DELIVERABLES
---------------------------------------------------------------
1. Full backend code with folder structure
2. Full Flutter code with folder structure (feature-first)
3. Theme file with all brutalist design tokens
4. Seed script for default categories and demo data
5. README with setup steps (env vars, run commands, SMTP setup)
6. Postman collection

Build in this order: backend auth -> accounts -> transactions -> debts ->
reports -> Flutter theme + components -> auth screens -> dashboard ->
remaining screens -> charts. After each phase, summarize what was built and
wait for my "continue" before moving to the next.