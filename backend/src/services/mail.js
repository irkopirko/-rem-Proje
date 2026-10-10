import nodemailer from 'nodemailer';

let transporter;

export class MailDeliveryError extends Error {}

const DEFAULT_FROM = 'Ink Akademi <noreply@inkakademionline.com>';

export function isMailConfigured() {
  return Boolean(process.env.BREVO_API_KEY || process.env.SMTP_HOST);
}

function parseSender(value) {
  const match = /^\s*(.*?)\s*<([^>]+)>\s*$/.exec(value);
  return match ? { name: match[1] || undefined, email: match[2] } : { email: value.trim() };
}

// Railway blocks outbound SMTP below the Pro plan, so Brevo's HTTPS API is preferred when a key is present.
async function sendViaBrevoApi({ to, subject, text, html }) {
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: { 'api-key': process.env.BREVO_API_KEY, 'content-type': 'application/json', accept: 'application/json' },
    body: JSON.stringify({
      sender: parseSender(process.env.MAIL_FROM || DEFAULT_FROM),
      to: [{ email: to }],
      subject,
      textContent: text,
      htmlContent: html,
    }),
    signal: AbortSignal.timeout(15_000),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    const err = new Error(body.slice(0, 300));
    err.code = `HTTP_${res.status}`;
    throw err;
  }
  return res.json();
}

function getTransporter() {
  if (transporter) return transporter;
  if (!process.env.SMTP_HOST) return null;
  const port = Number(process.env.SMTP_PORT || 587);
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port,
    secure: port === 465,
    requireTLS: port !== 465,
    connectionTimeout: 10_000,
    greetingTimeout: 10_000,
    socketTimeout: 15_000,
    auth: process.env.SMTP_USER ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS } : undefined,
  });
  return transporter;
}

export async function sendMail({ to, subject, text, html }) {
  if (!isMailConfigured()) {
    // No mail provider yet: the message is only written to the server log so the flow can still be tested.
    console.log('[mail:dev]', { to, subject, text });
    return { dev: true };
  }
  try {
    if (process.env.BREVO_API_KEY) {
      return await sendViaBrevoApi({ to, subject, text, html });
    }
    return await getTransporter().sendMail({
      from: process.env.MAIL_FROM || DEFAULT_FROM,
      to,
      subject,
      text,
      html,
    });
  } catch (err) {
    console.error('[mail] delivery failed:', err.code || '', err.responseCode || '', err.message);
    throw new MailDeliveryError('Mail delivery failed');
  }
}

/** Informational mails must never make the user's actual request fail. */
async function sendQuietly(message) {
  try {
    await sendMail(message);
  } catch {
    // Already logged in sendMail.
  }
}

const escapeHtml = (s) => s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

function layout(title, bodyHtml) {
  return `<!doctype html><html lang="tr"><body style="margin:0;background:#f4f1ee;font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;color:#111">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:32px 16px"><tr><td align="center">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#fff;border-radius:16px;padding:32px">
      <tr><td style="font-size:20px;font-weight:800;letter-spacing:2px">INK AKADEMI</td></tr>
      <tr><td style="padding-top:20px;font-size:18px;font-weight:700">${escapeHtml(title)}</td></tr>
      <tr><td style="padding-top:12px;font-size:15px;line-height:1.5">${bodyHtml}</td></tr>
      <tr><td style="padding-top:28px;font-size:13px;color:#777">Sevgiler,<br>Ink Akademi Ekibi</td></tr>
    </table>
  </td></tr></table></body></html>`;
}

function codeBlock(code) {
  return `<div style="margin:20px 0;padding:16px;background:#111;color:#fff;border-radius:12px;text-align:center;font-size:32px;font-weight:800;letter-spacing:10px">${escapeHtml(code)}</div>`;
}

export async function sendRegistrationOTP(email, code) {
  const text = `Selam! Dövme yolculuğuna beraber başlamak için sabırsızlanıyoruz.\nOnay kodun: ${code}\nKod 15 dakika geçerlidir.\nSevgiler,\nInk Akademi Ekibi`;
  const html = layout(
    'Hesap onay kodun',
    `Selam! Dövme yolculuğuna beraber başlamak için sabırsızlanıyoruz. Uygulamaya aşağıdaki kodu gir:${codeBlock(code)}Kod 15 dakika geçerlidir. Bu isteği sen yapmadıysan bu e-postayı yok sayabilirsin.`
  );
  return sendMail({ to: email, subject: `Ink Akademi onay kodun: ${code}`, text, html });
}

export async function sendPasswordResetOTP(email, code) {
  const text = `Şifre sıfırlama kodun: ${code}\nKod 15 dakika geçerlidir.\nInk Akademi Ekibi`;
  const html = layout(
    'Şifre sıfırlama kodun',
    `Şifreni sıfırlamak için aşağıdaki kodu uygulamaya gir:${codeBlock(code)}Kod 15 dakika geçerlidir. Bu isteği sen yapmadıysan şifren güvende, bu e-postayı yok sayabilirsin.`
  );
  return sendMail({ to: email, subject: `Ink Akademi şifre sıfırlama kodun: ${code}`, text, html });
}

export async function sendWelcome(email) {
  const text =
    'Hoş geldin! Seni aramızda görmekten mutluluk duyuyoruz. Hadi dövmecilik kariyerini beraber oluşturalım. <3\nInk Akademi Ekibi';
  const html = layout('Hoş geldin!', 'Seni aramızda görmekten mutluluk duyuyoruz. Hadi dövmecilik kariyerini beraber oluşturalım. &lt;3');
  return sendQuietly({ to: email, subject: 'Ink Akademi — Hoş geldin', text, html });
}

export async function sendPasswordChanged(email) {
  const text = 'Selam! Şifren başarıyla değiştirildi. Sıkı çalışmaya devam et. Sevgiler.\nInk Akademi Ekibi';
  const html = layout(
    'Şifren değiştirildi',
    'Şifren başarıyla değiştirildi. Sıkı çalışmaya devam et! Bu değişikliği sen yapmadıysan hemen bizimle iletişime geç.'
  );
  return sendQuietly({ to: email, subject: 'Ink Akademi — Şifre değiştirildi', text, html });
}
