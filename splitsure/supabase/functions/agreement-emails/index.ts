// SplitSure – agreement-emails Edge Function
//
// 1. Send invitations (creator's session required)
//      POST { agreement_id, note? } → { configured, sent, skipped, failed, missing? }
//    E-mails every collaborator line with an address (except the creator) a branded
//    message with two buttons:
//      • "Approve & sign"  → APP_URL/approve/<one-time token>   (no sign-in needed)
//      • "Review details"  → APP_URL/invite/<invite token>     (sign in, request changes…)
//    Each (line, version) is e-mailed at most once (agreement_email_log).
//
// 2. Approve from the e-mail (public – the token is the proof of the inbox)
//      POST { action: "approval_info", token } → summary for the approval page
//      POST { action: "approve", token }       → { status, signature_code }
//    Only the SHA-256 hash of the token is stored (agreement_approval_tokens), and the
//    creator never sees the token, so nobody can sign on someone else's behalf. After
//    signing, the collaborator gets a confirmation e-mail with their signature code.
//
// Every e-mail uses the same branded shell: SplitSure logo + name, then the content.
//
// Secrets: GMAIL_USER + GMAIL_APP_PASSWORD (or RESEND_API_KEY + EMAIL_FROM), APP_URL.
// Deploy with --no-verify-jwt (the approval page is used signed out; sending checks the user itself).

import { createClient } from "jsr:@supabase/supabase-js@2";
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const admin = createClient(SUPABASE_URL, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
// The app icon, served from the same site the e-mail links point to.
const LOGO_URL = `${(Deno.env.get("APP_URL") ?? "https://splitsure.vercel.app").replace(/\/+$/, "")}/icons/Icon-192.png`;

type Lang = "en" | "fr";

const T = {
  en: {
    subjectNew: (song: string) => `Review & approve: “${song}” – SplitSure`,
    subjectUpdate: (song: string, v: number) => `Updated agreement (v${v}): “${song}” – SplitSure`,
    subjectSigned: (song: string) => `You signed “${song}” – SplitSure`,
    titleNew: "You're invited to review a collaboration agreement",
    titleUpdate: "An updated agreement needs your approval",
    titleSigned: "Your signature is on the agreement",
    hi: (n: string) => `Hi ${n},`,
    introNew: (o: string, s: string) => `<b>${o}</b> added you to the split agreement for <b>“${s}”</b> and is waiting for your approval.`,
    introUpdate: (o: string, s: string, v: number) => `<b>${o}</b> updated the split agreement for <b>“${s}”</b> (version ${v}). Please review the new terms and approve them.`,
    introSigned: (s: string) => `You approved the split agreement for <b>“${s}”</b>. Your electronic signature below is now printed on the agreement document.`,
    song: "Song", reference: "Reference", version: "Version", yourRole: "Your role", yourShare: "Your share",
    parties: "All parties", party: "Name", role: "Role", share: "Share",
    noteFrom: (o: string) => `Note from ${o}`,
    cta: "Approve & sign",
    review: "Review details or request changes",
    how: "<b>Approve &amp; sign</b> opens a secure page where one tap records your approval – no account needed. Your signature code is then printed on the agreement. To ask for changes or decline, use the second link.",
    hasAccount: "Already on SplitSure? The agreement is also waiting in your notifications.",
    noAccount: "Not on SplitSure yet? You can still approve with the button above.",
    fallback: "If the button doesn't work, copy this link into your browser:",
    why: (o: string, e: string) => `You received this e-mail because ${o} added ${e} to an agreement on SplitSure.`,
    whySigned: (e: string) => `Sent to ${e} after you approved an agreement on SplitSure.`,
    sigCode: "Signature code", signedOn: "Signed on", status: "Agreement status",
    statusAccepted: "Approved by all parties", statusPending: "Waiting for the other parties",
    keep: "Keep this e-mail: the code identifies your approval on the agreement document.",
    open: "Open SplitSure",
    tagline: "Protect your music. Promote your sound.",
    someone: "A SplitSure user",
    you: "you",
    wSubject: (song: string) => `Witness request: “${song}” – SplitSure`,
    wSubjectDone: (song: string) => `You witnessed “${song}” – SplitSure`,
    wTitle: "You are asked to witness a collaboration agreement",
    wIntro: (o: string, s: string) => `<b>${o}</b> named you as the witness of the split agreement for <b>“${s}”</b>. Please confirm that you witnessed this agreement, or decline if you did not.`,
    wRole: "Your role", wRoleValue: "Witness",
    wConfirm: "Confirm as witness", wDecline: "Decline",
    wHow: "<b>Confirm as witness</b> opens a secure page where one tap records your confirmation – no account needed. Your witness code is then printed on the agreement.",
    wWhy: (o: string, e: string) => `You received this e-mail because ${o} named ${e} as the witness of an agreement on SplitSure.`,
    wTitleDone: "Your witness confirmation is recorded",
    wIntroDone: (s: string) => `You confirmed that you witnessed the split agreement for <b>“${s}”</b>. Your witness code below is printed on the agreement document.`,
    wCode: "Witness code",
  },
  fr: {
    subjectNew: (song: string) => `À examiner et approuver : « ${song} » – SplitSure`,
    subjectUpdate: (song: string, v: number) => `Accord mis à jour (v${v}) : « ${song} » – SplitSure`,
    subjectSigned: (song: string) => `Vous avez signé « ${song} » – SplitSure`,
    titleNew: "Vous êtes invité(e) à examiner un accord de collaboration",
    titleUpdate: "Un accord mis à jour attend votre approbation",
    titleSigned: "Votre signature figure sur l'accord",
    hi: (n: string) => `Bonjour ${n},`,
    introNew: (o: string, s: string) => `<b>${o}</b> vous a ajouté(e) à l'accord de partage pour <b>« ${s} »</b> et attend votre approbation.`,
    introUpdate: (o: string, s: string, v: number) => `<b>${o}</b> a modifié l'accord de partage pour <b>« ${s} »</b> (version ${v}). Veuillez examiner les nouvelles conditions et les approuver.`,
    introSigned: (s: string) => `Vous avez approuvé l'accord de partage pour <b>« ${s} »</b>. Votre signature électronique ci-dessous figure désormais sur le document.`,
    song: "Titre", reference: "Référence", version: "Version", yourRole: "Votre rôle", yourShare: "Votre part",
    parties: "Toutes les parties", party: "Nom", role: "Rôle", share: "Part",
    noteFrom: (o: string) => `Message de ${o}`,
    cta: "Approuver et signer",
    review: "Voir les détails ou demander des modifications",
    how: "<b>Approuver et signer</b> ouvre une page sécurisée où une seule touche enregistre votre approbation – sans compte. Votre code de signature est ensuite imprimé sur l'accord. Pour demander des modifications ou refuser, utilisez le second lien.",
    hasAccount: "Déjà sur SplitSure ? L'accord vous attend aussi dans vos notifications.",
    noAccount: "Pas encore sur SplitSure ? Vous pouvez quand même approuver avec le bouton ci-dessus.",
    fallback: "Si le bouton ne fonctionne pas, copiez ce lien dans votre navigateur :",
    why: (o: string, e: string) => `Vous recevez cet e-mail car ${o} a ajouté ${e} à un accord sur SplitSure.`,
    whySigned: (e: string) => `Envoyé à ${e} après votre approbation d'un accord sur SplitSure.`,
    sigCode: "Code de signature", signedOn: "Signé le", status: "Statut de l'accord",
    statusAccepted: "Approuvé par toutes les parties", statusPending: "En attente des autres parties",
    keep: "Conservez cet e-mail : le code identifie votre approbation sur le document.",
    open: "Ouvrir SplitSure",
    tagline: "Protégez votre musique. Faites connaître votre talent.",
    someone: "Un utilisateur SplitSure",
    you: "vous",
    wSubject: (song: string) => `Demande de témoin : « ${song} » – SplitSure`,
    wSubjectDone: (song: string) => `Vous êtes témoin de « ${song} » – SplitSure`,
    wTitle: "Vous êtes sollicité(e) comme témoin d'un accord de collaboration",
    wIntro: (o: string, s: string) => `<b>${o}</b> vous a désigné(e) comme témoin de l'accord de partage pour <b>« ${s} »</b>. Veuillez confirmer que vous avez été témoin de cet accord, ou refuser si ce n'est pas le cas.`,
    wRole: "Votre rôle", wRoleValue: "Témoin",
    wConfirm: "Confirmer comme témoin", wDecline: "Refuser",
    wHow: "<b>Confirmer comme témoin</b> ouvre une page sécurisée où une seule touche enregistre votre confirmation – sans compte. Votre code de témoin est ensuite imprimé sur l'accord.",
    wWhy: (o: string, e: string) => `Vous recevez cet e-mail car ${o} a désigné ${e} comme témoin d'un accord sur SplitSure.`,
    wTitleDone: "Votre confirmation de témoin est enregistrée",
    wIntroDone: (s: string) => `Vous avez confirmé avoir été témoin de l'accord de partage pour <b>« ${s} »</b>. Votre code de témoin ci-dessous figure sur le document.`,
    wCode: "Code de témoin",
  },
};

const esc = (s: unknown) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));
const pct = (n: number) => `${Number(n).toLocaleString("en-US", { maximumFractionDigits: 2 })}%`;
const nameOf = (p: any) => [p?.first_name, p?.last_name].filter((x) => x && String(x).trim()).join(" ").trim();
const strip = (h: string) => h.replace(/<[^>]+>/g, "").replace(/&amp;/g, "&");

