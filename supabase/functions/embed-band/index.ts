// supabase/functions/embed-band/index.ts
// Ekte bilde-embedding (CLIP via Jina). Alle bilder nedskaleres til maks 512px
// FØR embedding — Jina prises etter bildestørrelse, så dette kutter token-kostnaden
// kraftig (typisk 10-20x) og unngår rate-limits. Vi henter bytene selv (service-role
// for private buckets), krymper med imagescript, og sender det lille bildet til Jina.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Image } from "https://deno.land/x/imagescript@1.2.15/mod.ts";

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

function u8ToB64(bytes: Uint8Array): string {
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

// Hent bildebytes. Supabase-lagring: service-role-nedlasting (funker for private
// buckets). Ellers vanlig fetch med nettleser-User-Agent.
async function fetchBytes(url: string): Promise<Uint8Array | null> {
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
        return new Uint8Array(await data.arrayBuffer());
      }
    }
    const r = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
        "Accept": "image/avif,image/webp,image/png,image/jpeg,*/*",
      },
    });
    if (!r.ok) return null;
    return new Uint8Array(await r.arrayBuffer());
  } catch {
    return null;
  }
}

// Nedskaler til maks 512px og returner base64 (JPEG). Faller tilbake til
// originalen hvis dekoding feiler.
async function downscaleToB64(bytes: Uint8Array, maxDim = 512): Promise<string> {
  try {
    const img = await Image.decode(bytes);
    const m = Math.max(img.width, img.height);
    if (m > maxDim) {
      img.resize(Math.round(img.width * maxDim / m), Math.round(img.height * maxDim / m));
    }
    const jpeg = await img.encodeJPEG(80);
    return u8ToB64(jpeg);
  } catch {
    return u8ToB64(bytes);
  }
}

async function jinaEmbed(item: Record<string, string>, jinaKey: string): Promise<number[] | null> {
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
      await sleep(1000);
      continue;
    }
    console.error("Jina " + lastJinaError);
    return null;
  }
  console.error("Jina rate-limit ga opp: " + lastJinaError);
  return null;
}

async function embedB64(base64: string, jinaKey: string): Promise<number[] | null> {
  for (const item of [{ image: `data:image/jpeg;base64,${base64}` }, { image: base64 }, { bytes: base64 }]) {
    const v = await jinaEmbed(item, jinaKey);
    if (v) return v;
  }
  return null;
}

// Embed fra rå bytes: nedskaler først, deretter Jina.
async function embedBytes(bytes: Uint8Array, jinaKey: string): Promise<number[] | null> {
  const b64 = await downscaleToB64(bytes);
  return await embedB64(b64, jinaKey);
}

async function embedStoredUrl(url: string, jinaKey: string): Promise<number[] | null> {
  const bytes = await fetchBytes(url);
  if (!bytes) return null;
  return await embedBytes(bytes, jinaKey);
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
      const limit = Math.min(Number(body.limit ?? 12), 20);
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
      let srcBytes: Uint8Array | null = null;
      if (body.image) srcBytes = Uint8Array.from(atob(String(body.image)), (c) => c.charCodeAt(0));
      else if (body.image_url) srcBytes = await fetchBytes(String(body.image_url));
      if (!cigarId || !srcBytes) return json({ error: "mangler cigar_id eller image/image_url" }, 400);
      const path = `admin/${cigarId}/${crypto.randomUUID()}.jpg`;
      const up = await admin.storage.from(BAND_BUCKET).upload(path, srcBytes, {
        contentType: "image/jpeg", upsert: false,
      });
      if (up.error) throw new Error("opplasting feilet: " + up.error.message);
      const url = publicUrl(path);
      const ins = await admin.from("cigar_image_samples").insert({
        cigar_id: cigarId, image_url: url, storage_path: path,
        source: "admin", reviewed_at: new Date().toISOString(),
      }).select("id").single();
      if (ins.error) throw new Error("kunne ikke lagre prove: " + ins.error.message);
      const vec = await embedBytes(srcBytes, jinaKey);
      if (vec) {
        await admin.from("cigar_image_samples")
          .update({ image_embedding: vecLiteral(vec) }).eq("id", ins.data.id);
      }
      return json({ ok: true, id: ins.data.id, image_url: url, embedded: !!vec, lastError: lastJinaError || null });
    }

    // Live-skann / lagre
    if (!jinaKey) {
      if (body.storage_path && body.cigar_id) return json({ ok: true, skipped: true });
      return json({ signature: "", suggestions: [] });
    }

    let embedding: number[] | null = null;
    if (body.image) {
      const bytes = Uint8Array.from(atob(String(body.image)), (c) => c.charCodeAt(0));
      embedding = await embedBytes(bytes, jinaKey);
    } else if (body.storage_path) {
      embedding = await embedStoredUrl(publicUrl(body.storage_path), jinaKey);
    }
    if (!embedding) return json({ error: "kunne ikke lage embedding", jina: lastJinaError || null }, 400);

    // B) LAGRE
    if (body.storage_path && body.cigar_id) {
      await admin.from("cigar_image_samples")
        .update({ image_embedding: vecLiteral(embedding) })
        .eq("storage_path", body.storage_path)
        .eq("cigar_id", body.cigar_id);
      return json({ ok: true });
    }

    // A) SPORRING
    const vec = vecLiteral(embedding);
    const { data: suggestions } = await admin.rpc("match_cigar_by_image", {
      p_embedding: vec,
      p_match_count: 6,
      p_min_similarity: 0.72,
    });
    // Konfidensvurdering: confident / brand / ambiguous / uncertain / none.
    // Appen bruker denne til aa avgjore om den tor si «X funnet» og hvor bred velger som vises.
    const { data: decision } = await admin.rpc("match_cigar_decision", {
      p_embedding: vec,
    });
    return json({ signature: "", suggestions: suggestions ?? [], decision: decision ?? null });
  } catch (e) {
    console.error("embed-band feilet:", e);
    return json({ error: e instanceof Error ? e.message : "ukjent feil" }, 500);
  }
});
