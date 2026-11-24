// Generates docs/email_templates/*.html: branded Supabase Auth e-mails
// (SplitSure logo + name first, then the content, in English and French).
// Run: node tool/email/gen_auth_templates.js
// Then paste each file into Supabase → Authentication → Emails → Templates (subjects in README.md).
const fs = require('fs');
const path = require('path');
const LOGO =
  'https://xcqdanlnbusgztrigfzg.supabase.co/storage/v1/object/public/agreement-assets/branding/splitsure-logo.png';

const shell = (title, body) => `<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light"><title>${title}</title></head>
<body style="margin:0;padding:0;background:#EEF3F8;font-family:Inter,Segoe UI,Helvetica,Arial,sans-serif">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#EEF3F8;padding:24px 12px"><tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;background:#FFFFFF;border-radius:20px;overflow:hidden;box-shadow:0 8px 30px rgba(20,43,74,0.10)">
  <tr><td style="background:#142B4A;background-image:linear-gradient(135deg,#142B4A 0%,#1E3F6F 55%,#0D9488 100%);padding:28px 32px">
    <table role="presentation" cellpadding="0" cellspacing="0"><tr>
      <td style="background:#FFFFFF;border-radius:14px;padding:6px;line-height:0"><img src="${LOGO}" width="44" height="44" alt="SplitSure" style="display:block;border-radius:10px"></td>
      <td style="padding-left:14px">
        <div style="font-size:24px;font-weight:800;letter-spacing:-0.3px;color:#FFFFFF">Split<span style="color:#12B8A6">Sure</span></div>
        <div style="font-size:12px;color:#CBD5E1;margin-top:2px">Protect your music. Promote your sound.</div>
      </td></tr></table>
  </td></tr>
${body}
  <tr><td style="background:#142B4A;background-image:linear-gradient(90deg,#142B4A,#0D9488);padding:16px 32px">
    <p style="margin:0;font-size:11px;line-height:1.6;color:#CBD5E1">Sent to {{ .Email }} by SplitSure. If you didn't ask for this, you can ignore this e-mail.<br>Envoyé à {{ .Email }} par SplitSure. Si vous n'avez rien demandé, ignorez cet e-mail.<br>SplitSure · splitsure.app</p>
  </td></tr>
</table></td></tr></table></body></html>
`;

const codeBox = `  <tr><td align="center" style="padding:20px 32px 0">
    <div style="display:inline-block;border:2px dashed #0D9488;background:#F0FDFA;border-radius:14px;padding:14px 24px">
      <div style="font-size:11px;letter-spacing:1.2px;text-transform:uppercase;color:#0D9488;font-weight:700">Code</div>
      <div style="font-family:Consolas,Menlo,monospace;font-size:30px;font-weight:800;letter-spacing:8px;color:#142B4A;margin-top:4px">{{ .Token }}</div>
    </div>
  </td></tr>
`;

const buttonRow = (b) => `  <tr><td align="center" style="padding:24px 32px 4px">
    <a href="{{ .ConfirmationURL }}" style="display:inline-block;background:#0D9488;background-image:linear-gradient(135deg,#0D9488,#12B8A6);color:#FFFFFF;text-decoration:none;font-size:16px;font-weight:700;padding:15px 36px;border-radius:30px">${b.en} / ${b.fr} &rarr;</a>
  </td></tr>
`;

const fallback = `  <tr><td style="padding:18px 32px 26px">
    <p style="margin:0;font-size:12px;color:#94A3B8">If the button doesn't work / Si le bouton ne fonctionne pas :<br><a href="{{ .ConfirmationURL }}" style="color:#0D9488;word-break:break-all">{{ .ConfirmationURL }}</a></p>
  </td></tr>
`;

const block = (t) =>
  `  <tr><td style="padding:32px 32px 4px">
    <h1 style="margin:0 0 10px;font-size:21px;line-height:1.3;color:#142B4A">${t.en.title}</h1>
    <p style="margin:0;font-size:15px;line-height:1.6;color:#334155">${t.en.body}</p>
  </td></tr>
` +
  (t.code ? codeBox : '') +
  (t.button ? buttonRow(t.button) : '') +
  `  <tr><td style="padding:22px 32px 0"><hr style="border:none;border-top:1px solid #E2E8F0;margin:0"></td></tr>
  <tr><td style="padding:18px 32px 4px">
    <h2 style="margin:0 0 8px;font-size:17px;line-height:1.3;color:#142B4A">${t.fr.title}</h2>
    <p style="margin:0;font-size:14px;line-height:1.6;color:#334155">${t.fr.body}</p>
  </td></tr>
` +
  (t.button ? fallback : '  <tr><td style="padding:0 0 26px"></td></tr>\n');