/** The branded frame every SplitSure e-mail uses: logo + name first, then the content. */
export function brandShell(o: { lang: Lang; subject: string; preheader: string; body: string; footer: string }) {
  const t = T[o.lang];
  return `<!doctype html>
<html lang="${o.lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light"><title>${esc(o.subject)}</title></head>
<body style="margin:0;padding:0;background:#EEF3F8;font-family:Inter,Segoe UI,Helvetica,Arial,sans-serif">
<div style="display:none;max-height:0;overflow:hidden;opacity:0">${esc(o.preheader)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#EEF3F8;padding:24px 12px">
<tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;background:#FFFFFF;border-radius:20px;overflow:hidden;box-shadow:0 8px 30px rgba(20,43,74,0.10)">
  <tr><td style="background:#142B4A;background-image:linear-gradient(135deg,#142B4A 0%,#1E3F6F 55%,#0D9488 100%);padding:28px 32px">
    <table role="presentation" cellpadding="0" cellspacing="0"><tr>
      <td style="background:#FFFFFF;border-radius:14px;padding:6px;line-height:0"><img src="${LOGO_URL}" width="44" height="44" alt="SplitSure" style="display:block;border-radius:10px"></td>
      <td style="padding-left:14px">
        <div style="font-size:24px;font-weight:800;letter-spacing:-0.3px;color:#FFFFFF">Split<span style="color:#12B8A6">Sure</span></div>
        <div style="font-size:12px;color:#CBD5E1;margin-top:2px">${t.tagline}</div>
      </td></tr></table>
  </td></tr>
  ${o.body}
  <tr><td style="background:#142B4A;background-image:linear-gradient(90deg,#142B4A,#0D9488);padding:16px 32px">
    <p style="margin:0;font-size:11px;line-height:1.6;color:#CBD5E1">${o.footer}<br>SplitSure · splitsure.app</p>
  </td></tr>
</table>
</td></tr></table>
</body></html>`;
}

const button = (href: string, label: string) =>
  `<a href="${esc(href)}" style="display:inline-block;background:#0D9488;background-image:linear-gradient(135deg,#0D9488,#12B8A6);color:#FFFFFF;text-decoration:none;font-size:16px;font-weight:700;padding:15px 36px;border-radius:30px">${label} &rarr;</a>`;

const detailRow = (label: string, value: string) =>
  `<tr><td style="padding:6px 0;color:#64748B;font-size:13px;width:42%">${label}</td>` +
  `<td style="padding:6px 0;color:#142B4A;font-size:14px;font-weight:600">${value}</td></tr>`;

interface Party { name: string; role: string; share: number; isRecipient: boolean }

