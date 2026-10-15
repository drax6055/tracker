const { getTransporter } = require('../config/mailer');
const env = require('../config/env');

class EmailService {
  static async sendOtpEmail(toEmail, otp) {
    const transporter = getTransporter();

    const subject = 'LEDGER - Your Password Reset OTP';
    const text = `Your OTP for resetting your LEDGER password is ${otp}. It is valid for 10 minutes. If you did not request this, please ignore this email.`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; background: #0D0D0D; color: #FFFFFF; border: 3px solid #FFE600; padding: 24px;">
        <h2 style="color: #FFE600; text-transform: uppercase; letter-spacing: 1px; margin-top: 0;">LEDGER SECURITY</h2>
        <p style="font-size: 15px; color: #B3B3B3;">You requested a password reset. Use the OTP code below to continue:</p>
        <div style="background: #1A1A1A; border: 2px solid #FFFFFF; padding: 16px; text-align: center; margin: 20px 0;">
          <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #FFE600; font-family: monospace;">${otp}</span>
        </div>
        <p style="font-size: 13px; color: #B3B3B3;">This OTP is valid for <strong>10 minutes</strong> and maximum 5 attempts.</p>
        <p style="font-size: 12px; color: #777777; margin-bottom: 0;">If you did not request this, please secure your account immediately.</p>
      </div>
    `;

    try {
      const info = await transporter.sendMail({
        from: env.smtp.from,
        to: toEmail,
        subject,
        text,
        html,
      });

      console.log(`[EmailService] OTP sent to ${toEmail}. MessageId: ${info.messageId || 'local-json'}`);
      // In dev or test mode, also log OTP clearly so tester doesn't need external inbox
      if (env.env !== 'production') {
        console.log(`[EmailService DEV LOG] >>> OTP for ${toEmail} is: [${otp}] <<<`);
      }
      return info;
    } catch (error) {
      console.error(`[EmailService Error] Failed to send email to ${toEmail}: ${error.message}`);
      // In local dev, still log OTP so the user can continue testing
      if (env.env !== 'production') {
        console.log(`[EmailService DEV FALLBACK] >>> OTP for ${toEmail} is: [${otp}] <<<`);
      }
      return null;
    }
  }
}

module.exports = EmailService;
