# Deploying LEDGER to Vercel (Step-by-Step Guide)

Both the **Node.js Express REST API** and the **Flutter Web App** are configured and ready for live deployment on Vercel.

---

## 1. Prerequisites
Before running the deployment commands:
1. **MongoDB Atlas (Free Cloud Database)**:
   - Create a free M0 cluster on [mongodb.com/atlas](https://www.mongodb.com/atlas).
   - In **Network Access**, click **Add IP Address** -> select **Allow Access from Anywhere (`0.0.0.0/0`)**.
   - In **Database Access**, create a user (e.g. `ledger_admin`) and copy your connection string:
     `mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/ledger_db?retryWrites=true&w=majority`
2. **Vercel Account**:
   - If you don't already have one, sign up at [vercel.com](https://vercel.com).

---

## 2. Deploying the Backend API

Open your terminal in `c:\Users\admin\Downloads\track\backend` and run:

```bash
npx vercel
```

### Prompt Responses:
- **Set up and deploy?**: `y`
- **Which scope?**: *(Select your Vercel personal account / team)*
- **Link to existing project?**: `n`
- **What's your project's name?**: `ledger-api`
- **In which directory is your code located?**: `./`
- **Want to modify these settings?**: `n`

### Set Environment Variables in Vercel:
Go to your project on [vercel.com](https://vercel.com) -> **Settings** -> **Environment Variables**, and add:
- `NODE_ENV`: `production`
- `MONGODB_URI`: `mongodb+srv://<user>:<password>@cluster0.xxxxx.mongodb.net/ledger_db`
- `JWT_ACCESS_SECRET`: `ledger_live_production_jwt_access_secret_2026_xyz`
- `JWT_REFRESH_SECRET`: `ledger_live_production_jwt_refresh_secret_2026_xyz`
- `JWT_ACCESS_EXPIRES_IN`: `15m`
- `JWT_REFRESH_EXPIRES_IN`: `7d`
- `CLIENT_URL`: `*`

Then redeploy production:
```bash
npx vercel --prod
```
*Note your backend URL (e.g. `https://ledger-api.vercel.app`).*

---

## 3. Seed Production Database (One-time)
To seed the test account `bruce@wayne.corp` / `Batman123!` in your live Atlas database:
```bash
MONGODB_URI="mongodb+srv://<user>:<password>@cluster0.xxxxx.mongodb.net/ledger_db" npm run seed
```

---

## 4. Deploying the Flutter Web Frontend

1. Compile the web bundle pointing to your live Vercel backend:
```bash
cd ..\mobile
flutter build web --release --dart-define=API_BASE_URL="https://<your-backend-project>.vercel.app/api/v1"
```

2. Deploy to Vercel:
```bash
npx vercel --prod
```

### Prompt Responses:
- **Set up and deploy?**: `y`
- **Which scope?**: *(Select your account)*
- **Link to existing project?**: `n`
- **What's your project's name?**: `ledger-app`
- **In which directory is your code located?**: `./`

*Vercel will use [`mobile/vercel.json`](file:///c:/Users/admin/Downloads/track/mobile/vercel.json) to serve `build/web` with client-side SPA routing.*

---

## 5. Testing on Real Phone

Once deployed:
1. Open the Vercel URL on your mobile phone browser (e.g. `https://ledger-app.vercel.app`).
2. Log in with:
   - **Email**: `bruce@wayne.corp`
   - **Password**: `Batman123!`
3. Optionally, add to your phone's Home Screen as a PWA (Progressive Web App) with zero app store friction!