export function renderEmail(o: {
  lang: Lang; isUpdate: boolean; recipientName: string; ownerName: string; song: string; reference: string;
  version: number; role: string; share: number; parties: Party[]; note?: string | null;
  approveLink: string; reviewLink: string; email: string; hasAccount: boolean;
}) {
  const t = T[o.lang];
  const owner = esc(o.ownerName);
  const song = esc(o.song);
  const title = o.isUpdate ? t.titleUpdate : t.titleNew;
  const intro = o.isUpdate ? t.introUpdate(owner, song, o.version) : t.introNew(owner, song);
  const subject = o.isUpdate ? t.subjectUpdate(o.song, o.version) : t.subjectNew(o.song);
  const partyRows = o.parties.map((p) =>
    `<tr style="${p.isRecipient ? "background:#E6F7F5;" : ""}">` +
    `<td style="padding:10px 12px;border-top:1px solid #E2E8F0;color:#142B4A;font-size:13px;font-weight:${p.isRecipient ? 700 : 500}">${esc(p.name)}${p.isRecipient ? ` <span style="color:#0D9488;font-weight:600">(${t.you})</span>` : ""}</td>` +
    `<td style="padding:10px 12px;border-top:1px solid #E2E8F0;color:#64748B;font-size:13px">${esc(p.role)}</td>` +
    `<td style="padding:10px 12px;border-top:1px solid #E2E8F0;color:#142B4A;font-size:13px;font-weight:700;text-align:right">${pct(p.share)}</td></tr>`
  ).join("");

  const body = `
  <tr><td style="padding:32px 32px 8px">
    <h1 style="margin:0 0 14px;font-size:21px;line-height:1.3;color:#142B4A">${title}</h1>
    <p style="margin:0 0 8px;font-size:15px;color:#334155">${t.hi(esc(o.recipientName))}</p>
    <p style="margin:0;font-size:15px;line-height:1.6;color:#334155">${intro}</p>
  </td></tr>
  <tr><td style="padding:20px 32px 0">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F5F8FA;border-radius:14px;padding:18px 20px">
      <tr><td>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
          ${detailRow(t.song, song)}
          ${detailRow(t.reference, esc(o.reference))}
          ${detailRow(t.version, String(o.version))}
          ${detailRow(t.yourRole, esc(o.role))}
        </table>
      </td>
      <td align="right" valign="middle" style="padding-left:12px">
        <div style="background:#0D9488;border-radius:14px;padding:12px 16px;text-align:center;min-width:92px">
          <div style="font-size:11px;letter-spacing:1px;text-transform:uppercase;color:#CCFBF1">${t.yourShare}</div>
          <div style="font-size:26px;font-weight:800;color:#FFFFFF">${pct(o.share)}</div>
        </div>
      </td></tr>
    </table>
  </td></tr>
  <tr><td style="padding:22px 32px 0">
    <div style="font-size:11px;letter-spacing:1.2px;text-transform:uppercase;color:#0D9488;font-weight:700;margin-bottom:8px">${t.parties}</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #E2E8F0;border-radius:12px;border-collapse:separate;overflow:hidden">
      <tr style="background:#142B4A">
        <td style="padding:9px 12px;color:#FFFFFF;font-size:11px;letter-spacing:1px;text-transform:uppercase">${t.party}</td>
        <td style="padding:9px 12px;color:#FFFFFF;font-size:11px;letter-spacing:1px;text-transform:uppercase">${t.role}</td>
        <td style="padding:9px 12px;color:#FFFFFF;font-size:11px;letter-spacing:1px;text-transform:uppercase;text-align:right">${t.share}</td>
      </tr>
      ${partyRows}
    </table>
  </td></tr>
  ${o.note ? `<tr><td style="padding:20px 32px 0">
    <div style="border-left:4px solid #12B8A6;background:#F0FDFA;border-radius:8px;padding:12px 16px">
      <div style="font-size:12px;color:#0D9488;font-weight:700;margin-bottom:4px">${t.noteFrom(owner)}</div>
      <div style="font-size:14px;color:#334155;line-height:1.5;white-space:pre-line">${esc(o.note)}</div>
    </div></td></tr>` : ""}
  <tr><td align="center" style="padding:28px 32px 6px">${button(o.approveLink, t.cta)}</td></tr>
  <tr><td align="center" style="padding:10px 32px 0">
    <a href="${esc(o.reviewLink)}" style="color:#0D9488;font-size:14px;font-weight:600;text-decoration:underline">${t.review}</a>
  </td></tr>
  <tr><td style="padding:14px 32px 0;text-align:center">
    <p style="margin:0 0 8px;font-size:13px;line-height:1.6;color:#64748B">${t.how}</p>
    <p style="margin:0;font-size:13px;line-height:1.6;color:#64748B">${o.hasAccount ? t.hasAccount : t.noAccount}</p>
  </td></tr>
  <tr><td style="padding:18px 32px 26px">
    <p style="margin:0;font-size:12px;color:#94A3B8">${t.fallback}<br><a href="${esc(o.approveLink)}" style="color:#0D9488;word-break:break-all">${esc(o.approveLink)}</a></p>
  </td></tr>`;

  const html = brandShell({ lang: o.lang, subject, preheader: `${title} – ${o.song}`, body, footer: t.why(owner, esc(o.email)) });
  const text = [
    "SplitSure", "", title, "", t.hi(o.recipientName),
    strip(o.isUpdate ? t.introUpdate(o.ownerName, o.song, o.version) : t.introNew(o.ownerName, o.song)),
    "", `${t.song}: ${o.song}`, `${t.reference}: ${o.reference}`, `${t.version}: ${o.version}`,
    `${t.yourRole}: ${o.role}`, `${t.yourShare}: ${pct(o.share)}`, "", `${t.parties}:`,
    ...o.parties.map((p) => `- ${p.name} · ${p.role} · ${pct(p.share)}`),
    ...(o.note ? ["", `${t.noteFrom(o.ownerName)}: ${o.note}`] : []),
    "", `${t.cta}: ${o.approveLink}`, `${t.review}: ${o.reviewLink}`, "", strip(t.how),
    "", "SplitSure – splitsure.app",
  ].join("\n");
  return { subject, html, text };
}

export function renderSignedEmail(o: {
  lang: Lang; name: string; song: string; reference: string; version: number; code: string;
  signedAt: Date; fullyAccepted: boolean; email: string; appUrl: string;
}) {
  const t = T[o.lang];
  const subject = t.subjectSigned(o.song);
  const date = o.signedAt.toLocaleString(o.lang === "fr" ? "fr-FR" : "en-GB",
    { dateStyle: "long", timeStyle: "short", timeZone: "Africa/Douala" });
  const body = `
  <tr><td style="padding:32px 32px 8px">
    <h1 style="margin:0 0 14px;font-size:21px;line-height:1.3;color:#142B4A">${t.titleSigned}</h1>
    <p style="margin:0 0 8px;font-size:15px;color:#334155">${t.hi(esc(o.name))}</p>
    <p style="margin:0;font-size:15px;line-height:1.6;color:#334155">${t.introSigned(esc(o.song))}</p>
  </td></tr>
  <tr><td align="center" style="padding:22px 32px 0">
    <div style="border:2px dashed #0D9488;background:#F0FDFA;border-radius:14px;padding:16px 20px">
      <div style="font-size:11px;letter-spacing:1.2px;text-transform:uppercase;color:#0D9488;font-weight:700">${t.sigCode}</div>
      <div style="font-family:Consolas,Menlo,monospace;font-size:24px;font-weight:800;letter-spacing:2px;color:#142B4A;margin-top:6px">${esc(o.code)}</div>
    </div>
  </td></tr>
  <tr><td style="padding:20px 32px 0">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F5F8FA;border-radius:14px;padding:14px 20px">
      ${detailRow(t.song, esc(o.song))}
      ${detailRow(t.reference, esc(o.reference))}
      ${detailRow(t.version, String(o.version))}
      ${detailRow(t.signedOn, esc(date))}
      ${detailRow(t.status, o.fullyAccepted ? t.statusAccepted : t.statusPending)}
    </table>
  </td></tr>
  <tr><td style="padding:16px 32px 0;text-align:center">
    <p style="margin:0;font-size:13px;line-height:1.6;color:#64748B">${t.keep}</p>
  </td></tr>
  <tr><td align="center" style="padding:22px 32px 28px">${button(o.appUrl, t.open)}</td></tr>`;
  const html = brandShell({ lang: o.lang, subject, preheader: `${t.sigCode}: ${o.code}`, body, footer: t.whySigned(esc(o.email)) });
  const text = [
    "SplitSure", "", t.titleSigned, "", t.hi(o.name), strip(t.introSigned(o.song)), "",
    `${t.sigCode}: ${o.code}`, `${t.song}: ${o.song}`, `${t.reference}: ${o.reference}`, `${t.version}: ${o.version}`,
    `${t.signedOn}: ${date}`, `${t.status}: ${o.fullyAccepted ? t.statusAccepted : t.statusPending}`, "", t.keep,
    "", "SplitSure – splitsure.app",
  ].join("\n");
  return { subject, html, text };
}

