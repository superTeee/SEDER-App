// scan-cigar. v50: GOOGLE LENS SOM SJEF — ga Lens et tydelig, navngitt treff
// (serien står i tittelen), LEDER det treffet. Andre signaler får bekrefte det
// eller ligge under; de kan ikke lenger dytte en annen sigar forbi et sikkert
// Lens-treff (slik «riktig merke» + tilfeldig tekst-treff gjorde før).
// v49: STRUKTURELL LENS-FIKS — et Google Lens-treff får bare stemme
// på en SPESIFIKK sigar hvis seriens navn faktisk står i Lens-tittelen. Før valgte
// vi det HØYEST-scorende prefikset av tittelen; det korte merke-prefikset
// ("cavalier geneve") vant alltid pga. delstreng-bonus og pekte på merkets
// standard-sigar (Paca) i stedet for serien Lens navnga (10th Anniversary). Nå
// velger vi det mest SPESIFIKKE treffet, og et rent merke-treff gir kun brand-signal.
// v48: KORROBERINGS-REGEL — et tekst-treff får bare stenge Google Lens ute hvis
// merket faktisk ble LEST på båndet. Uten dette kunne en delvis/feillest tekst gi
// et falskt sikkert treff (Montenegro «O», Ilegal «San Andrés») som hoppet over Lens.
// v47: rene dekkblad-/region-ord driver ikke tekst-treff.
// v46: «To vitner»-løftet beholder intern rangering (2012 vs Super Fly).
// v45: Beholder enkelt-tegn (V, G, O, tall) i Lens-navnet.
// v44: Google Lens slås opp DIREKTE mot basen; fuzzy avvises ved feil merke.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ScanRequest { image: string; ocr_text?: string; mode?: "identify" | "shape" | "wrapper"; }
interface AIGuess { brand: string; series?: string | null; wrapper?: string | null; confidence: number; reason: string; }
interface AICigarMatch { cigar_id: string; confidence: number; reason: string; exact_match: boolean; brand?: string; authoritative?: boolean; }
interface ShapeGuess { body_type: string; head_type: string; foot_type: string; confidence: number; reason: string; }
interface WrapperColorGuess { wrapper: string | null; confidence: number; reason: string; }

const KNOWN_WRAPPER_TYPES = [
  "Connecticut Shade", "Connecticut", "Sun Grown", "Sungrown", "Habano",
  "Maduro", "Oscuro", "Corojo", "Colorado", "Cameroon", "Natural",
];

function extractWrapperKeyword(text: string | null | undefined): string | null {
  if (!text) return null;
  const lower = text.toLowerCase();
  for (const type of KNOWN_WRAPPER_TYPES) {
    if (lower.includes(type.toLowerCase())) return type;
  }
  return null;
}

// Rene dekkblad-/region-/format-ord: står på mange bånd men er ikke distinkte
// merke-/serienavn. Et søk som BARE består av disse skal ikke gi tekst-treff.
const GENERIC_BAND_TERMS = new Set([
  "andres", "maduro", "habano", "habana", "connecticut", "corojo", "oscuro",
  "colorado", "cameroon", "sumatra", "broadleaf", "natural", "criollo",
  "candela", "sungrown", "nicaragua", "nicaraguan", "honduras", "honduran",
  "dominican", "dominicana", "ecuador", "ecuadorian", "mexican", "mexico",
  "reserva", "reserve", "edicion", "seleccion", "limited", "edition", "special",
  "clasico", "toro", "robusto", "corona", "churchill", "gordo", "belicoso",
  "torpedo", "petit", "grande", "san", "shade", "wrapper", "cigars", "cigar",
]);

