// supabase/functions/embed-band/index.ts
// Lager et 512-d "visuelt fingeravtrykk" av et sigarbånd — gjenbruker OpenAI.
//
// GPT (gpt-5-mini) beskriver båndets UTSEENDE i en fast, verdi-basert form
// (ikke hvilket merke det er), og text-embedding-3-small (dimensions:512) gjør
// beskrivelsen om til en vektor som passer cigar_image_samples.embedding
// (vector(512)). OpenAI-nøkkelen ligger kun her, server-side.
//
// Tre bruksmåter (samme funksjon):
//   A) { image }                      -> { signature, suggestions }  (skanne-spørring)
//   B) { storage_path, cigar_id }     -> lagrer embedding på prøven   (etter en løst skanning)
//   C) { backfill:true, limit }       -> fyller manglende embeddings   (krever x-admin-key)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-admin-key",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BAND_BUCKET = "band-samples";

function publicUrl(path: string): string {
  return `${SUPABASE_URL}/storage/v1/object/public/${BAND_BUCKET}/${path}`;
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

// Beskriv KUN utseendet — faste verdier i fast rekkefølge, uten feltnavn, slik
// at to bilder av samme bånd gir like beskrivelser (og dermed nære vektorer).
async function describeBand(base64: string, ocr: string, key: string): Promise<string> {
  const prompt =
    `Du beskriver KUN det VISUELLE utseendet til et sigarbånd (IKKE hvilket merke det er).\n` +
    (ocr ? `OCR leste denne teksten på båndet: "${ocr}".\n` : "") +
    `Returner ÉN linje med disse VERDIENE i denne rekkefølgen, adskilt med "; ", UTEN feltnavn:\n` +
    `1) 2-4 dominant colors\n` +
    `2) metallic finish (gold/silver/copper/none)\n` +
    `3) band shape and layout\n` +
    `4) central emblem/crest/animal/logo described briefly, or "no emblem"\n` +
    `5) any legible text on the band, verbatim, or "no text"\n` +
    `6) border or edge pattern\n` +
    `7) overall style (e.g. ornate classic, minimalist modern)\n` +
    `Bruk korte engelske stikkord. Vær konsis og konsekvent.`;

  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), 25_000);
  try {
    const r = await fetch("https://api.openai.com/v1/chat/completions", {
      signal: controller.signal,
      method: "POST",
      headers: { "Authorization": `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "gpt-5-mini",
        messages: [{
          role: "user",
          content: [
            { type: "text", text: prompt },
            { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64}` } },
          ],
        }],
        reasoning_effort: "minimal",
        max_completion_tokens: 400,
      }),
    });
    if (!r.ok) throw new Error(`OpenAI vision-feil ${r.status}: ${await r.text()}`);
    const j = await r.json();
    return (j.choices?.[0]?.message?.content ?? "").trim();
  } finally {
    clearTimeout(t);
  }
}

async function embed(text: string, key: string): Promise<number[]> {
  const r = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: { "Authorization": `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "text-embedding-3-small",
      input: text && text.length > 0 ? text : "unknown cigar band",
      dimensions: 512,
    }),
  });
  if (!r.ok) throw new Error(`OpenAI embed-feil ${r.status}: ${await r.text()}`);
  const j = await r.json();
  return j.data[0].embedding as number[];
}

function vecLiteral(v: number[]): string {
  return "[" + v.join(",") + "]";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const key = Deno.env.get("OPENAI_API_KEY");
    if (!key) throw new Error("OPENAI_API_KEY er ikke satt som secret");
    const body = await req.json().catch(() => ({}));
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE);

    // C) BACKFILL — fyll manglende embeddings. Krever service-role i x-admin-key.
    if (body.backfill === true) {
      if (req.headers.get("x-admin-key") !== SERVICE_ROLE) {
        return new Response(JSON.stringify({ error: "unauthorized" }), {
          status: 401, headers: { ...cors, "Content-Type": "application/json" },
        });
      }
      const limit = Math.min(Number(body.limit ?? 20), 50);
      const { data: rows } = await admin
        .from("cigar_image_samples")
        .select("id, image_url, storage_path, ocr_text")
        .is("embedding", null)
        .limit(limit);
      let done = 0, failed = 0;
      for (const row of rows ?? []) {
        try {
          const url = row.image_url ??
            (row.storage_path ? publicUrl(row.storage_path) : null);
          if (!url) { failed++; continue; }
          const b64 = await toBase64FromUrl(url);
          if (!b64) { failed++; continue; }
          const sig = await describeBand(b64, row.ocr_text ?? "", key);
          const vec = await embed(sig, key);
          await admin.from("cigar_image_samples")
            .update({ embedding: vecLiteral(vec) }).eq("id", row.id);
          done++;
        } catch (e) {
          failed++;
          console.error("backfill-rad feilet", row.id, e);
        }
      }
      const { count: remaining } = await admin
        .from("cigar_image_samples")
        .select("id", { count: "exact", head: true })
        .is("embedding", null);
      return new Response(JSON.stringify({ done, failed, remaining }), {
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    // Skaff bildet: enten direkte base64, eller hentet fra storage_path.
    let base64: string | null = body.image ?? null;
    if (!base64 && body.storage_path) {
      base64 = await toBase64FromUrl(publicUrl(body.storage_path));
    }
    if (!base64) {
      return new Response(JSON.stringify({ error: "mangler image eller storage_path" }), {
        status: 400, headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const signature = await describeBand(base64, body.ocr_text ?? "", key);
    const embedding = await embed(signature, key);

    // B) LAGRE — kalt etter en løst skanning: fest embedding på prøven.
    if (body.storage_path && body.cigar_id) {
      await admin.from("cigar_image_samples")
        .update({ embedding: vecLiteral(embedding) })
        .eq("storage_path", body.storage_path)
        .eq("cigar_id", body.cigar_id);
      return new Response(JSON.stringify({ ok: true, signature }), {
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    // A) SPØRRING — finn sigarer med lignende bånd blant tidligere løste skann.
    const { data: suggestions } = await admin.rpc("match_cigar_by_band", {
      p_embedding: vecLiteral(embedding),
      p_match_count: 6,
      p_min_similarity: 0.72,
    });

    return new Response(JSON.stringify({ signature, suggestions: suggestions ?? [] }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("embed-band feilet:", e);
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : "ukjent feil" }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
    );
  }
});