export function renderWitnessEmail(o: {
  lang: Lang; isUpdate: boolean; witnessName: string; ownerName: string; song: string; reference: string;
  version: number; parties: Party[]; note?: string | null; confirmLink: string; declineLink: string;
  email: string; hasAccount: boolean;
}) {
  const t = T[o.lang];
  const owner = esc(o.ownerName);
  const song = esc(o.song);
  const subject = o.isUpdate ? `${t.wSubject(o.song)} (v${o.version})` : t.wSubject(o.song);
  const partyRows = o.parties.map((p) =>
    `<tr><td style="padding:10px 12px;border-top:1px solid #E2E8F0;color:#142B4A;font-size:13px;font-weight:500">${esc(p.name)}</td>` +
    `<td style="padding:10px 12px;border-top:1px solid #E2E8F0;color:#64748B;font-size:13px">${esc(p.role)}</td>` +
    `<td style="padding:10px 12px;border-top:1px solid #E2E8F0;color:#142B4A;font-size:13px;font-weight:700;text-align:right">${pct(p.share)}</td></tr>`
  ).join("");
  const body = `
  <tr><td style="padding:32px 32px 8px">
    <h1 style="margin:0 0 14px;font-size:21px;line-height:1.3;color:#142B4A">${t.wTitle}</h1>
    <p style="margin:0 0 8px;font-size:15px;color:#334155">${t.hi(esc(o.witnessName))}</p>
    <p style="margin:0;font-size:15px;line-height:1.6;color:#334155">${t.wIntro(owner, song)}</p>
  </td></tr>
  <tr><td style="padding:20px 32px 0">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F5F8FA;border-radius:14px;padding:18px 20px">
      ${detailRow(t.song, song)}
      ${detailRow(t.reference, esc(o.reference))}
      ${detailRow(t.version, String(o.version))}
      ${detailRow(t.wRole, t.wRoleValue)}
    </table>
  </td></tr>
  <tr><td style="padding:22px 32px 0">
    <div style="font-size:11px;letter-spacing:1.2px;text-transform:uppercase;color:#0D9488;font-weight:700;margin-bottom:8px">${t.parties}</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #E2E8F0;border-radius:12px;border-collapse:separate;overflow:hidden">
      <tr style="background:#142B4A">
        <td style="padding:9px 12px;color:#FFFFFF;font-size:11px;letter-spacing:1px;text-transform:uppercase">${t.party}</td>
        <td style="padding:9px 12px;color:#FFFFFF;font-size:11px;letter-spacing:1px;text-transform:uppercase">${t.role}</td>
        <td style="padding:9px 12px;color:#FFFFFF;font-size:11px;letter-spacing:1px;text-transform:uppercase;text-align:right">${t.share}</td>
      </tr>
      ${partyRows}
    </table>
  </td></tr>
  ${o.note ? `<tr><td style="padding:20px 32px 0">
    <div style="border-left:4px solid #12B8A6;background:#F0FDFA;border-radius:8px;padding:12px 16px">
      <div style="font-size:12px;color:#0D9488;font-weight:700;margin-bottom:4px">${t.noteFrom(owner)}</div>
      <div style="font-size:14px;color:#334155;line-height:1.5;white-space:pre-line">${esc(o.note)}</div>
    </div></td></tr>` : ""}
  <tr><td align="center" style="padding:28px 32px 6px">${button(o.confirmLink, t.wConfirm)}</td></tr>
  <tr><td align="center" style="padding:10px 32px 0">
    <a href="${esc(o.declineLink)}" style="color:#B91C1C;font-size:14px;font-weight:600;text-decoration:underline">${t.wDecline}</a>
  </td></tr>
  <tr><td style="padding:14px 32px 0;text-align:center">
    <p style="margin:0 0 8px;font-size:13px;line-height:1.6;color:#64748B">${t.wHow}</p>
    <p style="margin:0;font-size:13px;line-height:1.6;color:#64748B">${o.hasAccount ? t.hasAccount : t.noAccount}</p>
  </td></tr>
  <tr><td style="padding:18px 32px 26px">
    <p style="margin:0;font-size:12px;color:#94A3B8">${t.fallback}<br><a href="${esc(o.confirmLink)}" style="color:#0D9488;word-break:break-all">${esc(o.confirmLink)}</a></p>
  </td></tr>`;
  const html = brandShell({ lang: o.lang, subject, preheader: `${t.wTitle} – ${o.song}`, body, footer: t.wWhy(owner, esc(o.email)) });
  const text = [
    "SplitSure", "", t.wTitle, "", t.hi(o.witnessName), strip(t.wIntro(o.ownerName, o.song)), "",
    `${t.song}: ${o.song}`, `${t.reference}: ${o.reference}`, `${t.version}: ${o.version}`, `${t.wRole}: ${t.wRoleValue}`,
    "", `${t.parties}:`, ...o.parties.map((p) => `- ${p.name} · ${p.role} · ${pct(p.share)}`),
    ...(o.note ? ["", `${t.noteFrom(o.ownerName)}: ${o.note}`] : []),
    "", `${t.wConfirm}: ${o.confirmLink}`, `${t.wDecline}: ${o.declineLink}`, "", strip(t.wHow),
    "", "SplitSure – splitsure.app",
  ].join("\n");
  return { subject, html, text };
}

export function renderWitnessDoneEmail(o: {
  lang: Lang; name: string; song: string; reference: string; version: number; code: string;
  signedAt: Date; fullyAccepted: boolean; email: string; appUrl: string;
}) {
  const t = T[o.lang];
  const subject = t.wSubjectDone(o.song);
  const date = o.signedAt.toLocaleString(o.lang === "fr" ? "fr-FR" : "en-GB",
    { dateStyle: "long", timeStyle: "short", timeZone: "Africa/Douala" });
  const body = `
  <tr><td style="padding:32px 32px 8px">
    <h1 style="margin:0 0 14px;font-size:21px;line-height:1.3;color:#142B4A">${t.wTitleDone}</h1>
    <p style="margin:0 0 8px;font-size:15px;color:#334155">${t.hi(esc(o.name))}</p>
    <p style="margin:0;font-size:15px;line-height:1.6;color:#334155">${t.wIntroDone(esc(o.song))}</p>
  </td></tr>
  <tr><td align="center" style="padding:22px 32px 0">
    <div style="border:2px dashed #0D9488;background:#F0FDFA;border-radius:14px;padding:16px 20px">
      <div style="font-size:11px;letter-spacing:1.2px;text-transform:uppercase;color:#0D9488;font-weight:700">${t.wCode}</div>
      <div style="font-family:Consolas,Menlo,monospace;font-size:24px;font-weight:800;letter-spacing:2px;color:#142B4A;margin-top:6px">${esc(o.code)}</div>
    </div>
  </td></tr>
  <tr><td style="padding:20px 32px 0">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F5F8FA;border-radius:14px;padding:14px 20px">
      ${detailRow(t.song, esc(o.song))}
      ${detailRow(t.reference, esc(o.reference))}
      ${detailRow(t.version, String(o.version))}
      ${detailRow(t.signedOn, esc(date))}
      ${detailRow(t.status, o.fullyAccepted ? t.statusAccepted : t.statusPending)}
    </table>
  </td></tr>
  <tr><td align="center" style="padding:22px 32px 28px">${button(o.appUrl, t.open)}</td></tr>`;
  const html = brandShell({ lang: o.lang, subject, preheader: `${t.wCode}: ${o.code}`, body, footer: t.whySigned(esc(o.email)) });
  const text = [
    "SplitSure", "", t.wTitleDone, "", t.hi(o.name), strip(t.wIntroDone(o.song)), "",
    `${t.wCode}: ${o.code}`, `${t.song}: ${o.song}`, `${t.reference}: ${o.reference}`, `${t.version}: ${o.version}`,
    `${t.signedOn}: ${date}`, "", "SplitSure – splitsure.app",
  ].join("\n");
  return { subject, html, text };
}

// Two ways to send (same idea as the Fixit project):
//  • Gmail SMTP – GMAIL_USER + GMAIL_APP_PASSWORD (a Google "App password"); no domain to verify.
//  • Resend     – RESEND_API_KEY + EMAIL_FROM (verified domain).
const useGmail = () => !!(Deno.env.get("GMAIL_USER") && Deno.env.get("GMAIL_APP_PASSWORD"));
const useResend = () => !!(Deno.env.get("RESEND_API_KEY") && Deno.env.get("EMAIL_FROM"));

