const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'fongongserge21@gmail.com',
    pass: 'x a u t u o p v g t y t k d b g' // Use an App Password, not your Gmail password!
  }
});

async function sendShipmentEmail({ receiverEmail, receiverName, trackingId, location }) {
  const mailOptions = {
    from: '"TNT Logistics" <fongongserge21@gmail.com>',
    to: receiverEmail,
    subject: 'Your Shipment Status Update',
    html: `
      <p>Dear ${receiverName},</p>
      <p>We are pleased to inform you that your shipment with tracking ID <b>${trackingId}</b> is now at <b>${location}</b>.</p>
      <p>You can track your shipment here: <a href="https://tracking-site-navy.vercel.app" target="_blank">tracking-site-navy.vercel.app</a></p>
      <p>Best regards,<br/>TNT Logistics Team</p>
    `
  };

  await transporter.sendMail(mailOptions);
}

module.exports = { sendShipmentEmail };