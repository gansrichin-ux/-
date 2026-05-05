const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const mailTransport = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_EMAIL,
    pass: process.env.GMAIL_PASSWORD,
  },
});

exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const code = data.code;

  if (!email || !code) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing email or code."
    );
  }

  const mailOptions = {
    from: `"Logist App" <${process.env.GMAIL_EMAIL}>`,
    to: email,
    subject: "Подтверждение E-mail - Logist App",
    text: `Ваш код подтверждения: ${code}`,
    html: `
      <div style="font-family: sans-serif; max-width: 500px; margin: 0 auto; border: 1px solid #eaeaea; border-radius: 8px; overflow: hidden;">
        <div style="background-color: #2D63ED; padding: 20px; text-align: center;">
          <h2 style="color: white; margin: 0; font-size: 24px;">Logist App</h2>
        </div>
        <div style="padding: 30px 20px; text-align: center;">
          <h3 style="margin-top: 0; color: #333;">Подтверждение E-mail</h3>
          <p style="color: #666; line-height: 1.5; margin-bottom: 25px;">
            Вы начали процесс регистрации (или входа) в Logist App.
            Ниже указан ваш 6-значный код для подтверждения почты.
          </p>
          <div style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #2D63ED; background-color: #f4f7ff; padding: 15px; border-radius: 8px; display: inline-block; margin-bottom: 25px;">
            ${code}
          </div>
          <p style="color: #999; font-size: 12px; margin: 0;">
            Код действителен 10 минут. Если вы не запрашивали этот код, просто проигнорируйте это письмо.
          </p>
        </div>
      </div>
    `,
  };

  try {
    await mailTransport.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error("Error sending email:", error);
    throw new functions.https.HttpsError("internal", error.toString());
  }
});