async function sendEmail(to: string, subject: string, html: string, text: string) {
  if (useGmail()) {
    const user = Deno.env.get("GMAIL_USER")!;
    const client = new SMTPClient({
      connection: {
        hostname: "smtp.gmail.com",
        port: 465,
        tls: true,
        auth: { username: user, password: Deno.env.get("GMAIL_APP_PASSWORD")! },
      },
    });
    try {
      await client.send({
        from: `SplitSure <${user}>`,
        replyTo: user,
        to,
        subject,
        content: text,
        html,
        headers: {
          "X-Mailer": "SplitSure/1.0",
          "List-Unsubscribe": `<mailto:${user}?subject=unsubscribe>`,
          "X-Entity-Ref-ID": crypto.randomUUID(),
        },
      });
      return { ok: true, id: null as string | null, error: null as string | null };
    } catch (e) {
      return { ok: false, id: null, error: e instanceof Error ? e.message : String(e) };
    } finally {
      try { await client.close(); } catch { /* already closed */ }
    }
  }
  if (!useResend()) return { ok: false, id: null, error: "EMAIL_NOT_CONFIGURED" };
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: Deno.env.get("EMAIL_FROM"),
      to: [to],
      subject,
      html,
      text,
      headers: {
        "X-Entity-Ref-ID": crypto.randomUUID(),
        "List-Unsubscribe": `<mailto:${(Deno.env.get("EMAIL_FROM") ?? "").replace(/.*<|>.*/g, "")}?subject=unsubscribe>`,
      },
    }),
  });
  const data = await res.json().catch(() => ({}));
  return { ok: res.ok, id: data?.id ?? null, error: res.ok ? null : (data?.message ?? `HTTP ${res.status}`) };
}

// ── Approval tokens ───────────────────────────────────────────────────────
const b64url = (b: Uint8Array) => btoa(String.fromCharCode(...b)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const newToken = () => b64url(crypto.getRandomValues(new Uint8Array(32)));
async function sha256(s: string) {
  const d = new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)));
  return Array.from(d, (x) => x.toString(16).padStart(2, "0")).join("");
}
const appUrl = () => (Deno.env.get("APP_URL") ?? "").replace(/\/+$/, "");

async function langForSplit(s: any, ownerId: string): Promise<Lang> {
  const ids = [s.user_id, ownerId].filter(Boolean);
  const { data } = await admin.from("profiles").select("id, preferred_language").in("id", ids);
  const pick = (id: string | null) => (data ?? []).find((p: any) => p.id === id)?.preferred_language;
  return (pick(s.user_id) ?? pick(ownerId)) === "fr" ? "fr" : "en";
}

/** Looks up an approval token; returns the token row, its line and agreement. */
async function loadToken(token: unknown) {
  if (typeof token !== "string" || token.length < 20 || token.length > 100) return null;
  const { data: t } = await admin.from("agreement_approval_tokens").select("*").eq("token_hash", await sha256(token)).maybeSingle();
  if (!t) return null;
  const { data: s } = await admin.from("agreement_splits").select("*").eq("id", t.split_id).maybeSingle();
  if (!s) return null;
  const { data: a } = await admin.from("agreements").select("*").eq("id", s.agreement_id).maybeSingle();
  if (!a) return null;
  return { t, s, a };
}

/** Looks up a witness token; returns the token row and its agreement. */
async function loadWitnessToken(token: unknown) {
  if (typeof token !== "string" || token.length < 20 || token.length > 100) return null;
  const { data: t } = await admin.from("agreement_witness_tokens").select("*").eq("token_hash", await sha256(token)).maybeSingle();
  if (!t) return null;
  const { data: a } = await admin.from("agreements").select("*").eq("id", t.agreement_id).maybeSingle();
  if (!a) return null;
  return { t, a };
}

async function witnessLang(a: any): Promise<Lang> {
  const ids = [a.witness_user_id, a.user_id].filter(Boolean);
  const { data } = await admin.from("profiles").select("id, preferred_language").in("id", ids);
  const pick = (id: string | null) => (data ?? []).find((p: any) => p.id === id)?.preferred_language;
  return (pick(a.witness_user_id) ?? pick(a.user_id)) === "fr" ? "fr" : "en";
}

async function witnessInfo(r: { t: any; a: any }) {
  const { t, a } = r;
  const { data: splits } = await admin.from("agreement_splits")
    .select("id, collaborator_name, role, split_percentage, response").eq("agreement_id", a.id).order("created_at");
  const { data: owner } = await admin.from("profiles").select("first_name, last_name").eq("id", a.user_id).maybeSingle();
  const answered = !!a.witness_response && a.witness_invited_version === t.version && a.version === t.version;
  let state = "open";
  if (answered) state = a.witness_response === "confirmed" ? "signed" : "declined";
  else if (a.version !== t.version) state = "newer_version";
  else if (t.used_at) state = "used";
  else if (new Date(t.expires_at) < new Date()) state = "expired";
  else if (!["pending", "changes_requested"].includes(a.status)) state = "closed";
  return json({
    kind: "witness",
    state,
    lang: await witnessLang(a),
    song: a.song_title,
    reference: a.reference ?? String(a.id).slice(0, 8).toUpperCase(),
    version: a.version,
    agreement_status: a.status,
    owner_name: nameOf(owner) || T.en.someone,
    recipient: { name: a.witness_name ?? "", role: a.witness_role ?? "witness", share: 0 },
    signature_code: answered && a.witness_response === "confirmed" ? a.witness_signature_code : null,
    signed_at: answered ? a.witness_responded_at : null,
    parties: (splits ?? []).map((p: any) => ({
      name: p.collaborator_name, role: p.role, share: Number(p.split_percentage),
      signed: p.response === "accepted", is_recipient: false,
    })),
  });
}

async function witnessRespond(r: { t: any; a: any }, token: string, response: unknown) {
  const resp = response === "declined" ? "declined" : "confirmed";
  const { data, error } = await admin.rpc("respond_witness_via_token", { p_token_hash: await sha256(token), p_response: resp });
  if (error) {
    const code = ["LINK_USED", "LINK_EXPIRED", "NEWER_VERSION", "INVALID_LINK"].find((c) => error.message.includes(c));
    return json({ error: code ?? "NOT_OPEN", message: error.message }, 409);
  }
  const res = data as { status: string; signature_code: string | null; response: string; already: boolean };
  if (!res.already && res.response === "confirmed" && res.signature_code && r.a.witness_email) {
    const mail = renderWitnessDoneEmail({
      lang: await witnessLang(r.a), name: r.a.witness_name ?? "", song: r.a.song_title,
      reference: r.a.reference ?? String(r.a.id).slice(0, 8).toUpperCase(), version: r.a.version,
      code: res.signature_code, signedAt: new Date(), fullyAccepted: res.status === "accepted",
      email: r.a.witness_email, appUrl: appUrl() || "https://splitsure.vercel.app",
    });
    await sendEmail(r.a.witness_email, mail.subject, mail.html, mail.text).catch(() => null);
  }
  return json({ kind: "witness", status: res.status, response: res.response, signature_code: res.signature_code, already: res.already });
}

