// supabase/functions/embed-band/index.ts
// Ekte bilde-embedding (CLIP via Jina) — bildet blir en vektor DIREKTE, uten
// tekst-mellomledd. Vektoren (512-d) lagres i cigar_image_samples.image_embedding.
//
// Bruksmåter (samme funksjon):
//   A) { image }                          -> { signature:"", suggestions }  (skanne-spørring)
//   B) { storage_path, cigar_id }         -> lagrer image_embedding på prøven (etter løst skann)
//   C) { backfill:true, limit }           -> fyller manglende image_embedding   (admin)
//   D) { addSample:true, image, cigar_id }-> last opp + embed nytt referansebilde (admin)
//
// Krever secret JINA_API_KEY. Uten nøkkel degraderer den pent (tomme forslag).

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

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status, headers: { ...cors, "Content-Type": "application/json" },
  });
}

function publicUrl(path: string): string {
  return `${SUPABASE_URL}/storage/v1/object/public/${BAND_BUCKET}/${path}`;
}

// Innlogget admin? Kallerens egen JWT (anon-klient med Authorization), så is_admin()
// ser auth.uid(). Brukes for backfill/addSample uten å eksponere service-nøkkelen.
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

async function toBase64FromUrl(url: string): Promise<string | null> {
  try {
    const r = await fetch(url);
    if (!r.ok) return null;
    const buf = new Uint8Array(await r.arrayBuffer());
    let bin = "";
    const chunk = 0x8000;
    for (let i = 0; i < buf.length; i += chunk) {
      bin += String.fromCharCode(...buf.subarray(i, i + chunk));
    }
    return btoa(bin);
  } catch {
    return null;
  }
}

// CLIP-embedding via Jina. Bildet går rett til en 512-d vektor. Prøver ulike
// input-former for base64, så vi er robuste mot API-format.
async function clipEmbed(base64: string, jinaKey: string): Promise<number[]> {
  const variants: Array<Record<string, string>> = [
    { image: `data:image/jpeg;base64,${base64}` },
    { image: base64 },
    { bytes: base64 },
  ];
  let lastErr = "ukjent";
  for (const item of variants) {
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
      if (Array.isArray(v) && v.length === 512) return v as number[];
      lastErr = "uventet svar: " + JSON.stringify(j).slice(0, 180);
      continue;
    }
    lastErr = `${r.status}: ${(await r.text()).slice(0, 180)}`;
    if (r.status === 401 || r.status === 403) break; // auth-feil: ingen vits å prøve flere former
  }
  throw new Error("Jina embed-feil " + lastErr);
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

    // C) BACKFILL — fyll manglende image_embedding. Service-role ELLER admin-JWT.
    if (body.backfill === true) {
      const viaServiceKey = req.headers.get("x-admin-key") === SERVICE_ROLE;
      const ok = viaServiceKey ? true : await callerIsAdmin(req);
      if (!ok) return json({ error: "unauthorized" }, 401);
      if (!jinaKey) return json({ error: "JINA_API_KEY er ikke satt som secret" }, 500);
      const limit = Math.min(Number(body.limit ?? 20), 50);
      const { data: rows } = await admin
        .from("cigar_image_samples")
        .select("id, image_url, storage_path")
        .is("image_embedding", null)
        .limit(limit);
      let done = 0, failed = 0;
      for (const row of rows ?? []) {
        try {
          const url = row.image_url ?? (row.storage_path ? publicUrl(row.storage_path) : null);
          if (!url) { failed++; continue; }
          const b64 = await toBase64FromUrl(url);
          if (!b64) { failed++; continue; }
          const vec = await clipEmbed(b64, jinaKey);
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
      return json({ done, failed, remaining });
    }

    // D) ADMIN LEGG TIL — last opp referansebilde, koble til sigar, embed straks.
    if (body.addSample === true) {
      if (!(await callerIsAdmin(req))) return json({ error: "unauthorized" }, 401);
      if (!jinaKey) return json({ error: "JINA_API_KEY er ikke satt som secret" }, 500);
      const cigarId = body.cigar_id;
      // Bildet kan komme som base64 (opplasting) ELLER som en URL (dratt/limt fra
      // nettet) — da henter serveren det og lagrer vår egen kopi.
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
      if (ins.error) throw new Error("kunne ikke lagre prøve: " + ins.error.message);
      const vec = await clipEmbed(b64, jinaKey);
      await admin.from("cigar_image_samples")
        .update({ image_embedding: vecLiteral(vec) }).eq("id", ins.data.id);
      return json({ ok: true, id: ins.data.id, image_url: url });
    }

    // Skaff bildet: enten direkte base64, eller hentet fra storage_path.
    let base64: string | null = body.image ?? null;
    if (!base64 && body.storage_path) base64 = await toBase64FromUrl(publicUrl(body.storage_path));
    if (!base64) return json({ error: "mangler image eller storage_path" }, 400);

    // Uten Jina-nøkkel: ingen visuell embedding ennå → degrader pent.
    if (!jinaKey) {
      if (body.storage_path && body.cigar_id) return json({ ok: true, skipped: true });
      return json({ signature: "", suggestions: [] });
    }

    const embedding = await clipEmbed(base64, jinaKey);

    // B) LAGRE — etter løst skann: fest image_embedding på prøven.
    if (body.storage_path && body.cigar_id) {
      await admin.from("cigar_image_samples")
        .update({ image_embedding: vecLiteral(embedding) })
        .eq("storage_path", body.storage_path)
        .eq("cigar_id", body.cigar_id);
      return json({ ok: true });
    }

    // A) SPØRRING — finn sigarer med lignende bånd (CLIP).
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
