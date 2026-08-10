// supabase/functions/embed-band/index.ts
// Ekte bilde-embedding (CLIP via Jina). For lagrede bilder lar vi Jina HENTE
// bildet selv via en signert URL (robust for private buckets, format og storrelse);
// bare live-skann sendes som base64.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-admin-key",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const BAND_BUCKET = "band-samples";

const storageAdmin = createClient(SUPABASE_URL, SERVICE_ROLE);

let lastJinaError = "";
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

function bufToB64(buf: ArrayBuffer): string {
  const bytes = new Uint8Array(buf);
  let bin = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    bin += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(bin);
}

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status, headers: { ...cors, "Content-Type": "application/json" },
  });
}

function publicUrl(path: string): string {
  return `${SUPABASE_URL}/storage/v1/object/public/${BAND_BUCKET}/${path}`;
}

async function callerIsAdmin(req: Request): Promise<boolean> {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return false;
    const caller = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data, error } = await caller.rpc("is_admin");
    if (error) return false;
    return data === true;
  } catch {
    return false;
  }
}

// Hvis URL-en peker til Supabase-lagring: returner en signert URL (funker for
// private buckets). Ellers returner URL-en uendret.
async function signedIfStorage(url: string): Promise<string> {
  const marker = "/storage/v1/object/";
  const idx = url.indexOf(marker);
  if (idx < 0 || !url.includes(".supabase.co")) return url;
  let rest = url.slice(idx + marker.length);
  if (rest.startsWith("public/")) rest = rest.slice(7);
  else if (rest.startsWith("sign/")) rest = rest.slice(5);
  const q = rest.indexOf("?");
  if (q >= 0) rest = rest.slice(0, q);
  const slash = rest.indexOf("/");
  if (slash <= 0) return url;
  const bucket = rest.slice(0, slash);
  const path = decodeURIComponent(rest.slice(slash + 1));
  const { data } = await storageAdmin.storage.from(bucket).createSignedUrl(path, 600);
  return data?.signedUrl ?? url;
}

async function toBase64FromUrl(url: string): Promise<string | null> {
  try {
    const marker = "/storage/v1/object/";
    const idx = url.indexOf(marker);
    if (idx >= 0 && url.includes(".supabase.co")) {
      let rest = url.slice(idx + marker.length);
      if (rest.startsWith("public/")) rest = rest.slice(7);
      else if (rest.startsWith("sign/")) rest = rest.slice(5);
      const q = rest.indexOf("?");
      if (q >= 0) rest = rest.slice(0, q);
      const slash = rest.indexOf("/");
      if (slash > 0) {
        const bucket = rest.slice(0, slash);
        const path = decodeURIComponent(rest.slice(slash + 1));
        const { data, error } = await storageAdmin.storage.from(bucket).download(path);
        if (error || !data) return null;
        return bufToB64(await data.arrayBuffer());
      }
    }
    const r = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
        "Accept": "image/avif,image/webp,image/png,image/jpeg,*/*",
      },
    });
    if (!r.ok) return null;
    return bufToB64(await r.arrayBuffer());
  } catch {
    return null;
  }
}