// true hvis søket — etter at vi fjerner rene dekkblad-/region-/format-ord og
// fyllord — ikke har noe distinkt merke-/serienavn igjen. (Forventer normalisert
// tekst: små bokstaver, uten aksenter.)
function isGenericQuery(nq: string): boolean {
  const words = nq.split(/\s+/).filter((w) =>
    w.length >= 3 &&
    !GENERIC_BAND_TERMS.has(w) &&
    !["the", "and", "los", "las", "del", "por", "que", "por"].includes(w)
  );
  return words.length === 0;
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
let lastJinaError = "";
let lensDiag: Record<string, unknown> | null = null;

function u8ToB64(bytes: Uint8Array): string {
  let bin = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    bin += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(bin);
}

function vecLiteral(v: number[]): string {
  return "[" + v.join(",") + "]";
}

async function jinaEmbed(item: Record<string, string>, jinaKey: string): Promise<number[] | null> {
  for (let attempt = 0; attempt < 3; attempt++) {
    const r = await fetch("https://api.jina.ai/v1/embeddings", {
      method: "POST",
      headers: { "Authorization": `Bearer ${jinaKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "jina-clip-v2", dimensions: 512, normalized: true, embedding_type: "float", input: [item] }),
    });
    if (r.ok) {
      const j = await r.json();
      const v = j?.data?.[0]?.embedding;
      return (Array.isArray(v) && v.length === 512) ? v as number[] : null;
    }
    lastJinaError = r.status + ": " + (await r.text()).slice(0, 200);
    if (r.status === 429 || r.status === 503) { await sleep(Math.min(1000 * Math.pow(2, attempt), 4000)); continue; }
    return null;
  }
  return null;
}

async function embedB64(base64: string, jinaKey: string): Promise<number[] | null> {
  for (const item of [{ image: `data:image/jpeg;base64,${base64}` }, { image: base64 }, { bytes: base64 }]) {
    const v = await jinaEmbed(item, jinaKey);
    if (v) return v;
  }
  return null;
}

async function locateBandWithGPT4o(b64: string, apiKey: string): Promise<number[] | null> {
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), 15_000);
  try {
    const r = await fetch("https://api.openai.com/v1/chat/completions", {
      signal: controller.signal, method: "POST",
      headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "gpt-5-mini",
        messages: [{ role: "user", content: [
          { type: "text", text: `Se på bildet av en sigar. Finn BÅNDET og returner en avgrensningsboks i normaliserte koordinater 0-1. Svar KUN med JSON: {"box":[x0,y0,x1,y1]} eller {"box":null}.` },
          { type: "image_url", image_url: { url: `data:image/jpeg;base64,${b64}` } },
        ] }],
        reasoning_effort: "minimal", max_completion_tokens: 700,
      }),
    });
    clearTimeout(t);
    if (!r.ok) return null;
    const j = await r.json();
    let c: string = j?.choices?.[0]?.message?.content ?? "";
    c = c.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
    const parsed = JSON.parse(c);
    const box = parsed?.box;
    if (!Array.isArray(box) || box.length !== 4) return null;
    let [x0, y0, x1, y1] = box.map(Number);
    if (![x0, y0, x1, y1].every((n) => Number.isFinite(n))) return null;
    if (x1 < x0) [x0, x1] = [x1, x0];
    if (y1 < y0) [y0, y1] = [y1, y0];
    x0 = Math.max(0, Math.min(1, x0)); y0 = Math.max(0, Math.min(1, y0));
    x1 = Math.max(0, Math.min(1, x1)); y1 = Math.max(0, Math.min(1, y1));
    if ((x1 - x0) < 0.05 || (y1 - y0) < 0.03) return null;
    return [x0, y0, x1, y1];
  } catch { clearTimeout(t); return null; }
}

async function cropAndDownscaleToB64(bytes: Uint8Array, box: number[] | null, maxDim = 512): Promise<string> {
  try {
    const { Image } = await import("https://deno.land/x/imagescript@1.2.15/mod.ts");
    let img = await Image.decode(bytes);
    const W = img.width, H = img.height;
    const region = box ?? [0.05, 0.28, 0.95, 0.78];
    let [x0, y0, x1, y1] = region;
    const margin = 0.18;
    const mx = (x1 - x0) * margin, my = (y1 - y0) * margin;
    x0 = Math.max(0, x0 - mx); y0 = Math.max(0, y0 - my);
    x1 = Math.min(1, x1 + mx); y1 = Math.min(1, y1 + my);
    const px = Math.round(x0 * W), py = Math.round(y0 * H);
    const pw = Math.round((x1 - x0) * W), ph = Math.round((y1 - y0) * H);
    if (pw > 8 && ph > 8 && (pw < W || ph < H)) img = img.crop(px, py, pw, ph);
    const m = Math.max(img.width, img.height);
    if (m > maxDim) img.resize(Math.round(img.width * maxDim / m), Math.round(img.height * maxDim / m));
    const jpeg = await img.encodeJPEG(80);
    return u8ToB64(jpeg);
  } catch { return u8ToB64(bytes); }
}

async function embedScanImage(base64Image: string, jinaKey: string, openaiKey: string | undefined): Promise<number[] | null> {
  try {
    const bytes = Uint8Array.from(atob(base64Image), (c) => c.charCodeAt(0));
    const box = openaiKey ? await locateBandWithGPT4o(base64Image, openaiKey) : null;
    const b64 = await cropAndDownscaleToB64(bytes, box);
    return await embedB64(b64, jinaKey);
  } catch { return null; }
}

function cleanLensTitle(title: string): string {
  let s = title;
  s = s.replace(/^\s*(cigar\s+review|review)\s*:?\s*/i, "");
  s = s.split(/\s+:\s*r\//i)[0];
  s = s.split(/\s+[|–—]\s+/)[0];
  s = s.replace(/\d+\s*["']?\s*(\d+\/\d+)?\s*[x×*]\s*\d+/gi, " ");
  s = s.replace(/\d+[.,]\d+\s*[x×]\s*\d+/gi, " ");
  s = s.replace(/\b(cigar review|review|cigars daily|cigar\.com|cigars\.com|halfwheel|neptune cigar|famous smoke|jr cigars|r\/[a-z_]+)\b/gi, " ");
  s = s.replace(/[^\p{L}\p{N}&' ]+/gu, " ").replace(/\s+/g, " ").trim();
  return s;
}

async function lensLookup(base64: string, serpKey: string, supabase: any): Promise<AICigarMatch[]> {
  let path = "";
  try {
    const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
    path = `lens/${crypto.randomUUID()}.jpg`;
    const up = await supabase.storage.from("scan-temp").upload(path, bytes, { contentType: "image/jpeg", upsert: true });
    if (up.error) { lensDiag = { error: "opplasting: " + up.error.message }; return []; }
    const { data: pub } = supabase.storage.from("scan-temp").getPublicUrl(path);
    const imageUrl: string | undefined = pub?.publicUrl;
    if (!imageUrl) { lensDiag = { error: "ingen public url" }; return []; }

    const serpUrl = `https://serpapi.com/search.json?engine=google_lens&url=${encodeURIComponent(imageUrl)}&api_key=${serpKey}`;
    const r = await fetch(serpUrl);
    if (!r.ok) { lensDiag = { status: r.status, error: (await r.text()).slice(0, 200) }; return []; }
    const j = await r.json();

    const titles: string[] = [];
    const kg = j?.knowledge_graph;
    if (Array.isArray(kg)) { for (const k of kg) if (k?.title) titles.push(String(k.title)); }
    for (const m of (j?.visual_matches ?? []) as Array<{ title?: string }>) { if (m?.title) titles.push(String(m.title)); }
    lensDiag = { status: r.status, n_visual: Array.isArray(j?.visual_matches) ? j.visual_matches.length : 0, n_titles: titles.length, cleaned: titles.slice(0, 8).map((t) => cleanLensTitle(t)), matched: 0 };

    type SV = { weight: number; votes: number; specVotes: number; best: number; id: string; brand: string; series: string };
    const seriesVotes = new Map<string, SV>();
    let nq = 0;
    const titleTop = titles.slice(0, 12);
    // DIREKTE oppslag: produktnavnet ligger FORAN i tittelen ("Camacho
    // Connecticut ..."), butikk-støy kommer etter. Prøv voksende prefikser
    // (merke, merke+linje, ...).
    for (let ti = 0; ti < titleTop.length; ti++) {
      if (nq >= 60) break;
      const c = cleanLensTitle(titleTop[ti]);
      const cl = c.toLowerCase();
      // Behold enkelt-tegn som er bokstav/tall (V, G, O, 4, 601): de er ofte
      // selve serie-nøkkelen i sigarnavn.
      const words = c.split(" ").filter((w) => w.length >= 2 || /^[\p{L}\p{N}]$/u.test(w));
      if (words.length < 2) continue;
      // Velg den mest SPESIFIKKE rada (flest serie-ord fra tittelen), IKKE bare
      // den med høyest råscore. Ellers vinner det korte merke-prefikset
      // ("cavalier geneve") med sin delstreng-bonus og peker på merkets
      // standard-sigar (Paca) i stedet for serien Lens faktisk navnga (10th
      // Anniversary). Et Lens-treff får bare stemme SPESIFIKT hvis seriens navn
      // står i tittelen; ellers teller det kun som et svakt merke-signal.
      let bestRow: { id: string; brand: string; series: string; score: number; spec: number } | null = null;
      const maxN = Math.min(words.length, 6);
      for (let n = 2; n <= maxN; n++) {
        if (nq++ >= 60) break;
        const q = words.slice(0, n).join(" ");
        const { data: rows } = await supabase.rpc("match_cigar", { p_query: q, p_limit: 1 });
        const row = (rows ?? [])[0] as { id: string; brand: string; series: string; score: number } | undefined;
        if (!row || Number(row.score) < 0.4) continue;
        // Merket rada peker på må stå i Lens-tittelen.
        const brandToks = (row.brand ?? "").toLowerCase().split(/\s+/).filter((x) => x.length >= 3);
        const brandInTitle = brandToks.length === 0 || brandToks.some((x) => cl.includes(x));
        if (!brandInTitle) continue;
        // Hvor mange distinkte serie-ord fra rada står i tittelen?
        const serToks = (row.series ?? "").toLowerCase().split(/\s+/).filter((x) => x.length >= 3 && !GENERIC_BAND_TERMS.has(x));
        const spec = serToks.filter((x) => cl.includes(x)).length;
        const serEmpty = serToks.length === 0;
        // Godta bare: (a) serien er navngitt i tittelen (spec>=1) med rimelig
        // score, eller (b) merket har ingen serie og score er sterk.
        const ok = (spec >= 1 && Number(row.score) >= 0.4) || (serEmpty && Number(row.score) >= 0.6);
        if (!ok) continue;
        if (!bestRow || spec > bestRow.spec || (spec === bestRow.spec && Number(row.score) > bestRow.score)) {
          bestRow = { id: row.id, brand: row.brand, series: row.series, score: Number(row.score), spec };
        }
      }
      if (!bestRow) continue;
      const key = (bestRow.brand + "|" + (bestRow.series ?? "")).toLowerCase();
      // Spesifikke treff (serie navngitt) veier tyngre enn rene merke-treff.
      const wRank = (1 / (1 + ti * 0.4)) * (bestRow.spec >= 1 ? 1 : 0.3);
      const spec1 = bestRow.spec >= 1 ? 1 : 0;
      const cur = seriesVotes.get(key);
      if (cur) { cur.weight += wRank; cur.votes += 1; cur.specVotes += spec1; if (bestRow.score > cur.best) { cur.best = bestRow.score; cur.id = bestRow.id; } }
      else seriesVotes.set(key, { weight: wRank, votes: 1, specVotes: spec1, best: bestRow.score, id: bestRow.id, brand: bestRow.brand, series: bestRow.series });
    }

    const out: AICigarMatch[] = [...seriesVotes.values()]
      .sort((a, b) => (b.weight - a.weight) || (b.best - a.best))
      .slice(0, 5)
      .map((v, i) => ({
        cigar_id: v.id,
        confidence: i === 0 ? Math.min(Math.max(v.best, 0.72), 0.9) : Math.max(0.6 - i * 0.04, 0.5),
        reason: `Google Lens kjente igjen båndet som «${v.brand}${v.series ? " " + v.series : ""}»`,
        exact_match: false,
        brand: v.brand,
        authoritative: i === 0 && v.specVotes >= 1,
      }));
    if (lensDiag) { lensDiag.matched = out.length; lensDiag.n_series = seriesVotes.size; }
    return out;
  } catch (e) {
    lensDiag = { error: e instanceof Error ? e.message : "ukjent" };
    return [];
  } finally {
    if (path) { try { await supabase.storage.from("scan-temp").remove([path]); } catch (_) { /* */ } }
  }
}

function typesOf(reason: string): Set<string> {
  const r = (reason ?? "").toLowerCase();
  const t = new Set<string>();
  if (r.includes("google lens")) t.add("lens");
  if (r.includes("fingeravtrykk") || r.includes("bilde-likhet")) t.add("fp");
  const nameLike = r.includes("bånd-tekst matchet") || r.includes("samme merke") ||
    r.includes("båndet viser") || r.includes("usikker på") || r.includes("identifisert") || r.includes("serie");
  if (nameLike || t.size === 0) t.add("name");
  return t;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { image, ocr_text, mode }: ScanRequest = await req.json();
    if (!image) return new Response(JSON.stringify({ error: "Mangler 'image'" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) throw new Error("OPENAI_API_KEY mangler");

    if (mode === "shape") return new Response(JSON.stringify(await classifyShapeWithGPT4o(image, openaiKey)), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    if (mode === "wrapper") return new Response(JSON.stringify(await classifyWrapperWithGPT4o(image, openaiKey)), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    if (mode === "identify") {
      const gs = await identifyWithGPT4o(image, ocr_text ?? "", openaiKey);
      return new Response(JSON.stringify(gs[0] ?? {}), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const jinaKey = Deno.env.get("JINA_API_KEY");
    const [guesses, fpEmbedding] = await Promise.all([
      identifyWithGPT4o(image, ocr_text ?? "", openaiKey),
      jinaKey ? embedScanImage(image, jinaKey, openaiKey) : Promise.resolve(null),
    ]);

    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const matches: AICigarMatch[] = [];
    const seenCigarIds = new Set<string>();

    const norm = (s: string | null | undefined): string => (s ?? "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
    const ocrNorm = norm(ocr_text);
    const hasReadableOcr = ocrNorm.replace(/[^a-z0-9]/g, "").length >= 2;
    const textSupportedBrands = new Set<string>();
    if (hasReadableOcr && !isGenericQuery(ocrNorm)) {
      const { data: ocrMatch } = await supabase.rpc("match_cigar", { p_query: (ocr_text ?? "").trim(), p_limit: 8 });
      for (const r of (ocrMatch ?? []) as Array<{ brand: string; score: number }>) {
        if (Number(r.score) >= 0.5 && r.brand) textSupportedBrands.add(norm(r.brand));
      }
    }
    const guessIsTextSupported = (g: AIGuess): boolean => {
      if (!hasReadableOcr) return true;
      if (g.brand && ocrNorm.includes(norm(g.brand))) return true;
      if (g.series && ocrNorm.includes(norm(g.series))) return true;
      if (g.series) {
        const words = norm(g.series).split(/\s+/).filter((w) => w.length >= 2);
        if (words.length > 0 && words.filter((w) => ocrNorm.includes(w)).length >= Math.ceil(words.length * 0.6)) return true;
      }
      if (g.brand && textSupportedBrands.has(norm(g.brand))) return true;
      return false;
    };

    for (const guess of guesses) {
      const guessCorroborated = guessIsTextSupported(guess);
      let { data, error } = await supabase.from("cigars").select("id, series, wrapper_leaf").ilike("brand", `%${guess.brand}%`).limit(300);
      if (!error && (!data || data.length === 0)) {
        const { data: aliasRows } = await supabase.from("cigar_aliases").select("brand").ilike("alias", guess.brand).limit(1);
        if (aliasRows && aliasRows.length > 0) {
          const retry = await supabase.from("cigars").select("id, series, wrapper_leaf").eq("brand", aliasRows[0].brand).limit(300);
          data = retry.data; error = retry.error;
        }
      }
      if (error || !data) continue;
      const effectiveWrapper = guess.wrapper ?? extractWrapperKeyword(guess.series) ?? extractWrapperKeyword(guess.reason);
      const seriesTextMatches = (a: string, b: string) => { const x = a.toLowerCase(), y = b.toLowerCase(); return x.includes(y) || y.includes(x); };
      const rowsMatchingGuessedSeries = guess.series ? data.filter((row) => row.series && seriesTextMatches(row.series, guess.series!)) : [];
      for (const row of data) {
        if (seenCigarIds.has(row.id)) continue;
        seenCigarIds.add(row.id);
        const seriesMatchesGuess = !!(guess.series && row.series && seriesTextMatches(row.series, guess.series));
        const wrapperMatchesGuess = !!(effectiveWrapper && row.wrapper_leaf && row.wrapper_leaf.toLowerCase().includes(effectiveWrapper.toLowerCase()));
        const distinctWrappers = new Set(rowsMatchingGuessedSeries.map((r) => (r.wrapper_leaf ?? "").toLowerCase().trim())).size;
        const seriesIsUnambiguous = rowsMatchingGuessedSeries.length === 0 || distinctWrappers <= 1;
        const isExactMatch = seriesMatchesGuess && (seriesIsUnambiguous || wrapperMatchesGuess) && guessCorroborated;
        let rowConfidence = isExactMatch ? guess.confidence : seriesMatchesGuess ? Math.max(guess.confidence - 0.15, 0.4) : Math.max(guess.confidence - 0.35, 0.3);
        if (!guessCorroborated) rowConfidence = Math.min(rowConfidence, 0.58);
        matches.push({ cigar_id: row.id, confidence: rowConfidence, reason: isExactMatch ? guess.reason : seriesMatchesGuess ? `${guess.reason} (usikker på wrapper-varianten)` : `Samme merke (${guess.brand}) identifisert på bildet`, exact_match: isExactMatch, brand: guess.brand });
      }
    }

    // Merker vi faktisk LESTE i teksten — brukes til å avvise fuzzy-treff som
    // kobler til FEIL merke via et delt ord ("Habana" → Sinistro Habana Vieja).
    const readBrands = new Set<string>();
    for (const g of guesses) {
      if (g.brand && hasReadableOcr && ocrNorm.includes(norm(g.brand))) readBrands.add(norm(g.brand));
    }

    const fuzzyQueries = new Set<string>();
    if (ocr_text && ocr_text.trim()) fuzzyQueries.add(ocr_text.trim());
    for (const g of guesses) {
      const bs = [g.brand, g.series].filter(Boolean).join(" ").trim();
      if (bs) fuzzyQueries.add(bs);
      if (g.brand) fuzzyQueries.add(g.brand);
      if (g.series) fuzzyQueries.add(g.series);
    }
    for (const fq of fuzzyQueries) {
      // Hopp over rene dekkblad-/region-ord ("San Andrés", "Maduro", ...): de
      // matcher tilfeldig de få sigarene som har ordet som serienavn og gir
      // falske sikre treff som stenger Google Lens ute.
      if (isGenericQuery(norm(fq))) continue;
      const { data: fuzzy, error: fErr } = await supabase.rpc("match_cigar", { p_query: fq, p_limit: 8 });
      if (fErr || !fuzzy) continue;
      for (const row of fuzzy as Array<{ id: string; brand: string; series: string; vitola: string; score: number }>) {
        if (row.score < 0.5) continue;
        if (seenCigarIds.has(row.id)) continue;
        // Leste vi et merke i teksten? Da må fuzzy-treffet være i DET merket.
        if (readBrands.size > 0 && !readBrands.has(norm(row.brand))) continue;
        seenCigarIds.add(row.id);
        matches.push({ cigar_id: row.id, confidence: Math.min(row.score, 1), reason: `Bånd-tekst matchet ${row.brand}${row.series ? " / " + row.series : ""}${row.vitola ? " (" + row.vitola + ")" : ""}`, exact_match: row.score >= 0.9, brand: row.brand });
      }
    }

    if (fpEmbedding) {
      const vec = vecLiteral(fpEmbedding);
      const { data: imgRows, error: imgErr } = await supabase.rpc("match_cigar_by_image", { p_embedding: vec, p_match_count: 6, p_min_similarity: 0.72 });
      if (!imgErr && imgRows && imgRows.length) {
        const rows = imgRows as Array<{ cigar_id: string; similarity: number; n_samples: number }>;
        const top = rows[0];
        const sim0 = Number(top.similarity);
        const sim1 = rows.length > 1 ? Number(rows[1].similarity) : 0;
        const margin = sim0 - sim1;
        const nSamples = Number(top.n_samples) || 1;
        let conf = 0, exact = false, note = "";
        if (sim0 >= 0.90 && margin >= 0.03) { conf = 0.92; exact = true; note = "svært sikkert"; }
        else if (sim0 >= 0.82 && margin >= 0.05) { conf = Math.min(sim0, 0.9); note = "klart høyest"; }
        else if (sim0 >= 0.80 && margin >= 0.035) { conf = 0.62; note = "sannsynlig"; }
        if (conf > 0) {
          if (nSamples >= 3 && conf < 0.95) conf = Math.min(conf + 0.02, 0.97);
          const existing = matches.find((m) => m.cigar_id === top.cigar_id);
          if (existing) { existing.confidence = Math.min(Math.max(existing.confidence, conf) + 0.03, 0.98); existing.exact_match = existing.exact_match || exact; existing.reason += ` · bekreftet av bilde-fingeravtrykk (${Math.round(sim0 * 100)}%, ${note})`; }
          else { matches.push({ cigar_id: top.cigar_id, confidence: conf, reason: `Bilde-fingeravtrykk: ${Math.round(sim0 * 100)}% likhet (${note})`, exact_match: exact }); seenCigarIds.add(top.cigar_id); }
        } else if (matches.length === 0) {
          for (const rr of rows.slice(0, 3)) {
            if (seenCigarIds.has(rr.cigar_id)) continue;
            const s = Number(rr.similarity);
            matches.push({ cigar_id: rr.cigar_id, confidence: Math.min(s * 0.6, 0.5), reason: `Mulig treff fra bilde-likhet (${Math.round(s * 100)}%) — usikkert`, exact_match: false });
            seenCigarIds.add(rr.cigar_id);
          }
        }
      }
    }

    const serpKey = Deno.env.get("SERPAPI_KEY");
    // KORROBERINGS-REGEL: et tekst-treff får bare stenge Google Lens ute hvis
    // merket faktisk ble LEST på båndet (står i OCR-teksten, i merkene vi leste,
    // eller ble tekst-støttet av OCR). Ellers er "sikkerheten" en gjetning —
    // delt ord, generisk tekst eller hallusinert merke — og Lens skal få lese.
    const brandRead = (b?: string): boolean => {
      if (!b) return false;
      const nb = norm(b);
      if (!nb) return false;
      return readBrands.has(nb) || textSupportedBrands.has(nb) || (hasReadableOcr && ocrNorm.includes(nb));
    };
    const strongName = matches.some((m) => m.confidence >= 0.82 && typesOf(m.reason).has("name") && brandRead(m.brand));
    const twoWitness = matches.some((m) => typesOf(m.reason).size >= 2);
    lensDiag = null;
    if (!serpKey) lensDiag = { skipped: "SERPAPI_KEY mangler" };
    else if (strongName) lensDiag = { skipped: "sterkt navn-treff" };
    else if (twoWitness) lensDiag = { skipped: "to vitner enige" };
    if (serpKey && image && !strongName && !twoWitness) {
      try {
        const lensMatches = await lensLookup(image, serpKey, supabase);
        for (const lm of lensMatches) {
          const existing = matches.find((m) => m.cigar_id === lm.cigar_id);
          if (existing) { existing.confidence = Math.max(existing.confidence, lm.confidence); existing.reason += ` · ${lm.reason}`; existing.authoritative = existing.authoritative || lm.authoritative; }
          else matches.push(lm);
        }
      } catch (e) { lensDiag = { error: e instanceof Error ? e.message : "ukjent" }; }
    }

    for (const m of matches) {
      const t = typesOf(m.reason);
      if (t.size >= 2) {
        m.confidence = Math.min(0.95, Math.max(m.confidence, 0.85) + Math.max(0, m.confidence - 0.6) * 0.25);
        m.exact_match = m.exact_match || m.confidence >= 0.9;
      }
      else if (t.has("name") && m.confidence >= 0.82) { /* korroborert */ }
      else if (t.has("lens")) { m.confidence = Math.min(m.confidence, 0.8); }
      else { m.confidence = Math.min(m.confidence, 0.78); m.exact_match = false; }
    }

    // --- Dekkblad-skille mellom linjer i SAMME merke ---
    try {
      const guessedWrapper = extractWrapperKeyword(guesses.find((g) => g.wrapper)?.wrapper);
      if (guessedWrapper && matches.length > 1) {
        matches.sort((a, b) => b.confidence - a.confidence);
        const leader = matches[0];
        const contenders = matches.filter((m) => leader.confidence - m.confidence <= 0.15);
        const ids = [...new Set(contenders.map((m) => m.cigar_id))];
        const { data: wrows } = await supabase.from("cigars").select("id, brand, wrapper_leaf").in("id", ids);
        const winfo = new Map<string, { brand: string; wrap: string }>();
        for (const r of (wrows ?? []) as Array<{ id: string; brand: string; wrapper_leaf: string | null }>) {
          winfo.set(r.id, { brand: norm(r.brand), wrap: (r.wrapper_leaf ?? "").toLowerCase() });
        }
        const gw = guessedWrapper.toLowerCase();
        const wrapHit = (id: string) => (winfo.get(id)?.wrap ?? "").includes(gw);
        const leaderBrand = winfo.get(leader.cigar_id)?.brand;
        if (leaderBrand && !wrapHit(leader.cigar_id)) {
          const better = contenders.find((m) => m.cigar_id !== leader.cigar_id && winfo.get(m.cigar_id)?.brand === leaderBrand && wrapHit(m.cigar_id));
          if (better) {
            better.confidence = Math.min(Math.max(better.confidence, leader.confidence) + 0.03, 0.92);
            better.reason += ` · dekkbladet (${guessedWrapper}) passer denne linjen best`;
            leader.confidence = Math.max(leader.confidence - 0.05, 0.5);
            if (lensDiag) lensDiag.wrapper_tiebreak = `${guessedWrapper}: foretrakk annen linje i ${leaderBrand}`;
          }
        }
      }
    } catch (_) { /* dekkblad-skille er best-effort */ }

    // GOOGLE LENS SOM SJEF: ga Lens et tydelig, navngitt treff (serien sto i
    // tittelen), skal DET treffet lede. Andre signaler får bekrefte eller ligge
    // under — de får ikke dytte en annen sigar forbi et sikkert Lens-treff.
    const lensBoss = matches.find((m) => m.authoritative);
    if (lensBoss) {
      lensBoss.confidence = Math.max(lensBoss.confidence, 0.9);
      lensBoss.exact_match = true;
      for (const m of matches) {
        if (m === lensBoss) continue;
        m.exact_match = false;
        if (m.confidence >= lensBoss.confidence) m.confidence = Math.max(0.3, lensBoss.confidence - 0.08);
      }
      if (lensDiag) lensDiag.lens_boss = `${lensBoss.brand ?? ""} leder (Lens navnga serien)`;
    }

    matches.sort((a, b) => b.confidence - a.confidence);
    const topMatches = matches.slice(0, 12);

    if (topMatches.length === 0) { try { await supabase.from("scan_misses").insert({ ocr_text: ocr_text ?? null, guesses, match_count: 0 }); } catch (_) { /* */ } }
    try { await supabase.from("scan_debug").insert({ ocr_text: ocr_text ?? null, has_readable_ocr: hasReadableOcr, text_supported_brands: Array.from(textSupportedBrands), guesses, top_matches: topMatches.slice(0, 6), lens_diag: lensDiag }); } catch (_) { /* */ }

    return new Response(JSON.stringify(topMatches), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Ukjent feil" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});

async function identifyWithGPT4o(base64Image: string, ocrText: string, apiKey: string): Promise<AIGuess[]> {
  const prompt = `Du er ekspert på sigarer. Se på bildet av sigarbåndet og identifiser merket (brand), serien (series), og wrapper.
${ocrText ? `Apple Vision OCR fant: "${ocrText}" — bruk som hint, men stol mest på bildet.` : ""}

VIKTIG — LES, IKKE GJETT: Returner KUN navn du FAKTISK KAN LESE. Klarer du ikke lese noe identifiserende navn — fordi båndet er en ren logo uten navn, eller bildet er for mørkt/uskarpt — returner TOM liste []. En enslig bokstav ("D", "F", "A") uten annen tekst er IKKE nok; da returnerer du []. Et feil merke er verre enn ingen.

"series" skal KUN være serienavnet.

WRAPPER (dekkblad): Hvis sigarkroppen er godt og NØYTRALT belyst, bedøm dekkbladets FARGE og velg NÆRMESTE fra: "Connecticut" (lyst/gyllent/blekt), "Habano" (middels brunt), "Corojo" (rødbrunt), "Sun Grown" (mørkere brunt), "Maduro" (mørkt sjokoladebrunt), "Oscuro" (nesten svart), "Cameroon" (spettet gyllenbrun). VIKTIG: Sett "wrapper": null hvis bildet er mørkt, i skygge/motlys, over-/undereksponert, eller fargen er tvetydig — IKKE gjett farge i dårlig lys, det villeder mer enn det hjelper. Oppgi bare en farge du faktisk er trygg på. Fargen hjelper å skille linjer i samme merke.

NB: tall-/kodenavn som "1.4", "No. 4" — ta med i "series". NB: "VF" i laurbærkrans = "Vega Fina". NB: trekant med "A" og tobakksblad = "Artista".

Svar med 1-3 kandidater. KUN gyldig JSON:
[{ "brand": "string", "series": "string eller null", "wrapper": "string eller null", "confidence": 0.0-1.0, "reason": "kort på norsk" }]`;
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 25_000);
  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      signal: controller.signal, method: "POST",
      headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "gpt-5-mini", messages: [{ role: "user", content: [{ type: "text", text: prompt }, { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Image}` } }] }], reasoning_effort: "minimal", max_completion_tokens: 1500 }),
    });
  } catch (e) { clearTimeout(timeoutId); if (e instanceof Error && e.name === "AbortError") return []; throw e; }
  clearTimeout(timeoutId);
  if (!response.ok) throw new Error(`OpenAI-feil (${response.status})`);
  const data = await response.json();
  const content: string = data.choices?.[0]?.message?.content ?? "[]";
  const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
  try { return JSON.parse(cleaned); } catch { return []; }
}

async function classifyShapeWithGPT4o(base64Image: string, apiKey: string): Promise<ShapeGuess> {
  const prompt = `Se på HELE sigaren og klassifiser formen. body_type fra: Parejo, Box-Pressed, Torpedo, Torpedo Box-Pressed, Belicoso, Pyramid, Perfecto, Salomon, Diadema, Chisel, Culebra. head_type: Round, Pointed, Wedge. foot_type: Open, Closed, Tapered. KUN JSON: { "body_type": "string", "head_type": "string", "foot_type": "string", "confidence": 0.0-1.0, "reason": "norsk" }`;
  const controller2 = new AbortController();
  const timeoutId2 = setTimeout(() => controller2.abort(), 25_000);
  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      signal: controller2.signal, method: "POST",
      headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "gpt-5-mini", messages: [{ role: "user", content: [{ type: "text", text: prompt }, { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Image}` } }] }], reasoning_effort: "minimal", max_completion_tokens: 1000 }),
    });
  } catch (e) { clearTimeout(timeoutId2); if (e instanceof Error && e.name === "AbortError") throw new Error("Form tidsavbrutt"); throw e; }
  clearTimeout(timeoutId2);
  if (!response.ok) throw new Error(`OpenAI-feil (${response.status})`);
  const data = await response.json();
  const content: string = data.choices?.[0]?.message?.content ?? "{}";
  const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
  try { return JSON.parse(cleaned); } catch { throw new Error("Kunne ikke tolke form-respons"); }
}

async function classifyWrapperWithGPT4o(base64Image: string, apiKey: string): Promise<WrapperColorGuess> {
  const prompt = `Se på HELE sigaren og vurder wrapper leaf. Velg fra: Connecticut, Maduro, Habano, Sun Grown, Natural, Cameroon, Corojo, Candela, Oscuro. Ser du ikke sigarkroppen tydelig, sett null. KUN JSON: { "wrapper": "string eller null", "confidence": 0.0-1.0, "reason": "norsk" }`;
  const controller3 = new AbortController();
  const timeoutId3 = setTimeout(() => controller3.abort(), 25_000);
  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      signal: controller3.signal, method: "POST",
      headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "gpt-5-mini", messages: [{ role: "user", content: [{ type: "text", text: prompt }, { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Image}` } }] }], reasoning_effort: "minimal", max_completion_tokens: 1000 }),
    });
  } catch (e) { clearTimeout(timeoutId3); if (e instanceof Error && e.name === "AbortError") throw new Error("Wrapper tidsavbrutt"); throw e; }
  clearTimeout(timeoutId3);
  if (!response.ok) throw new Error(`OpenAI-feil (${response.status})`);
  const data = await response.json();
  const content: string = data.choices?.[0]?.message?.content ?? "{}";
  const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
  try { return JSON.parse(cleaned); } catch { throw new Error("Kunne ikke tolke wrapper-respons"); }
}