async function approvalInfo(token: unknown) {
  const r = await loadToken(token);
  if (!r) {
    const w = await loadWitnessToken(token);
    return w ? await witnessInfo(w) : json({ error: "INVALID_LINK" }, 404);
  }
  const { t, s, a } = r;
  const { data: splits } = await admin.from("agreement_splits")
    .select("id, collaborator_name, role, split_percentage, response, signature_code").eq("agreement_id", a.id).order("created_at");
  const { data: owner } = await admin.from("profiles").select("first_name, last_name").eq("id", a.user_id).maybeSingle();
  const signedThisVersion = s.response === "accepted" && !!s.signature_code && a.version === t.version;
  let state = "open";
  if (signedThisVersion) state = "signed";
  else if (a.version !== t.version) state = "newer_version";
  else if (t.used_at) state = "used";
  else if (new Date(t.expires_at) < new Date()) state = "expired";
  else if (!["pending", "changes_requested"].includes(a.status)) state = "closed";
  return json({
    state,
    lang: await langForSplit(s, a.user_id),
    song: a.song_title,
    reference: a.reference ?? String(a.id).slice(0, 8).toUpperCase(),
    version: a.version,
    agreement_status: a.status,
    owner_name: nameOf(owner) || T.en.someone,
    recipient: { name: s.collaborator_name, role: s.role, share: Number(s.split_percentage) },
    // Same link as the e-mail's "Review details" button (sign in → request changes / decline).
    invite_token: s.invite_token,
    signature_code: signedThisVersion ? s.signature_code : null,
    signed_at: signedThisVersion ? s.accepted_at : null,
    parties: (splits ?? []).map((p: any) => ({
      name: p.collaborator_name, role: p.role, share: Number(p.split_percentage),
      signed: p.response === "accepted", is_recipient: p.id === s.id,
    })),
  });
}

async function approve(token: unknown, response?: unknown) {
  const r = await loadToken(token);
  if (!r) {
    const w = await loadWitnessToken(token);
    return w ? await witnessRespond(w, token as string, response) : json({ error: "INVALID_LINK" }, 404);
  }
  const hash = await sha256(token as string);
  const { data, error } = await admin.rpc("respond_via_email_token", { p_token_hash: hash, p_response: "accepted" });
  if (error) {
    const code = ["LINK_USED", "LINK_EXPIRED", "NEWER_VERSION", "INVALID_LINK"].find((c) => error.message.includes(c));
    return json({ error: code ?? "NOT_OPEN", message: error.message }, 409);
  }
  const res = data as { status: string; signature_code: string; already: boolean };
  if (!res.already && r.s.collaborator_email) {
    // Confirmation with the signature code (best effort; the signature is already recorded).
    const { data: s2 } = await admin.from("agreement_splits").select("accepted_at").eq("id", r.s.id).maybeSingle();
    const mail = renderSignedEmail({
      lang: await langForSplit(r.s, r.a.user_id), name: r.s.collaborator_name, song: r.a.song_title,
      reference: r.a.reference ?? String(r.a.id).slice(0, 8).toUpperCase(), version: r.a.version,
      code: res.signature_code, signedAt: new Date(s2?.accepted_at ?? Date.now()),
      fullyAccepted: res.status === "accepted", email: r.s.collaborator_email, appUrl: appUrl() || "https://splitsure.vercel.app",
    });
    await sendEmail(r.s.collaborator_email, mail.subject, mail.html, mail.text).catch(() => null);
  }
  return json({ status: res.status, signature_code: res.signature_code, already: res.already });
}

// ── Sending invitations ───────────────────────────────────────────────────
async function sendInvitations(req: Request, body: any) {
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data: { user } } = await admin.auth.getUser(token);
  if (!user) return json({ error: "UNAUTHORIZED" }, 401);
  const agreementId = body.agreement_id;
  if (typeof agreementId !== "string") return json({ error: "MISSING_AGREEMENT" }, 400);

  const missing = [
    ...(useGmail() || useResend() ? [] : ["GMAIL_USER + GMAIL_APP_PASSWORD (or RESEND_API_KEY + EMAIL_FROM)"]),
    ...(appUrl() ? [] : ["APP_URL"]),
  ];
  if (missing.length) return json({ configured: false, missing, sent: 0, skipped: 0, failed: 0 });

  const { data: a } = await admin.from("agreements").select("*").eq("id", agreementId).maybeSingle();
  if (!a || a.user_id !== user.id) return json({ error: "NOT_ALLOWED" }, 403);
  // { witness_only: true }: only e-mail the witness (asked later with invite_witness()).
  const witnessOnly = body.witness_only === true;
  const open = witnessOnly ? ["pending", "changes_requested"].includes(a.status) : a.status === "pending";
  if (!open) return json({ error: "NOT_SENT_FOR_REVIEW" }, 409);

  const { data: splits } = await admin.from("agreement_splits").select("*").eq("agreement_id", agreementId).order("created_at");
  const { data: owner } = await admin.from("profiles").select("first_name, last_name, email, preferred_language")
    .eq("id", user.id).maybeSingle();
  const ownerName = nameOf(owner) || T.en.someone;
  const ownerEmail = (owner?.email ?? user.email ?? "").toLowerCase();
  const ownerLang: Lang = owner?.preferred_language === "fr" ? "fr" : "en";

  const userIds = (splits ?? []).map((s: any) => s.user_id).filter(Boolean);
  const { data: profiles } = userIds.length
    ? await admin.from("profiles").select("id, preferred_language").in("id", userIds)
    : { data: [] as any[] };
  const langOf = (uid: string | null): Lang => {
    const p = (profiles ?? []).find((x: any) => x.id === uid);
    return p ? (p.preferred_language === "fr" ? "fr" : "en") : ownerLang;
  };

  const { data: already } = await admin.from("agreement_email_log").select("split_id")
    .eq("agreement_id", agreementId).eq("version", a.version).eq("status", "sent");
  const done = new Set((already ?? []).map((r: any) => r.split_id));
  const base = appUrl();
  const reference = a.reference ?? String(a.id).slice(0, 8).toUpperCase();
  const note = typeof body.note === "string" && body.note.trim() ? body.note.trim().slice(0, 1000) : null;

  let sent = 0, skipped = 0, failed = 0;
  for (const s of witnessOnly ? [] : splits ?? []) {
    const email = (s.collaborator_email ?? "").trim().toLowerCase();
    if (!email || s.user_id === user.id || email === ownerEmail || done.has(s.id)) { skipped++; continue; }

    // One-time approval link for this line and version (older links stop working).
    const approvalToken = newToken();
    await admin.from("agreement_approval_tokens").delete().eq("split_id", s.id).is("used_at", null);
    const { error: tokErr } = await admin.from("agreement_approval_tokens").insert({
      token_hash: await sha256(approvalToken), split_id: s.id, version: a.version, email,
    });
    if (tokErr) { failed++; continue; }

    const { subject, html, text } = renderEmail({
      lang: langOf(s.user_id), isUpdate: a.version > 1, recipientName: s.collaborator_name, ownerName, song: a.song_title,
      reference, version: a.version, role: s.role, share: Number(s.split_percentage),
      parties: (splits ?? []).map((p: any) => ({
        name: p.collaborator_name, role: p.role, share: Number(p.split_percentage), isRecipient: p.id === s.id,
      })),
      note, approveLink: `${base}/approve/${approvalToken}`, reviewLink: `${base}/invite/${s.invite_token}`,
      email, hasAccount: !!s.user_id,
    });
    const r = await sendEmail(email, subject, html, text);
    await admin.from("agreement_email_log").upsert({
      agreement_id: agreementId, split_id: s.id, version: a.version, email,
      status: r.ok ? "sent" : "failed", provider_id: r.id, error: r.error,
    }, { onConflict: "split_id,version" });
    if (r.ok) sent++; else failed++;
  }

  // The witness gets their own "Confirm as witness / Decline" e-mail (with or without an account).
  const witnessEmail = (a.witness_email ?? "").trim().toLowerCase();
  let witness = "none";
  if (witnessEmail && a.witness_invited_version === a.version) {
    if (witnessEmail === ownerEmail || a.witness_emailed_version === a.version) {
      witness = "skipped";
    } else {
      const wToken = newToken();
      await admin.from("agreement_witness_tokens").delete().eq("agreement_id", agreementId).is("used_at", null);
      const { error: wErr } = await admin.from("agreement_witness_tokens").insert({
        token_hash: await sha256(wToken), agreement_id: agreementId, version: a.version, email: witnessEmail,
      });
      if (wErr) {
        witness = "failed";
      } else {
        const link = `${base}/approve/${wToken}`;
        const mail = renderWitnessEmail({
          lang: a.witness_user_id ? langOf(a.witness_user_id) : ownerLang, isUpdate: a.version > 1,
          witnessName: a.witness_name ?? "", ownerName, song: a.song_title, reference, version: a.version,
          parties: (splits ?? []).map((p: any) => ({
            name: p.collaborator_name, role: p.role, share: Number(p.split_percentage), isRecipient: false,
          })),
          note, confirmLink: link, declineLink: `${link}?decline=1`, email: witnessEmail, hasAccount: !!a.witness_user_id,
        });
        const r = await sendEmail(witnessEmail, mail.subject, mail.html, mail.text);
        if (r.ok) {
          await admin.from("agreements").update({ witness_emailed_version: a.version }).eq("id", agreementId);
          witness = "sent";
          sent++;
        } else {
          witness = "failed";
          failed++;
        }
      }
    }
  }
  return json({ configured: true, sent, skipped, failed, witness });
}

