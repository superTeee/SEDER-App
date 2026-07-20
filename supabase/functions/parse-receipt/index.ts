// supabase/functions/parse-receipt/index.ts
// Edge Function: les en sigarbutikk-kvittering med GPT-vision, hent ut
// varelinjer {navn, antall, enhetspris}, og match hver mot sigar-databasen
// via match_cigar-RPC. Returnerer treff + ikke-funnet, slik at appen kan
// legge alt i humidoren med bekreftelse.
//
// OpenAI-nøkkelen ligger kun her server-side — aldri i appen.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ReceiptRequest {
  image: string;
}

// Én rå varelinje slik GPT leser den fra kvitteringen.
interface ReceiptLine {
  name: string;
  quantity: number;
  unit_price: number | null;
}

// Et treff mot sigar-databasen (matched line).
interface MatchedLine {
  cigar_id: string;
  brand: string;
  series: string | null;
  vitola: string | null;
  receipt_name: string; // hva som faktisk sto på kvitteringen
  quantity: number;
  unit_price: number | null;
  score: number;
}

// Terskel for å regne en varelinje som et sikkert nok treff. Under dette
// havner linja i "unmatched" og brukeren håndterer den manuelt.
const MATCH_THRESHOLD = 0.45;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { image }: ReceiptRequest = await req.json();

    if (!image) {
      return new Response(
        JSON.stringify({ error: "Mangler 'image' i forespørselen" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) {
      throw new Error("OPENAI_API_KEY er ikke satt som secret i Supabase");
    }

    const parsed = await readReceiptWithGPT(image, openaiKey);
    console.log(
      `parse-receipt: butikk=${parsed.store ?? "?"}, ${parsed.lines.length} varelinje(r): ` +
        parsed.lines.map((l) => `${l.name} ×${l.quantity}`).join(", "),
    );

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const matched: MatchedLine[] = [];
    const unmatched: ReceiptLine[] = [];

    for (const line of parsed.lines) {
      const query = (line.name ?? "").trim();
      if (!query) continue;

      const { data, error } = await supabase.rpc("match_cigar", {
        p_query: query,
        p_limit: 3,
      });

      const rows = (data ?? []) as Array<
        { id: string; brand: string; series: string; vitola: string; score: number }
      >;
      const best = !error && rows.length > 0 ? rows[0] : null;

      if (best && best.score >= MATCH_THRESHOLD) {
        matched.push({
          cigar_id: best.id,
          brand: best.brand,
          series: best.series,
          vitola: best.vitola,
          receipt_name: query,
          quantity: line.quantity > 0 ? line.quantity : 1,
          unit_price: line.unit_price,
          score: Math.min(best.score, 1),
        });
      } else {
        unmatched.push({
          name: query,
          quantity: line.quantity > 0 ? line.quantity : 1,
          unit_price: line.unit_price,
        });
      }
    }

    console.log(
      `parse-receipt: ${matched.length} treff, ${unmatched.length} ikke funnet.`,
    );

    return new Response(
      JSON.stringify({ store: parsed.store, matched, unmatched }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("parse-receipt feilet:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Ukjent feil" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

interface ParsedReceipt {
  store: string | null;
  lines: ReceiptLine[];
}

async function readReceiptWithGPT(
  base64Image: string,
  apiKey: string,
): Promise<ParsedReceipt> {
  const prompt =
    `Du er ekspert på sigarer og leser en kvittering fra en sigarbutikk (kan være på norsk, engelsk, spansk eller tysk).

Hent ut KUN varelinjene som er sigarer. Ignorer tilbehør (tennere, kuttere, askebegre, etuier), rabatter, moms, totalsum, bonuspoeng og betalingsinfo.

For hver sigar-varelinje:
- "name": produktnavnet så komplett som mulig (merke + serie + eventuell vitola/størrelse), akkurat slik det står på kvitteringen. Rett åpenbare OCR-feil hvis du er sikker.
- "quantity": antall sigarer på linja (heltall, minst 1). Kvitteringer skriver ofte "2 x", "2 stk", eller antall i egen kolonne.
- "unit_price": prisen for ÉN sigar som et tall (ingen valutategn). Hvis kvitteringen bare viser linjens totalsum, regn ut totalsum / antall. Sett null hvis prisen ikke er lesbar.

Prøv også å hente butikkens navn i "store" (øverst på kvitteringen), eller null.

Returner KUN gyldig JSON i dette formatet, ingen annen tekst:
{
  "store": "string eller null",
  "lines": [
    { "name": "string", "quantity": 1, "unit_price": 0.0 }
  ]
}
Hvis du ikke finner noen sigar-linjer, returner { "store": null, "lines": [] }.`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => {
    console.warn("readReceiptWithGPT: 30s timeout — avbryter OpenAI-kall");
    controller.abort();
  }, 30_000);

  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      signal: controller.signal,
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-5-mini",
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Image}` } },
            ],
          },
        ],
        reasoning_effort: "minimal",
        max_completion_tokens: 2000,
      }),
    });
  } catch (e) {
    clearTimeout(timeoutId);
    if (e instanceof Error && e.name === "AbortError") {
      throw new Error("Kvittering-lesing tidsavbrutt etter 30s");
    }
    throw e;
  }
  clearTimeout(timeoutId);

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`OpenAI-feil (${response.status}): ${errText}`);
  }

  const data = await response.json();
  const content: string = data.choices?.[0]?.message?.content ?? "{}";
  const finishReason: string = data.choices?.[0]?.finish_reason ?? "ukjent";
  const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

  try {
    const obj = JSON.parse(cleaned);
    const lines: ReceiptLine[] = Array.isArray(obj.lines)
      ? obj.lines
          .filter((l: unknown) => l && typeof (l as ReceiptLine).name === "string")
          .map((l: ReceiptLine) => ({
            name: String(l.name).trim(),
            quantity: Number.isFinite(l.quantity) && l.quantity > 0 ? Math.round(l.quantity) : 1,
            unit_price: typeof l.unit_price === "number" && Number.isFinite(l.unit_price)
              ? l.unit_price
              : null,
          }))
      : [];
    return { store: typeof obj.store === "string" ? obj.store : null, lines };
  } catch {
    console.error(`Kunne ikke parse kvittering-respons (finish_reason=${finishReason}):`, content);
    return { store: null, lines: [] };
  }
}
