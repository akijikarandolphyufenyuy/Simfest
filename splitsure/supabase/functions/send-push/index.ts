// SplitSure – send-push Edge Function
//
// Triggered by a Supabase Database Webhook on INSERT into public.notifications.
// Looks up the recipient's FCM tokens and language, then sends a web push through
// the Firebase Cloud Messaging HTTP v1 API.
//
// Required secrets (supabase secrets set ...):
//   FIREBASE_SERVICE_ACCOUNT  – the full service-account JSON (Firebase Console →
//                               Project settings → Service accounts → Generate key)
//   APP_URL                   – public URL of the PWA, e.g. https://splitsure.app
//   WEBHOOK_SECRET            – any random string; also set as the webhook's
//                               "x-webhook-secret" HTTP header
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically.

import { createClient } from "jsr:@supabase/supabase-js@2";

type Lang = "en" | "fr";

const TEXT: Record<string, Record<Lang, (p: Record<string, string>) => [string, string]>> = {
  agreement_invited: {
    en: (p) => ["New collaboration agreement", `You've been invited to review “${p.song}”.`],
    fr: (p) => ["Nouvel accord de collaboration", `Vous êtes invité à examiner « ${p.song} ».`],
  },
  agreement_new_version: {
    en: (p) => ["Agreement updated", `Version ${p.version} of “${p.song}” is ready for review.`],
    fr: (p) => ["Accord mis à jour", `La version ${p.version} de « ${p.song} » est prête à être examinée.`],
  },
  agreement_accepted: {
    en: (p) => ["Agreement accepted", `${p.name} accepted “${p.song}”.`],
    fr: (p) => ["Accord accepté", `${p.name} a accepté « ${p.song} ».`],
  },
  agreement_changes_requested: {
    en: (p) => ["Changes requested", `${p.name} requested changes to “${p.song}”.`],
    fr: (p) => ["Modifications demandées", `${p.name} demande des modifications sur « ${p.song} ».`],
  },
  agreement_declined: {
    en: (p) => ["Agreement declined", `${p.name} declined “${p.song}”.`],
    fr: (p) => ["Accord refusé", `${p.name} a refusé « ${p.song} ».`],
  },
  agreement_fully_accepted: {
    en: (p) => ["Agreement finalised", `All parties accepted “${p.song}”.`],
    fr: (p) => ["Accord finalisé", `Toutes les parties ont accepté « ${p.song} ».`],
  },
  campaign_completed: {
    en: (p) => ["Campaign completed", `“${p.campaign}” is complete.`],
    fr: (p) => ["Campagne terminée", `« ${p.campaign} » est terminée.`],
  },
  subscription_expiring: {
    en: (p) => ["Subscription expiring soon", `Your plan expires on ${p.date}.`],
    fr: (p) => ["Abonnement bientôt expiré", `Votre abonnement expire le ${p.date}.`],
  },
  subscription_expired: {
    en: () => ["Subscription expired", "Renew to keep full access to SplitSure."],
    fr: () => ["Abonnement expiré", "Renouvelez pour conserver l'accès complet à SplitSure."],
  },
  opportunity_recommended: {
    en: (p) => ["New opportunity for you", `“${p.title}” matches your Music Passport.`],
    fr: (p) => ["Nouvelle opportunité pour vous", `« ${p.title} » correspond à votre Music Passport.`],
  },
  application_received: {
    en: (p) => ["New application", `${p.name} applied to “${p.title}”.`],
    fr: (p) => ["Nouvelle candidature", `${p.name} a postulé à « ${p.title} ».`],
  },
  application_under_review: {
    en: (p) => ["Application under review", `“${p.title}”`],
    fr: (p) => ["Candidature en cours d'examen", `« ${p.title} »`],
  },
  application_shortlisted: {
    en: (p) => ["You've been shortlisted!", `“${p.title}”`],
    fr: (p) => ["Vous êtes présélectionné(e) !", `« ${p.title} »`],
  },
  application_accepted: {
    en: (p) => ["Application accepted 🎉", `“${p.title}”`],
    fr: (p) => ["Candidature acceptée 🎉", `« ${p.title} »`],
  },
  application_rejected: {
    en: (p) => ["Application update", `Your application to “${p.title}” wasn't selected this time.`],
    fr: (p) => ["Mise à jour de candidature", `Votre candidature à « ${p.title} » n'a pas été retenue cette fois.`],
  },
  workspace_created: {
    en: (p) => ["DealFlow workspace ready", `Agree on roles and splits for “${p.title}”.`],
    fr: (p) => ["Espace DealFlow prêt", `Accordez-vous sur les rôles et les parts pour « ${p.title} ».`],
  },
  member_added: {
    en: (p) => ["You were added to a collaboration", `Agree on roles and splits for “${p.title}”.`],
    fr: (p) => ["Vous avez été ajouté(e) à une collaboration", `Accordez-vous sur les rôles et les parts pour « ${p.title} ».`],
  },
  terms_updated: {
    en: (p) => ["Terms updated", `New terms were proposed for “${p.title}”. Review and agree.`],
    fr: (p) => ["Termes mis à jour", `De nouveaux termes ont été proposés pour « ${p.title} ».`],
  },
  payment_success: {
    en: (p) => ["Payment successful", `${p.amount} FCFA received. Thank you!`],
    fr: (p) => ["Paiement réussi", `${p.amount} FCFA reçus. Merci !`],
  },
  payment_failed: {
    en: (p) => ["Payment failed", `Your ${p.amount} FCFA payment didn't go through. Nothing was charged.`],
    fr: (p) => ["Échec du paiement", `Votre paiement de ${p.amount} FCFA n'a pas abouti. Rien n'a été débité.`],
  },
  pro_activated: {
    en: () => ["Pro activated ⭐", "Unlimited posts, agreements and Reach are now unlocked."],
    fr: () => ["Pro activé ⭐", "Annonces, accords et Reach illimités sont désormais débloqués."],
  },
};

