const nodemailer = require('nodemailer');
const env = require('./env');

let transporter = null;

const getTransporter = () => {
  if (!transporter) {
    if (env.smtp.user && env.smtp.pass) {
      transporter = nodemailer.createTransport({
        host: env.smtp.host,
        port: env.smtp.port,
        secure: env.smtp.secure,
        auth: {
          user: env.smtp.user,
          pass: env.smtp.pass,
        },
      });
    } else {
      // In development without credentials, create a stream/json or fallback transporter
      transporter = nodemailer.createTransport({
        jsonTransport: true,
      });
    }
  }
  return transporter;
};

module.exports = {
  getTransporter,
};