async function jinaEmbed(item: Record<string, string>, jinaKey: string): Promise<number[] | null> {
  // Prøv opptil 2 ganger; ved 429/503 (rate-limit) venter vi kort og prøver igjen.
  for (let attempt = 0; attempt < 2; attempt++) {
    const r = await fetch("https://api.jina.ai/v1/embeddings", {
      method: "POST",
      headers: { "Authorization": `Bearer ${jinaKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "jina-clip-v2",
        dimensions: 512,
        normalized: true,
        embedding_type: "float",
        input: [item],
      }),
    });
    if (r.ok) {
      const j = await r.json();
      const v = j?.data?.[0]?.embedding;
      return (Array.isArray(v) && v.length === 512) ? v as number[] : null;
    }
    lastJinaError = r.status + ": " + (await r.text()).slice(0, 200);
    if (r.status === 429 || r.status === 503) {
      await sleep(1000);   // rate-limit → kort pause, prøv igjen
      continue;
    }
    console.error("Jina " + lastJinaError);
    return null;   // annen feil (kvote/format) → gi opp
  }
  console.error("Jina rate-limit ga opp: " + lastJinaError);
  return null;
}

// Embed et lagret bilde: la Jina hente en signert URL. Faller tilbake til
// nedlasting + base64 hvis URL-metoden ikke gir vektor.
async function embedStoredUrl(rawUrl: string, jinaKey: string): Promise<number[] | null> {
  const signed = await signedIfStorage(rawUrl);
  const viaUrl = await jinaEmbed({ image: signed }, jinaKey);
  if (viaUrl) return viaUrl;
  const b64 = await toBase64FromUrl(rawUrl);
  if (!b64) return null;
  return await embedB64(b64, jinaKey);
}

// Embed fra base64 (live-skann). Prover ulike input-former.
async function embedB64(base64: string, jinaKey: string): Promise<number[] | null> {
  for (const item of [{ image: `data:image/jpeg;base64,${base64}` }, { image: base64 }, { bytes: base64 }]) {
    const v = await jinaEmbed(item, jinaKey);
    if (v) return v;
  }
  return null;
}

function vecLiteral(v: number[]): string {
  return "[" + v.join(",") + "]";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const jinaKey = Deno.env.get("JINA_API_KEY");
    const body = await req.json().catch(() => ({}));
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE);

    // C) BACKFILL
    if (body.backfill === true) {
      const viaServiceKey = req.headers.get("x-admin-key") === SERVICE_ROLE;
      const ok = viaServiceKey ? true : await callerIsAdmin(req);
      if (!ok) return json({ error: "unauthorized" }, 401);
      if (!jinaKey) return json({ error: "JINA_API_KEY er ikke satt som secret" }, 500);
      // Bevisst liten batch per kall, så vi aldri treffer tidsgrensen (retry tar tid).
      const limit = Math.min(Number(body.limit ?? 8), 8);
      const { data: rows } = await admin
        .from("cigar_image_samples")
        .select("id, image_url, storage_path")
        .is("image_embedding", null)
        .limit(limit);
      lastJinaError = "";
      let done = 0, failed = 0;
      for (const row of rows ?? []) {
        try {
          const url = row.image_url ?? (row.storage_path ? publicUrl(row.storage_path) : null);
          if (!url) { failed++; continue; }
          const vec = await embedStoredUrl(url, jinaKey);
          if (!vec) { failed++; continue; }
          await admin.from("cigar_image_samples")
            .update({ image_embedding: vecLiteral(vec) }).eq("id", row.id);
          done++;
          await sleep(250);   // liten pause mellom kall
        } catch (e) {
          failed++;
          console.error("backfill-rad feilet", row.id, e);
        }
      }
      const { count: remaining } = await admin
        .from("cigar_image_samples")
        .select("id", { count: "exact", head: true })
        .is("image_embedding", null);
      return json({ done, failed, remaining, lastError: lastJinaError || null });
    }

    // D) ADMIN LEGG TIL (base64 eller URL)
    if (body.addSample === true) {
      if (!(await callerIsAdmin(req))) return json({ error: "unauthorized" }, 401);
      if (!jinaKey) return json({ error: "JINA_API_KEY er ikke satt som secret" }, 500);
      const cigarId = body.cigar_id;
      let b64: string | null = body.image ?? null;
      if (!b64 && body.image_url) {
        b64 = await toBase64FromUrl(String(body.image_url));
        if (!b64) return json({ error: "kunne ikke hente bildet fra URL-en" }, 400);
      }
      if (!cigarId || !b64) return json({ error: "mangler cigar_id eller image/image_url" }, 400);
      const bytes = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
      const path = `admin/${cigarId}/${crypto.randomUUID()}.jpg`;
      const up = await admin.storage.from(BAND_BUCKET).upload(path, bytes, {
        contentType: "image/jpeg", upsert: false,
      });
      if (up.error) throw new Error("opplasting feilet: " + up.error.message);
      const url = publicUrl(path);
      const ins = await admin.from("cigar_image_samples").insert({
        cigar_id: cigarId, image_url: url, storage_path: path,
        source: "admin", reviewed_at: new Date().toISOString(),
      }).select("id").single();
      if (ins.error) throw new Error("kunne ikke lagre prove: " + ins.error.message);
      const vec = await embedStoredUrl(url, jinaKey);
      if (vec) {
        await admin.from("cigar_image_samples")
          .update({ image_embedding: vecLiteral(vec) }).eq("id", ins.data.id);
      }
      return json({ ok: true, id: ins.data.id, image_url: url, embedded: !!vec });
    }

    // Skaff bildet for live-skann / lagre
    let base64: string | null = body.image ?? null;

    if (!jinaKey) {
      if (body.storage_path && body.cigar_id) return json({ ok: true, skipped: true });
      return json({ signature: "", suggestions: [] });
    }

    let embedding: number[] | null = null;
    if (base64) embedding = await embedB64(base64, jinaKey);
    else if (body.storage_path) embedding = await embedStoredUrl(publicUrl(body.storage_path), jinaKey);
    if (!embedding) return json({ error: "kunne ikke lage embedding" }, 400);

    // B) LAGRE
    if (body.storage_path && body.cigar_id) {
      await admin.from("cigar_image_samples")
        .update({ image_embedding: vecLiteral(embedding) })
        .eq("storage_path", body.storage_path)
        .eq("cigar_id", body.cigar_id);
      return json({ ok: true });
    }

    // A) SPORRING
    const { data: suggestions } = await admin.rpc("match_cigar_by_image", {
      p_embedding: vecLiteral(embedding),
      p_match_count: 6,
      p_min_similarity: 0.72,
    });
    return json({ signature: "", suggestions: suggestions ?? [] });
  } catch (e) {
    console.error("embed-band feilet:", e);
    return json({ error: e instanceof Error ? e.message : "ukjent feil" }, 500);
  }
});
