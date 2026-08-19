// supabase/functions/parse-receipt/index.ts
// v6: målbasert berikelse. For hver kvittering-linje henter vi som før topp-5
// tekst-kandidater (match_cigar), MEN legger nå også til den raden i serien som
// passer MÅLENE til en generisk vitola best (via resolve_by_size). Da når
// «Alma del Campo Robusto» fram til «Tribu» selv om ingen rad heter «Robusto».
// GPT velger fortsatt riktig kandidat blant de berikede.
//
// OpenAI-nøkkelen ligger kun her server-side — aldri i appen.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ReceiptRequest { image: string; }
interface ReceiptLine { name: string; quantity: number; unit_price: number | null; }
interface MatchedLine {
  cigar_id: string; brand: string; series: string | null; vitola: string | null;
  receipt_name: string; quantity: number; unit_price: number | null; score: number;
}
interface Candidate {
  id: string; brand: string; series: string | null; vitola: string | null;
  score: number; label: string;
}

// Terskel brukes KUN som fallback hvis GPT-valg-steget feiler.
const MATCH_THRESHOLD = 0.45;

// Trekk ut mål fra en linje: "5 x 52", "5 1/4 x 52", "6.5x54" -> {ring, length}.
// Sigar-konvensjon: LENGDE (tommer) × RING (2 siffer). null hvis ikke funnet.
function parseMixed(s: string): number {
  s = s.trim().replace(",", ".");
  const mixed = s.match(/^(\d+)\s+(\d)\/(\d)$/);            // "5 1/4"
  if (mixed) return parseInt(mixed[1]) + parseInt(mixed[2]) / parseInt(mixed[3]);
  const frac = s.match(/^(\d)\/(\d)$/);                      // "1/2"
  if (frac) return parseInt(frac[1]) / parseInt(frac[2]);
  return parseFloat(s);
}
function extractDims(name: string): { ring: number; length: number } | null {
  const m = name.match(/(\d+(?:\s+\d\/\d)?(?:[.,]\d+)?)\s*[x×]\s*(\d{2})\b/i);
  if (!m) return null;
  const length = parseMixed(m[1]);
  const ring = parseInt(m[2], 10);
  if (!Number.isFinite(length) || !Number.isFinite(ring) || ring < 30 || ring > 80) return null;
  if (length < 2 || length > 10) return null;
  return { ring, length };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { image }: ReceiptRequest = await req.json();
    if (!image) {
      return json({ error: "Mangler 'image' i forespørselen" }, 400);
    }

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) throw new Error("OPENAI_API_KEY er ikke satt som secret i Supabase");

    // 1) Les kvitteringen (GPT-vision)
    const parsed = await readReceiptWithGPT(image, openaiKey);
    console.log(
      `parse-receipt: butikk=${parsed.store ?? "?"}, ${parsed.lines.length} varelinje(r): ` +
        parsed.lines.map((l) => `${l.name} ×${l.quantity}`).join(", "),
    );

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // 2) Hent topp-5 tekst-kandidater per linje (trigram) + målbasert berikelse
    const candidatesPerLine: Candidate[][] = [];
    for (const line of parsed.lines) {
      const q = (line.name ?? "").trim();
      if (!q) { candidatesPerLine.push([]); continue; }
      const { data, error } = await supabase.rpc("match_cigar", { p_query: q, p_limit: 5 });
      const rows = (!error && Array.isArray(data) ? data : []) as Array<
        { id: string; brand: string; series: string | null; vitola: string | null; score: number }
      >;
      const cands: Candidate[] = rows.map((r) => ({
        id: r.id, brand: r.brand, series: r.series, vitola: r.vitola, score: r.score,
        label: [r.brand, r.series, r.vitola].filter(Boolean).join(" "),
      }));

      // Målbasert berikelse: bruk toppkandidatens merke/serie som kontekst, og
      // finn raden som passer MÅLENE til den generiske vitolaen best. Eksplisitte
      // mål på kvitteringen ("5 x 52") vinner over ordboka. Legges til (dedup),
      // så GPT kan velge den når "Robusto" egentlig er "Tribu".
      const top = rows[0];
      if (top && top.brand) {
        const dims = extractDims(q);
        const { data: rz } = await supabase.rpc("resolve_by_size", {
          p_brand: top.brand,
          p_series: top.series,
          p_vitola: q,
          p_ring: dims?.ring ?? null,
          p_length: dims?.length ?? null,
        });
        const sized = (Array.isArray(rz) ? rz : []) as Array<
          { id: string; brand: string; series: string | null; vitola: string | null }
        >;
        for (const r of sized.slice(0, 2)) {
          if (!cands.some((c) => c.id === r.id)) {
            cands.push({
              id: r.id, brand: r.brand, series: r.series, vitola: r.vitola, score: 0.5,
              label: [r.brand, r.series, r.vitola].filter(Boolean).join(" "),
            });
          }
        }
      }
      candidatesPerLine.push(cands);
    }

    // 3) La GPT velge riktig kandidat per linje (eller null)
    let chosen: (Candidate | null)[];
    try {
      const items = parsed.lines.map((line, i) => ({
        receipt: (line.name ?? "").trim(),
        candidates: candidatesPerLine[i],
      }));
      const picks = await pickMatchesWithGPT(items, openaiKey); // number|null per linje (0-basert)
      chosen = parsed.lines.map((_, i) => {
        const ci = picks[i];
        return (ci != null && candidatesPerLine[i][ci]) ? candidatesPerLine[i][ci] : null;
      });
    } catch (e) {
      console.error("GPT-valg feilet — faller tilbake til terskel:", e);
      chosen = parsed.lines.map((_, i) => {
        const best = candidatesPerLine[i][0];
        return best && best.score >= MATCH_THRESHOLD ? best : null;
      });
    }

    // 4) Bygg treff + ikke-funnet
    const matched: MatchedLine[] = [];
    const unmatched: ReceiptLine[] = [];
    for (let i = 0; i < parsed.lines.length; i++) {
      const line = parsed.lines[i];
      const q = (line.name ?? "").trim();
      if (!q) continue;
      const qty = line.quantity > 0 ? line.quantity : 1;
      const pick = chosen[i];
      if (pick) {
        matched.push({
          cigar_id: pick.id, brand: pick.brand, series: pick.series, vitola: pick.vitola,
          receipt_name: q, quantity: qty, unit_price: line.unit_price,
          score: 1, // GPT-bekreftet treff -> høy konfidens
        });
      } else {
        unmatched.push({ name: q, quantity: qty, unit_price: line.unit_price });
      }
    }

    console.log(`parse-receipt: ${matched.length} treff, ${unmatched.length} ikke funnet.`);
    return json({ store: parsed.store, matched, unmatched });
  } catch (error) {
    console.error("parse-receipt feilet:", error);
    return json({ error: error instanceof Error ? error.message : "Ukjent feil" }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status, headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

interface ParsedReceipt { store: string | null; lines: ReceiptLine[]; }

async function readReceiptWithGPT(base64Image: string, apiKey: string): Promise<ParsedReceipt> {
  const prompt =
    `Du er ekspert på sigarer og leser en kvittering fra en sigarbutikk (kan være på norsk, engelsk, spansk eller tysk).

Hent ut KUN varelinjene som er sigarer. Ignorer tilbehør (tennere, kuttere, askebegre, etuier), rabatter, moms, totalsum, bonuspoeng og betalingsinfo.

For hver sigar-varelinje:
- \"name\": produktnavnet så komplett som mulig (merke + serie + eventuell vitola/størrelse), akkurat slik det står på kvitteringen. Rett åpenbare OCR-feil hvis du er sikker.
- \"quantity\": antall sigarer på linja (heltall, minst 1). Kvitteringer skriver ofte \"2 x\", \"2 stk\", eller antall i egen kolonne.
- \"unit_price\": prisen for ÉN sigar som et tall (ingen valutategn). Hvis kvitteringen bare viser linjens totalsum, regn ut totalsum / antall. Sett null hvis prisen ikke er lesbar.

Prøv også å hente butikkens navn i \"store\" (øverst på kvitteringen), eller null.

Returner KUN gyldig JSON i dette formatet, ingen annen tekst:
{
  \"store\": \"string eller null\",
  \"lines\": [
    { \"name\": \"string\", \"quantity\": 1, \"unit_price\": 0.0 }
  ]
}
Hvis du ikke finner noen sigar-linjer, returner { \"store\": null, \"lines\": [] }.`;

  const data = await callOpenAI(apiKey, [
    { type: "text", text: prompt },
    { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Image}` } },
  ], 2000);

  const content: string = data.choices?.[0]?.message?.content ?? "{}";
  const obj = safeJSON(content);
  const lines: ReceiptLine[] = Array.isArray(obj?.lines)
    ? obj.lines
        .filter((l: unknown) => l && typeof (l as ReceiptLine).name === "string")
        .map((l: ReceiptLine) => ({
          name: String(l.name).trim(),
          quantity: Number.isFinite(l.quantity) && l.quantity > 0 ? Math.round(l.quantity) : 1,
          unit_price: typeof l.unit_price === "number" && Number.isFinite(l.unit_price) ? l.unit_price : null,
        }))
    : [];
  return { store: typeof obj?.store === "string" ? obj.store : null, lines };
}

// Gir GPT kvittering-linjer + kandidater og ber den velge riktig kandidat.
// Returnerer per linje: 0-basert kandidat-indeks, eller null.
async function pickMatchesWithGPT(
  items: { receipt: string; candidates: Candidate[] }[],
  apiKey: string,
): Promise<(number | null)[]> {
  const result: (number | null)[] = items.map(() => null);

  // Kun linjer som faktisk har kandidater trenger et valg.
  const active = items
    .map((it, i) => ({ it, i }))
    .filter((x) => x.it.receipt && x.it.candidates.length > 0);
  if (active.length === 0) return result;

  const block = active.map(({ it, i }) => {
    const cands = it.candidates.map((c, ci) => `${ci + 1}) ${c.label}`).join("   ");
    return `[${i}] kvittering: "${it.receipt}"\n     kandidater: ${cands}`;
  }).join("\n");

  const prompt =
    `Du er sigar-ekspert og kobler kvittering-linjer til riktig sigar i katalogen vår.
For hver linje får du kvittering-teksten og opptil 5 kandidater fra databasen.
Velg kandidaten som er SAMME sigar som kvittering-linja — ta høyde for forkortelser, manglende ord, rekkefølge og språk, og bruk din egen kunnskap om sigarer. Forhandlere bruker ofte GENERISKE størrelsesnavn (Robusto, Toro, Gordo) selv om produsenten bruker egne navn (Tribu, Sendero, Madroño) — samme mål = samme sigar. Hvis ingen kandidat helt klart er samme sigar, returner null for den linja.

Returner KUN JSON, ingen annen tekst:
{ "picks": [ { "i": 0, "choice": 2 }, { "i": 1, "choice": null } ] }
der "i" er linje-indeksen (tallet i klammer) og "choice" er kandidatnummeret (1-basert) eller null.

Linjer:
${block}`;

  const data = await callOpenAI(apiKey, [{ type: "text", text: prompt }], 1500);
  const content: string = data.choices?.[0]?.message?.content ?? "{}";
  const obj = safeJSON(content);
  const picks = Array.isArray(obj?.picks) ? obj.picks : [];
  for (const p of picks) {
    const i = Number((p as { i: unknown }).i);
    const choice = (p as { choice: unknown }).choice;
    if (!Number.isInteger(i) || i < 0 || i >= items.length) continue;
    if (choice == null) { result[i] = null; continue; }
    const ci = Number(choice) - 1; // 1-basert -> 0-basert
    if (Number.isInteger(ci) && ci >= 0 && ci < items[i].candidates.length) {
      result[i] = ci;
    }
  }
  return result;
}

async function callOpenAI(
  apiKey: string,
  content: unknown,
  maxTokens: number,
): Promise<{ choices?: { message?: { content?: string } }[] }> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30_000);
  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      signal: controller.signal,
      method: "POST",
      headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "gpt-5-mini",
        messages: [{ role: "user", content }],
        reasoning_effort: "minimal",
        max_completion_tokens: maxTokens,
      }),
    });
  } catch (e) {
    clearTimeout(timeoutId);
    if (e instanceof Error && e.name === "AbortError") throw new Error("OpenAI-kall tidsavbrutt etter 30s");
    throw e;
  }
  clearTimeout(timeoutId);
  if (!response.ok) throw new Error(`OpenAI-feil (${response.status}): ${await response.text()}`);
  return await response.json();
}

function safeJSON(raw: string): any {
  const cleaned = raw.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
  try { return JSON.parse(cleaned); } catch { return null; }
}
