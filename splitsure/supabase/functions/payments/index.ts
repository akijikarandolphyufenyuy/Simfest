// SplitSure – payments Edge Function (MeSomb mobile money: MTN MoMo / Orange Money)
//
// The ONLY place that talks to MeSomb. The app never sees the keys and never
// decides whether a payment succeeded: this function asks MeSomb, then calls
// public.complete_payment(), which applies the result exactly once.
//
//   POST { action: "initiate", type: "PRO_UPGRADE" | "AGREEMENT_GENERATION",
//          provider: "MTN" | "ORANGE", phone: "6XXXXXXXX", target_id?: uuid }
//        → { reference, status }
//   POST { action: "verify", reference } → { reference, status, type }
//
// Required secrets (Dashboard → Edge Functions → Secrets, or `supabase secrets set`):
//   MESOMB_APP_KEY (or MESOMB_APPLICATION_KEY), MESOMB_ACCESS_KEY, MESOMB_SECRET_KEY
// SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are provided automatically.

import { createClient } from "jsr:@supabase/supabase-js@2";

const MESOMB_HOST = "https://mesomb.hachther.com";
const MESOMB_VERSION = "v1.1";

// Either secret name works (MeSomb's dashboard calls it "Application key").
const mesombAppKey = () => Deno.env.get("MESOMB_APP_KEY") ?? Deno.env.get("MESOMB_APPLICATION_KEY");
const AGREEMENT_PRICE_FCFA = 50;
const PENDING_WINDOW_MS = 3 * 60 * 1000; // a payment request stays "in progress" this long

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});