const templates = {
  confirm_signup: {
    subject: 'Your SplitSure code: {{ .Token }} / Votre code SplitSure : {{ .Token }}',
    en: { title: 'Confirm your email to activate your account', body: 'Welcome to SplitSure! Enter this 6-digit code in the app to confirm your email address and activate your account. The code expires in 1 hour.' },
    fr: { title: 'Confirmez votre e-mail pour activer votre compte', body: "Bienvenue sur SplitSure ! Saisissez ce code à 6 chiffres dans l'application pour confirmer votre adresse e-mail et activer votre compte. Le code expire dans 1 heure." },
    code: true,
  },
  reset_password: {
    subject: 'Your SplitSure reset code / Votre code SplitSure : {{ .Token }}',
    en: { title: 'Reset your password', body: 'Enter this code in the SplitSure app to choose a new password, or simply tap the button. The code expires in 1 hour.' },
    fr: { title: 'Réinitialisez votre mot de passe', body: "Saisissez ce code dans l'application SplitSure pour choisir un nouveau mot de passe, ou touchez simplement le bouton. Le code expire dans 1 heure." },
    code: true,
    button: { en: 'Reset my password', fr: 'Réinitialiser' },
  },
  magic_link: {
    subject: 'Your SplitSure sign-in link / Votre lien de connexion SplitSure',
    en: { title: 'Sign in to SplitSure', body: 'Tap the button to sign in, or enter this code in the app.' },
    fr: { title: 'Connexion à SplitSure', body: "Touchez le bouton pour vous connecter, ou saisissez ce code dans l'application." },
    code: true,
    button: { en: 'Sign in', fr: 'Se connecter' },
  },
  invite_user: {
    subject: "You're invited to SplitSure / Vous êtes invité(e) sur SplitSure",
    en: { title: "You've been invited to SplitSure", body: 'Accept the invitation to create your account and start collaborating.' },
    fr: { title: 'Vous êtes invité(e) sur SplitSure', body: "Acceptez l'invitation pour créer votre compte et commencer à collaborer." },
    button: { en: 'Accept invitation', fr: 'Accepter' },
  },
  change_email: {
    subject: 'Confirm your new e-mail / Confirmez votre nouvelle adresse – SplitSure',
    en: { title: 'Confirm your new e-mail address', body: 'Tap the button to confirm changing your SplitSure e-mail from {{ .Email }} to {{ .NewEmail }}.' },
    fr: { title: 'Confirmez votre nouvelle adresse e-mail', body: 'Touchez le bouton pour confirmer le changement de votre adresse SplitSure de {{ .Email }} vers {{ .NewEmail }}.' },
    button: { en: 'Confirm change', fr: 'Confirmer' },
  },
  reauthentication: {
    subject: 'Your SplitSure verification code / Votre code de vérification : {{ .Token }}',
    en: { title: 'Confirm it is you', body: 'Enter this code in SplitSure to continue.' },
    fr: { title: 'Confirmez votre identité', body: 'Saisissez ce code dans SplitSure pour continuer.' },
    code: true,
  },
};

const out = path.join(__dirname, '..', '..', 'docs', 'email_templates');
fs.mkdirSync(out, { recursive: true });
let readme =
  '# SplitSure – Supabase Auth e-mail templates\n\n' +
  'Generated by `node tool/email/gen_auth_templates.js`. Paste each file into ' +
  'Supabase → Authentication → Emails → Templates with this subject:\n\n' +
  '| Template | File | Subject |\n|---|---|---|\n';
for (const [name, t] of Object.entries(templates)) {
  fs.writeFileSync(path.join(out, `${name}.html`), shell(`${t.en.title} – SplitSure`, block(t)));
  readme += `| ${name.replace(/_/g, ' ')} | ${name}.html | \`${t.subject}\` |\n`;
}
fs.writeFileSync(path.join(out, 'README.md'), readme);
console.log('written', Object.keys(templates).length, 'templates to', out);