// ── Sign-up e-mail verification (6-digit code) ───────────────────────────
//   POST { action: "verify_send" }          → { sent: true } | { verified: true }
//   POST { action: "verify_check", code }   → { verified: true } | { error }
// Both need the user's session. Only a hash of the code is stored (30 min, 5 tries).
const VT = {
  en: {
    subject: (c: string) => `Your SplitSure code: ${c}`,
    title: "Confirm your e-mail address",
    intro: (n: string) => `${n ? `Hi ${esc(n)}, w` : "W"}elcome to SplitSure! Enter this code in the app to confirm your e-mail address and finish creating your account.`,
    label: "Your verification code",
    expiry: "The code expires in 30 minutes.",
    ignore: "If you didn't create a SplitSure account, you can ignore this e-mail.",
    footer: (e: string) => `Sent to ${e} because it was used to create a SplitSure account.`,
  },
  fr: {
    subject: (c: string) => `Votre code SplitSure : ${c}`,
    title: "Confirmez votre adresse e-mail",
    intro: (n: string) => `${n ? `Bonjour ${esc(n)}, b` : "B"}ienvenue sur SplitSure ! Saisissez ce code dans l'application pour confirmer votre adresse e-mail et terminer la création de votre compte.`,
    label: "Votre code de vérification",
    expiry: "Le code expire dans 30 minutes.",
    ignore: "Si vous n'avez pas créé de compte SplitSure, ignorez cet e-mail.",
    footer: (e: string) => `Envoyé à ${e} car cette adresse a servi à créer un compte SplitSure.`,
  },
};

async function sessionUser(req: Request) {
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return null;
  const { data: { user } } = await admin.auth.getUser(token);
  return user ?? null;
}

async function verifySend(req: Request) {
  const user = await sessionUser(req);
  if (!user?.email) return json({ error: "UNAUTHORIZED" }, 401);
  const { data: profile } = await admin.from("profiles")
    .select("first_name, preferred_language, email_verified_at").eq("id", user.id).maybeSingle();
  if (profile?.email_verified_at) return json({ verified: true });
  // Google already verified the address.
  if ((user.identities ?? []).some((i: any) => i.provider === "google")) {
    await admin.rpc("mark_email_verified", { p_user: user.id });
    return json({ verified: true });
  }
  if (!useGmail() && !useResend()) return json({ error: "EMAIL_NOT_CONFIGURED" }, 503);
  const { data: prev } = await admin.from("email_verification_codes").select("sent_at").eq("user_id", user.id).maybeSingle();
  if (prev && Date.now() - new Date(prev.sent_at).getTime() < 45_000) return json({ error: "TOO_SOON" }, 429);

  const code = String(crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000).padStart(6, "0");
  const { error: upErr } = await admin.from("email_verification_codes").upsert({
    user_id: user.id, code_hash: await sha256(`${user.id}:${code}`),
    expires_at: new Date(Date.now() + 30 * 60 * 1000).toISOString(), attempts: 0, sent_at: new Date().toISOString(),
  });
  if (upErr) return json({ error: "STORE_FAILED", message: upErr.message }, 500);

  const lang: Lang = profile?.preferred_language === "fr" ? "fr" : "en";
  const t = VT[lang];
  const body = `
  <tr><td style="padding:32px 32px 8px">
    <h1 style="margin:0 0 14px;font-size:21px;line-height:1.3;color:#142B4A">${t.title}</h1>
    <p style="margin:0;font-size:15px;line-height:1.6;color:#334155">${t.intro(profile?.first_name ?? "")}</p>
  </td></tr>
  <tr><td align="center" style="padding:24px 32px 0">
    <div style="border:2px solid #0D9488;background:#F0FDFA;border-radius:16px;padding:18px 24px;display:inline-block">
      <div style="font-size:11px;letter-spacing:1.4px;text-transform:uppercase;color:#0D9488;font-weight:700">${t.label}</div>
      <div style="font-family:Consolas,Menlo,monospace;font-size:38px;font-weight:800;letter-spacing:10px;color:#142B4A;margin-top:8px">${code}</div>
    </div>
  </td></tr>
  <tr><td style="padding:20px 32px 28px;text-align:center">
    <p style="margin:0 0 6px;font-size:13px;color:#64748B">${t.expiry}</p>
    <p style="margin:0;font-size:12px;color:#94A3B8">${t.ignore}</p>
  </td></tr>`;
  const subject = t.subject(code);
  const html = brandShell({ lang, subject, preheader: `${t.label}: ${code}`, body, footer: t.footer(esc(user.email)) });
  const text = ["SplitSure", "", t.title, "", `${t.label}: ${code}`, t.expiry, "", t.ignore].join("\n");
  const r = await sendEmail(user.email, subject, html, text);
  if (!r.ok) return json({ error: "SEND_FAILED", message: r.error }, 502);
  return json({ sent: true });
}

async function verifyCheck(req: Request, code: unknown) {
  const user = await sessionUser(req);
  if (!user) return json({ error: "UNAUTHORIZED" }, 401);
  if (typeof code !== "string" || !/^\d{6}$/.test(code)) return json({ error: "INVALID_CODE" }, 400);
  const { data: row } = await admin.from("email_verification_codes").select("*").eq("user_id", user.id).maybeSingle();
  if (!row) return json({ error: "INVALID_CODE" }, 400);
  if (new Date(row.expires_at) < new Date()) return json({ error: "EXPIRED" }, 400);
  if (row.attempts >= 5) return json({ error: "TOO_MANY_ATTEMPTS" }, 429);
  if (row.code_hash !== await sha256(`${user.id}:${code}`)) {
    await admin.from("email_verification_codes").update({ attempts: row.attempts + 1 }).eq("user_id", user.id);
    return json({ error: "INVALID_CODE" }, 400);
  }
  const { error } = await admin.rpc("mark_email_verified", { p_user: user.id });
  if (error) return json({ error: "VERIFY_FAILED", message: error.message }, 500);
  await admin.from("email_verification_codes").delete().eq("user_id", user.id);
  return json({ verified: true });
}