// ── MeSomb request signing (port of the official pymesomb Signature.sign_request)
const enc = new TextEncoder();
const hex = (buf: ArrayBuffer) => [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
const sha1 = async (s: string) => hex(await crypto.subtle.digest("SHA-1", enc.encode(s)));
async function hmacSha1(key: string, msg: string) {
  const k = await crypto.subtle.importKey("raw", enc.encode(key), { name: "HMAC", hash: "SHA-1" }, false, ["sign"]);
  return hex(await crypto.subtle.sign("HMAC", k, enc.encode(msg)));
}
function nonce(len = 40) {
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  const r = crypto.getRandomValues(new Uint8Array(len));
  return [...r].map((b) => chars[b % chars.length]).join("");
}
// Python's urllib.parse.quote_plus
const quotePlus = (s: string) =>
  encodeURIComponent(s).replace(/[!'()*]/g, (c) => "%" + c.charCodeAt(0).toString(16).toUpperCase()).replace(/%20/g, "+");

async function mesomb(method: "GET" | "POST", endpoint: string, query: [string, string][], body?: unknown,
                      extraHeaders: Record<string, string> = {}) {
  const appKey = mesombAppKey();
  const accessKey = Deno.env.get("MESOMB_ACCESS_KEY");
  const secretKey = Deno.env.get("MESOMB_SECRET_KEY");
  if (!appKey || !accessKey || !secretKey) throw new Error("Payments are not configured (missing MeSomb secrets).");

  const path = `/api/${MESOMB_VERSION}/${endpoint}`;
  const qs = query.map(([k, v]) => `${quotePlus(k)}=${quotePlus(v)}`).join("&");
  const fullUrl = `${MESOMB_HOST}${path}${qs ? "?" + qs : ""}`;
  const parsed = new URL(fullUrl);
  const date = new Date();
  // SDK uses milliseconds: date.getTime()
  const timestamp = date.getTime();
  const n = nonce();
  const payload = body === undefined ? "{}" : JSON.stringify(body);

  // host header must be "protocol//host" (e.g. "https://mesomb.hachther.com")
  const hostHeader = `${parsed.protocol}//${parsed.host}`;
  // GET requests have no body, so content-type is excluded from signed headers
  const signed: Record<string, string> = method === "POST"
    ? { "content-type": "application/json", "host": hostHeader, "x-mesomb-date": String(timestamp), "x-mesomb-nonce": n }
    : { "host": hostHeader, "x-mesomb-date": String(timestamp), "x-mesomb-nonce": n };
  const keys = Object.keys(signed).sort();
  const canonicalHeaders = keys.map((k) => `${k}:${signed[k]}`).join("\n");
  const signedHeaders = keys.join(";");
  // canonical query: raw query string minus leading "?"
  const canonicalQS = parsed.search ? parsed.search.substring(1) : "";
  const canonicalRequest =
    `${method}\n${encodeURI(parsed.pathname)}\n${canonicalQS}\n${canonicalHeaders}\n${signedHeaders}\n${await sha1(payload)}`;
  // scope: year + month (0-indexed, no padding) + day (no padding) — matches SDK exactly
  const scope = `${date.getFullYear()}${date.getMonth()}${date.getDate()}/payment/mesomb_request`;
  const stringToSign = `HMAC-SHA1\n${timestamp}\n${scope}\n${await sha1(canonicalRequest)}`;
  const signature = await hmacSha1(secretKey, stringToSign);

  const res = await fetch(fullUrl, {
    method,
    headers: {
      "Content-Type": "application/json",
      "Accept-Language": "en",
      "x-mesomb-date": String(timestamp),
      "x-mesomb-nonce": n,
      "X-MeSomb-Application": appKey,
      "X-MeSomb-Source": "MeSombJS/v1.1.0",
      Authorization: `HMAC-SHA1 Credential=${accessKey}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,
      ...extraHeaders,
    },
    body: method === "POST" ? payload : undefined,
  });
  const text = await res.text();
  let data: any = null;
  try { data = JSON.parse(text); } catch { data = { detail: text }; }
  return { ok: res.ok, status: res.status, data };
}

// ── helpers
function normalizePhone(raw: string): string | null {
  let d = (raw ?? "").replace(/\D/g, "");
  if (d.startsWith("00237")) d = d.slice(5);
  else if (d.startsWith("237") && d.length === 12) d = d.slice(3);
  return /^6\d{8}$/.test(d) ? d : null;
}

function newReference(type: string) {
  const r = crypto.getRandomValues(new Uint8Array(6));
  return `SS-${type === "PRO_UPGRADE" ? "PRO" : "AGR"}-${Date.now().toString(36).toUpperCase()}-${hex(r.buffer).toUpperCase()}`;
}

async function isAgreementParty(agreementId: string, userId: string) {
  const { data: a } = await admin.from("agreements").select("id, user_id, status").eq("id", agreementId).maybeSingle();
  if (!a) return { ok: false, status: null };
  if (a.user_id === userId) return { ok: true, status: a.status };
  const { count } = await admin.from("agreement_splits").select("id", { count: "exact", head: true })
    .eq("agreement_id", agreementId).eq("user_id", userId);
  return { ok: (count ?? 0) > 0, status: a.status };
}

/** Ask MeSomb for the transaction status and apply it (idempotent). */
async function verify(reference: string, userId: string) {
  const { data: tx } = await admin.from("payment_transactions").select("*").eq("reference", reference).maybeSingle();
  if (!tx || tx.user_id !== userId) return json({ error: "NOT_FOUND" }, 404);
  if (tx.status !== "pending") return json({ reference, status: tx.status, type: tx.type });

  // Look the transaction up by our own reference (sent as X-MeSomb-TrxID), falling back to MeSomb's id.
  let r = await mesomb("GET", "payment/transactions/", [["ids", reference], ["source", "EXTERNAL"]]);
  let list = Array.isArray(r.data) ? r.data : [];
  if (!list.length && tx.provider_tx_id) {
    r = await mesomb("GET", "payment/transactions/", [["ids", tx.provider_tx_id], ["source", "MESOMB"]]);
    list = Array.isArray(r.data) ? r.data : [];
  }
  const m = list[0];
  const mStatus = String(m?.status ?? "").toUpperCase();

  if (mStatus === "SUCCESS") {
    const { data, error } = await admin.rpc("complete_payment", {
      p_reference: reference, p_success: true, p_provider_tx_id: String(m.pk ?? tx.provider_tx_id ?? ""),
      p_provider_status: mStatus, p_message: m.message ?? null, p_raw: m,
    });
    if (error) return json({ error: error.message }, 500);
    return json({ reference, status: "success", type: tx.type, applied: data });
  }
  if (mStatus === "FAILED" || mStatus === "FAIL" || mStatus === "CANCELED" || mStatus === "CANCELLED") {
    await admin.rpc("complete_payment", {
      p_reference: reference, p_success: false, p_provider_tx_id: m.pk ? String(m.pk) : null,
      p_provider_status: mStatus, p_message: m.message ?? null, p_raw: m,
    });
    return json({ reference, status: mStatus.startsWith("CANCEL") ? "cancelled" : "failed", type: tx.type });
  }
  return json({ reference, status: "pending", type: tx.type });
}

async function initiate(body: any, userId: string) {
  const type = body.type;
  const provider = body.provider;
  const phone = normalizePhone(body.phone);
  if (!["PRO_UPGRADE", "AGREEMENT_GENERATION"].includes(type)) return json({ error: "INVALID_TYPE" }, 400);
  if (!["MTN", "ORANGE"].includes(provider)) return json({ error: "INVALID_PROVIDER" }, 400);
  if (!phone) return json({ error: "INVALID_PHONE" }, 400);
  if (!mesombAppKey() || !Deno.env.get("MESOMB_ACCESS_KEY") || !Deno.env.get("MESOMB_SECRET_KEY")) {
    return json({ error: "PAYMENT_UNAVAILABLE" }, 503);
  }

  // The server decides the price.
  let amount: number;
  let targetId: string | null = null;
  if (type === "PRO_UPGRADE") {
    const { data: ent } = await admin.from("user_entitlements").select("plan_type, subscription_status, pro_expires_at")
      .eq("user_id", userId).maybeSingle();
    const active = ent?.plan_type === "pro" && ent.subscription_status === "active" &&
      (!ent.pro_expires_at || new Date(ent.pro_expires_at) > new Date());
    if (active) return json({ error: "ALREADY_PRO" }, 409);
    const { data: plan } = await admin.from("plans").select("price_fcfa").eq("id", "pro").maybeSingle();
    amount = plan?.price_fcfa ?? 100;
  } else {
    targetId = body.target_id;
    if (!targetId) return json({ error: "MISSING_TARGET" }, 400);
    const party = await isAgreementParty(targetId, userId);
    if (!party.ok) return json({ error: "NOT_ALLOWED" }, 403);
    // Paying unlocks the PDF preview right away; the final document still needs every party's acceptance.
    const { data: doc } = await admin.from("agreement_documents").select("agreement_id").eq("agreement_id", targetId).maybeSingle();
    if (doc) return json({ error: "ALREADY_UNLOCKED" }, 409);
    amount = AGREEMENT_PRICE_FCFA;
  }

  // Idempotency: a recent pending request for the same thing is resumed, not duplicated.
  let q = admin.from("payment_transactions").select("reference, created_at").eq("user_id", userId)
    .eq("type", type).eq("status", "pending").order("created_at", { ascending: false }).limit(1);
  q = targetId ? q.eq("target_id", targetId) : q.is("target_id", null);
  const { data: pending } = await q;
  if (pending?.length && Date.now() - new Date(pending[0].created_at).getTime() < PENDING_WINDOW_MS) {
    return json({ reference: pending[0].reference, status: "pending", resumed: true });
  }

  const reference = newReference(type);
  const { error: insErr } = await admin.from("payment_transactions").insert({
    reference, user_id: userId, type, amount_fcfa: amount, provider, phone, target_id: targetId, status: "pending",
  });
  if (insErr) return json({ error: insErr.message }, 500);

  let r: { ok: boolean; status: number; data: any };
  try {
    r = await mesomb("POST", "payment/collect/", [], {
      amount, service: provider, payer: phone, country: "CM", currency: "XAF",
      amount_currency: "XAF", fees: true, conversion: false,
    }, { "X-MeSomb-OperationMode": "asynchronous", "X-MeSomb-TrxID": reference });
  } catch (e) {
    // Never leave a request hanging: record it as failed (nothing was collected).
    await admin.rpc("complete_payment", {
      p_reference: reference, p_success: false, p_provider_tx_id: null, p_provider_status: "NOT_SENT",
      p_message: e instanceof Error ? e.message : String(e), p_raw: null,
    });
    return json({ error: "PAYMENT_UNAVAILABLE" }, 503);
  }

  const t = r.data?.transaction;
  const mStatus = String(t?.status ?? r.data?.status ?? "").toUpperCase();
  if (!r.ok || mStatus === "FAILED" || mStatus === "FAIL") {
    await admin.rpc("complete_payment", {
      p_reference: reference, p_success: false, p_provider_tx_id: t?.pk ? String(t.pk) : null,
      p_provider_status: mStatus || `HTTP_${r.status}`, p_message: r.data?.detail ?? r.data?.message ?? null,
      p_raw: r.data,
    });
    return json({ reference, status: "failed", message: r.data?.detail ?? r.data?.message ?? null });
  }
  await admin.from("payment_transactions").update({
    provider_tx_id: t?.pk ? String(t.pk) : null, provider_status: mStatus || "PENDING", raw: r.data,
    updated_at: new Date().toISOString(),
  }).eq("reference", reference);

  // In synchronous edge cases MeSomb may already report success: apply it through the same path.
  if (mStatus === "SUCCESS") return await verify(reference, userId);
  return json({ reference, status: "pending" });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    const body = await req.json().catch(() => ({}));

    // Health check is unauthenticated — read-only, no money moves.
    if (body.action === "health") {
      // Read-only check that the MeSomb keys and request signing work (no money moves).
      if (!mesombAppKey() || !Deno.env.get("MESOMB_ACCESS_KEY") || !Deno.env.get("MESOMB_SECRET_KEY")) {
        return json({ configured: false });
      }
      // Fetch application status — read-only, no money moves.
      const r = await mesomb("GET", "payment/status/", []);
      return json({
        configured: true,
        mesomb_ok: r.ok,
        mesomb_status: r.status,
        detail: r.ok ? null : (r.data?.detail ?? null),
      });
    }

    // All other actions require authentication.
    const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    const { data: { user } } = await admin.auth.getUser(token);
    if (!user) return json({ error: "UNAUTHORIZED" }, 401);
    if (body.action === "initiate") return await initiate(body, user.id);
    if (body.action === "verify" && typeof body.reference === "string") return await verify(body.reference, user.id);
    return json({ error: "INVALID_ACTION" }, 400);
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
