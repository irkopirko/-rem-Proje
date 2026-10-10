import nodemailer from 'nodemailer';

let transporter;

function getTransporter() {
  if (transporter) return transporter;
  if (!process.env.SMTP_HOST) {
    return null;
  }
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: false,
    auth: process.env.SMTP_USER
      ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
      : undefined,
  });
  return transporter;
}

export async function sendMail({ to, subject, text, html }) {
  const tx = getTransporter();
  if (!tx) {
    console.log('[mail:dev]', { to, subject, text });
    return { dev: true };
  }
  return tx.sendMail({
    from: process.env.MAIL_FROM || 'inkakademi@noreply.com',
    to,
    subject,
    text,
    html,
  });
}

export async function sendRegistrationOTP(email, code) {
  const text = `Selam! Dövme yolculuğuna beraber başlamak için sabırsızlanıyoruz.\nOnay kodun: ${code}\nSevgiler,\nInk Akademi Ekibi`;
  return sendMail({
    to: email,
    subject: 'Ink Akademi — Hesap onay kodu',
    text,
  });
}

export async function sendWelcome(email) {
  const text =
    'Hoş geldin! Seni aramızda görmekten mutluluk duyuyoruz. Hadi dövmecilik kariyerini beraber oluşturalım. <3\nInk Akademi Ekibi';
  return sendMail({ to: email, subject: 'Ink Akademi — Hoş geldin', text });
}

export async function sendPasswordChanged(email) {
  const text =
    'Selam! Şifren başarıyla değiştirildi. Sıkı çalışmaya devam et. Sevgiler.\nInk Akademi Ekibi';
  return sendMail({ to: email, subject: 'Ink Akademi — Şifre değiştirildi', text });
}

export async function sendPasswordResetOTP(email, code) {
  const text = `Şifre sıfırlama kodun: ${code}\nInk Akademi Ekibi`;
  return sendMail({ to: email, subject: 'Ink Akademi — Şifre sıfırlama', text });
}
