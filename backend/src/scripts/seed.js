const dns = require('dns');
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (e) {
  // Ignore if custom dns servers cannot be set
}
const mongoose = require('mongoose');
const User = require('../models/user.model');
const env = require('../config/env');

const seedData = async () => {
  try {
    console.log('[Seed] Connecting to MongoDB at', env.mongodbUri);
    await mongoose.connect(env.mongodbUri, {
      driverInfo: { name: 'nodejs', version: '1.0.0' },
    });

    const testEmail = 'bruce@wayne.corp';
    const testPassword = 'Batman123!';

    let user = await User.findOne({ email: testEmail });
    if (user) {
      console.log(`[Seed] User ${testEmail} already exists! Resetting password to: ${testPassword}`);
      user.password = testPassword;
      await user.save();
    } else {
      user = await User.create({
        name: 'Bruce Wayne',
        email: testEmail,
        password: testPassword,
        currency: 'INR',
        currencySymbol: '₹',
      });
      console.log(`[Seed] Successfully created demo user: ${testEmail}`);
    }

    console.log('==================================================');
    console.log('  DEMO / TEST CREDENTIALS:');
    console.log(`  Email:    ${testEmail}`);
    console.log(`  Password: ${testPassword}`);
    console.log('==================================================');

    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('[Seed Error]', err);
    process.exit(1);
  }
};

seedData();