// ── Google OAuth access token from the service account (RS256 JWT) ──
async function accessToken(sa: { client_email: string; private_key: string }): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const enc = (o: unknown) =>
    btoa(JSON.stringify(o)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const unsigned = `${enc({ alg: "RS256", typ: "JWT" })}.${enc({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })}`;
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)));
  const jwt = `${unsigned}.${btoa(String.fromCharCode(...sig)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!json.access_token) throw new Error(`OAuth failed: ${JSON.stringify(json)}`);
  return json.access_token;
}

Deno.serve(async (req) => {
  if (req.headers.get("x-webhook-secret") !== Deno.env.get("WEBHOOK_SECRET")) {
    return new Response("unauthorized", { status: 401 });
  }
  const payload = await req.json();
  const n = payload.record;
  if (!n?.user_id) return new Response("ignored");

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const [{ data: tokens }, { data: profile }] = await Promise.all([
    db.from("fcm_tokens").select("token").eq("user_id", n.user_id),
    db.from("profiles").select("preferred_language").eq("id", n.user_id).maybeSingle(),
  ]);
  if (!tokens?.length) return new Response("no tokens");

  const lang: Lang = profile?.preferred_language === "fr" ? "fr" : "en";
  const params = Object.fromEntries(Object.entries(n.params ?? {}).map(([k, v]) => [k, String(v ?? "")]));
  const [title, body] = TEXT[n.kind]?.[lang](params) ?? [n.title, n.body ?? ""];

  const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
  const token = await accessToken(sa);
  const link = `${Deno.env.get("APP_URL") ?? ""}/home`;

  const results = await Promise.all(
    tokens.map(async ({ token: fcm }) => {
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
        method: "POST",
        headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
        body: JSON.stringify({
          message: {
            token: fcm,
            notification: { title, body },
            data: { kind: n.kind ?? "", related_id: n.related_id ?? "" },
            webpush: { fcm_options: { link }, notification: { icon: "/icons/Icon-192.png" } },
          },
        }),
      });
      // Drop tokens FCM reports as no longer valid.
      if (res.status === 404 || res.status === 410) await db.from("fcm_tokens").delete().eq("token", fcm);
      return res.status;
    }),
  );
  return new Response(JSON.stringify({ sent: results }), { headers: { "content-type": "application/json" } });
});