// ── Password reset e-mail (code + link) ──────────────────────────────────
//   POST { action: "reset_send", email, lang? } → { sent: true }
// Supabase Auth creates the recovery code (admin generateLink, which sends nothing);
// we e-mail it through the project's own sender with the branded template. The app
// then checks it with verifyOTP(type: recovery) as before. Always answers { sent: true }
// so the endpoint never reveals whether an address has an account.
const RT = {
  en: {
    subject: "Reset your SplitSure password",
    title: "Reset your password",
    intro: (n: string) => `${n ? `Hi ${esc(n)}, w` : "W"}e received a request to reset the password of your SplitSure account. Enter this code in the app to choose a new password.`,
    label: "Your reset code",
    or: "Or open this link on the device where you use SplitSure:",
    button: "Reset my password",
    expiry: "The code and link expire in 1 hour and can be used once.",
    ignore: "Didn't ask for this? You can ignore this e-mail – your password stays the same.",
    footer: (e: string) => `Sent to ${e} because a password reset was requested on SplitSure.`,
  },
  fr: {
    subject: "Réinitialisez votre mot de passe SplitSure",
    title: "Réinitialisez votre mot de passe",
    intro: (n: string) => `${n ? `Bonjour ${esc(n)}, n` : "N"}ous avons reçu une demande de réinitialisation du mot de passe de votre compte SplitSure. Saisissez ce code dans l'application pour choisir un nouveau mot de passe.`,
    label: "Votre code de réinitialisation",
    or: "Ou ouvrez ce lien sur l'appareil où vous utilisez SplitSure :",
    button: "Réinitialiser mon mot de passe",
    expiry: "Le code et le lien expirent dans 1 heure et ne servent qu'une fois.",
    ignore: "Vous n'avez rien demandé ? Ignorez cet e-mail – votre mot de passe reste inchangé.",
    footer: (e: string) => `Envoyé à ${e} car une réinitialisation de mot de passe a été demandée sur SplitSure.`,
  },
};

async function resetSend(rawEmail: unknown, rawLang: unknown) {
  const email = typeof rawEmail === "string" ? rawEmail.trim().toLowerCase() : "";
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 254) return json({ error: "INVALID_EMAIL" }, 400);
  if (!useGmail() && !useResend()) return json({ error: "EMAIL_NOT_CONFIGURED" }, 503);

  // One e-mail per address per minute.
  const key = `reset:${email}`;
  const { data: prev } = await admin.from("auth_email_throttle").select("sent_at").eq("key", key).maybeSingle();
  if (prev && Date.now() - new Date(prev.sent_at).getTime() < 60_000) return json({ error: "TOO_SOON" }, 429);
  await admin.from("auth_email_throttle").upsert({ key, sent_at: new Date().toISOString() });

  const redirectTo = `${appUrl() || "https://splitsure.vercel.app"}/`;
  const { data, error } = await admin.auth.admin.generateLink({ type: "recovery", email, options: { redirectTo } });
  // Unknown address: answer the same way, but send nothing.
  if (error || !data?.properties?.email_otp) return json({ sent: true });

  const { data: profile } = await admin.from("profiles").select("first_name, preferred_language")
    .eq("id", data.user.id).maybeSingle();
  const lang: Lang = (profile?.preferred_language ?? rawLang) === "fr" ? "fr" : "en";
  const t = RT[lang];
  const code = data.properties.email_otp;
  const link = data.properties.action_link;
  const body = `
  <tr><td style="padding:32px 32px 8px">
    <h1 style="margin:0 0 14px;font-size:21px;line-height:1.3;color:#142B4A">${t.title}</h1>
    <p style="margin:0;font-size:15px;line-height:1.6;color:#334155">${t.intro(profile?.first_name ?? "")}</p>
  </td></tr>
  <tr><td align="center" style="padding:24px 32px 0">
    <div style="border:2px solid #0D9488;background:#F0FDFA;border-radius:16px;padding:18px 24px;display:inline-block">
      <div style="font-size:11px;letter-spacing:1.4px;text-transform:uppercase;color:#0D9488;font-weight:700">${t.label}</div>
      <div style="font-family:Consolas,Menlo,monospace;font-size:36px;font-weight:800;letter-spacing:8px;color:#142B4A;margin-top:8px">${esc(code)}</div>
    </div>
  </td></tr>
  <tr><td align="center" style="padding:22px 32px 0">
    <p style="margin:0 0 12px;font-size:13px;color:#64748B">${t.or}</p>
    ${button(link, t.button)}
  </td></tr>
  <tr><td style="padding:20px 32px 28px;text-align:center">
    <p style="margin:0 0 6px;font-size:13px;color:#64748B">${t.expiry}</p>
    <p style="margin:0;font-size:12px;color:#94A3B8">${t.ignore}</p>
  </td></tr>`;
  const html = brandShell({ lang, subject: t.subject, preheader: `${t.label}: ${code}`, body, footer: t.footer(esc(email)) });
  const text = ["SplitSure", "", t.title, "", strip(t.intro(profile?.first_name ?? "")), "", `${t.label}: ${code}`, "",
    `${t.button}: ${link}`, "", t.expiry, t.ignore].join("\n");
  const r = await sendEmail(email, t.subject, html, text);
  if (!r.ok) return json({ error: "SEND_FAILED", message: r.error }, 502);
  return json({ sent: true });
}

// ── E-mail health check ──────────────────────────────────────────────────
// Sends one short test message to the sender's own address (GMAIL_USER), so it
// never reaches anyone else; at most once every 10 minutes per function instance.
let lastHealth = 0;
async function emailHealth() {
  const provider = useGmail() ? "gmail" : useResend() ? "resend" : "none";
  if (provider === "none") return json({ ok: false, provider, error: "EMAIL_NOT_CONFIGURED" });
  if (Date.now() - lastHealth < 10 * 60 * 1000) return json({ ok: null, provider, error: "TRY_LATER" }, 429);
  lastHealth = Date.now();
  const to = provider === "gmail" ? Deno.env.get("GMAIL_USER")! : String(Deno.env.get("EMAIL_FROM")).replace(/.*<|>.*/g, "");
  const r = await sendEmail(to, "SplitSure e-mail check",
    brandShell({ lang: "en", subject: "SplitSure e-mail check", preheader: "E-mail sending works",
      body: `<tr><td style="padding:32px"><h1 style="margin:0 0 10px;font-size:20px;color:#142B4A">E-mail sending works</h1>
        <p style="margin:0;font-size:14px;color:#334155">Agreement invitations, witness requests and signature confirmations can now be delivered.</p></td></tr>`,
      footer: "Automatic test message sent to the SplitSure sender address." }),
    "SplitSure e-mail sending works.");
  return json({ ok: r.ok, provider, error: r.error });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    const body = await req.json().catch(() => ({}));
    if (body.action === "approval_info") return await approvalInfo(body.token);
    if (body.action === "approve") return await approve(body.token, body.response);
    if (body.action === "email_health") return await emailHealth();
    if (body.action === "verify_send") return await verifySend(req);
    if (body.action === "verify_check") return await verifyCheck(req, body.code);
    if (body.action === "reset_send") return await resetSend(body.email, body.lang);
    return await sendInvitations(req, body);
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
