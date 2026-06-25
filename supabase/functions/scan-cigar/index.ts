// supabase/functions/scan-cigar/index.ts
// Edge Function: AI-fallback for sigar-identifikasjon via GPT-4o Vision
// Kalles fra appen når Apple Vision OCR + databasesøk ikke finner treff.
// OpenAI-nøkkelen ligger kun her server-side — aldri i appen.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ScanRequest {
  image: string; // base64-encoded JPEG — sigarbåndet (mode "identify") eller hele sigaren (mode "shape"/"wrapper")
  ocr_text?: string; // tekst funnet av Apple Vision (kan være tom)
  // "identify" (default) = gjett merke/serie fra båndet, slå opp i databasen.
  // "shape" = klassifiser den fysiske formen (body/head/foot-type) fra et bilde
  // av hele sigaren — brukes til å avklare når flere størrelser deler samme bånd.
  // "wrapper" = klassifiser KUN wrapper-fargen fra et bilde av hele sigaren —
  // brukes til å avklare når samme bånd/serie finnes i flere wrapper-varianter
  // (Connecticut/Maduro/Sun Grown/...). Båndet alene viser ofte ikke dette,
  // siden wrapper-fargen sitter på selve sigaren, ikke båndet.
  mode?: "identify" | "shape" | "wrapper";
}

interface AIGuess {
  brand: string;
  series?: string | null;
  // Wrapper-typen (Connecticut/Maduro/Habano/Sun Grown/...) — mange serier
  // finnes i flere wrapper-varianter med IDENTISK serienavn på båndet, så
  // serien alene er ofte ikke nok til å peke ut riktig rad i databasen.
  wrapper?: string | null;
  confidence: number; // 0.0–1.0
  reason: string;
}

interface AICigarMatch {
  cigar_id: string;
  confidence: number;
  reason: string;
  // true når båndet/AI-en eksplisitt pekte ut nøyaktig denne serien —
  // appen kan da velge denne automatisk i stedet for å vise en liste.
  exact_match: boolean;
}

interface ShapeGuess {
  body_type: string;
  head_type: string;
  foot_type: string;
  confidence: number;
  reason: string;
}

interface WrapperColorGuess {
  // Wrapper-typen sett på SELVE sigaren (ikke båndet) — eller null hvis
  // bildet ikke viser nok av sigarkroppen til å avgjøre det.
  wrapper: string | null;
  confidence: number;
  reason: string;
}

// MARK: - Wrapper-gjenkjenning (robust mot at GPT-4o ikke følger skjemaet)
// I praksis legger GPT-4o noen ganger wrapper-typen INN i "series"-feltet
// (f.eks. series: "Vintage 1999 Connecticut") i stedet for det egne
// "wrapper"-feltet, eller utelater "wrapper" helt selv når den faktisk så
// ordet på båndet. Vi kan ikke stole 100% på at AI-en sorterer riktig felt,
// så vi leter etter kjente wrapper-typer i ALL tekst AI-en ga oss (series +
// wrapper + reason) som en sikkerhetsnett, sortert lengste-først så
// "Connecticut Shade" matches før "Connecticut".
const KNOWN_WRAPPER_TYPES = [
  "Connecticut Shade",
  "Connecticut",
  "Sun Grown",
  "Sungrown",
  "Habano",
  "Maduro",
  "Corojo",
  "Cameroon",
  "Natural",
];

function extractWrapperKeyword(text: string | null | undefined): string | null {
  if (!text) return null;
  const lower = text.toLowerCase();
  for (const type of KNOWN_WRAPPER_TYPES) {
    if (lower.includes(type.toLowerCase())) return type;
  }
  return null;
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { image, ocr_text, mode }: ScanRequest = await req.json();

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

    // Mode "shape": brukes når samme bånd matcher flere størrelser/former av
    // samme serie i databasen. Appen ber da om ett ekstra bilde av HELE
    // sigaren, og vi klassifiserer formen i stedet for å gjette merke/serie.
    // Ingen DB-oppslag her — appen matcher selv det returnerte body_type mot
    // kandidatlisten den allerede har.
    if (mode === "shape") {
      const shape = await classifyShapeWithGPT4o(image, openaiKey);
      console.log(
        `scan-cigar (shape): body=${shape.body_type} head=${shape.head_type} foot=${shape.foot_type} (${shape.confidence})`,
      );
      return new Response(JSON.stringify(shape), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Mode "wrapper": brukes når samme bånd/serie matcher flere rader som KUN
    // skiller seg på wrapper-typen (f.eks. "Vintage 1999" i Connecticut vs.
    // Maduro). Båndet alene viser sjelden wrapper-fargen tydelig — det er
    // fargen på selve sigarkroppen som avgjør — så appen ber om ett ekstra
    // bilde av HELE sigaren, akkurat som for "shape".
    if (mode === "wrapper") {
      const wrapperGuess = await classifyWrapperWithGPT4o(image, openaiKey);
      console.log(
        `scan-cigar (wrapper): wrapper=${wrapperGuess.wrapper ?? "null"} (${wrapperGuess.confidence})`,
      );
      return new Response(JSON.stringify(wrapperGuess), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Steg 1: Spør GPT-4o Vision om hva den ser på sigarbåndet
    const guesses = await identifyWithGPT4o(image, ocr_text ?? "", openaiKey);

    console.log(
      `scan-cigar: GPT-4o gjettet ${guesses.length} kandidat(er): ` +
        guesses
          .map((g) => `${g.brand}${g.series ? ` / ${g.series}` : ""} (${g.confidence})`)
          .join(", "),
    );

    // Steg 2: Koble AI-gjetningene mot ekte rader i "cigars"-tabellen
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Vi henter ALLE varianter/serier av merket AI-en gjettet på — ikke
    // bare den ene serien AI-en var mest sikker på. Det gjør at brukeren
    // får velge mellom f.eks. alle Ashton-seriene i appen, i stedet for
    // å bli "gjettet for" på nøyaktig hvilken Ashton det er.
    const matches: AICigarMatch[] = [];
    const seenCigarIds = new Set<string>();

    for (const guess of guesses) {
      // VIKTIG: .limit(15) var hovedbuggen bak "My Father Blue fant ikke
      // treff"-saken. Noen merker (Padron: 102 rader, Arturo Fuente: 85,
      // Ashton: 70, My Father: 48) har langt flere rader enn 15, og uten
      // noen ORDER BY var det helt vilkårlig hvilke 15 rader Postgres
      // returnerte — serien AI-en faktisk gjettet på (f.eks. "Blue") kunne
      // falle utenfor de 15 og dermed ALDRI bli vurdert som kandidat, selv
      // om AI-en var 90% sikker. 300 gir solid margin over det største
      // merket i databasen i dag (Padron, 102) for fremtidig vekst.
      let { data, error } = await supabase
        .from("cigars")
        .select("id, series, wrapper_leaf")
        .ilike("brand", `%${guess.brand}%`)
        .limit(300);

      // Alias-fallback: hvis AI-en returnerte et initialforkortelse (f.eks. "VF"
      // istedenfor "Vega Fina"), vil ILIKE mot brand gi null treff. Da slår vi
      // opp i cigar_aliases-tabellen for å finne det ekte merkenavnet og prøver igjen.
      if (!error && (!data || data.length === 0)) {
        const { data: aliasRows } = await supabase
          .from("cigar_aliases")
          .select("brand")
          .ilike("alias", guess.brand)
          .limit(1);

        if (aliasRows && aliasRows.length > 0) {
          const realBrand = aliasRows[0].brand;
          const retry = await supabase
            .from("cigars")
            .select("id, series, wrapper_leaf")
            .eq("brand", realBrand)
            .limit(300);
          data = retry.data;
          error = retry.error;
          console.log(`scan-cigar: alias-fallback "${guess.brand}" → "${realBrand}" (${data?.length ?? 0} rader)`);
        }
      }

      if (error || !data) continue;

      // GPT-4o er ikke alltid konsekvent med HVOR den putter wrapper-typen —
      // noen ganger henger den seg på "series" (f.eks. "Vintage 1999
      // Connecticut") i stedet for det egne "wrapper"-feltet. Vi leter derfor
      // etter en kjent wrapper-type i ALT AI-en sa (wrapper-feltet, men også
      // series og reason som fallback) i stedet for å stole blindt på at
      // "wrapper" ble fylt ut riktig.
      const effectiveWrapper = guess.wrapper ??
        extractWrapperKeyword(guess.series) ??
        extractWrapperKeyword(guess.reason);

      // Siden "series" fra AI-en noen ganger har wrapper-typen hengende på
      // slutten ("Vintage 1999 Connecticut"), kan ikke seriematch kreve at
      // raden sin rene series-tekst inneholder HELE AI-gjetningen. Vi sjekker
      // begge veier: stemmer det uansett hvem som er "lengst"?
      const seriesTextMatches = (a: string, b: string) => {
        const x = a.toLowerCase();
        const y = b.toLowerCase();
        return x.includes(y) || y.includes(x);
      };

      // Mange serier (f.eks. "Vintage 1999") finnes i flere wrapper-
      // varianter (Connecticut/Maduro/Sun Grown) med identisk serienavn.
      // Hvis serien AI-en gjettet på finnes i FLERE ULIKE WRAPPER-TYPER,
      // er serien alene IKKE nok til å si "eksakt treff" — da må wrapper-
      // typen også stemme. Men hvis 16 rader deler serienavn fordi de er
      // ulike vitolae (Robusto/Churchill/Toro) av SAMME wrapper, er det
      // IKKE tvetydighet — det er bare størrelsesvarianter av samme sigar.
      const rowsMatchingGuessedSeries = guess.series
        ? data.filter((row) => row.series && seriesTextMatches(row.series, guess.series!))
        : [];

      for (const row of data) {
        if (seenCigarIds.has(row.id)) continue;
        seenCigarIds.add(row.id);

        const seriesMatchesGuess = !!(
          guess.series &&
          row.series &&
          seriesTextMatches(row.series, guess.series)
        );

        const wrapperMatchesGuess = !!(
          effectiveWrapper &&
          row.wrapper_leaf &&
          row.wrapper_leaf.toLowerCase().includes(effectiveWrapper.toLowerCase())
        );

        // Serien er unik nok i seg selv hvis alle rader som matcher serien
        // deler SAMME wrapper-type (f.eks. 16 Classic-vitolae, alle Connecticut).
        // Kun hvis serien finnes i FLERE ULIKE wrapper-varianter (f.eks. Vintage
        // 1999 i Connecticut OG Maduro) er det reell tvetydighet — da krever vi
        // at wrapper-typen også stemmer for å kalle det eksakt treff.
        const distinctWrappersInMatchedSeries = new Set(
          rowsMatchingGuessedSeries.map((r) => (r.wrapper_leaf ?? "").toLowerCase().trim()),
        ).size;
        const seriesIsUnambiguous = rowsMatchingGuessedSeries.length === 0 ||
          distinctWrappersInMatchedSeries <= 1;
        const isExactMatch = seriesMatchesGuess &&
          (seriesIsUnambiguous || wrapperMatchesGuess);

        matches.push({
          cigar_id: row.id,
          // Serien AI-en faktisk gjettet på får full konfidens. Andre
          // serier av samme merke får lavere, men fortsatt synlig
          // konfidens — de er reelle kandidater, ikke bare gjetning.
          confidence: isExactMatch
            ? guess.confidence
            : seriesMatchesGuess
            ? Math.max(guess.confidence - 0.15, 0.4) // riktig serie, usikker wrapper
            : Math.max(guess.confidence - 0.35, 0.3),
          reason: isExactMatch
            ? guess.reason
            : seriesMatchesGuess
            ? `${guess.reason} (usikker på akkurat denne wrapper-varianten)`
            : `Samme merke (${guess.brand}) som ble identifisert på bildet`,
          // Eksakt treff kun når serien matcher OG (serien er unik for denne
          // raden ELLER wrapper-typen også stemmer) — se kommentar over.
          exact_match: isExactMatch,
        });
      }
    }

    // Beste treff først, og ikke overvelde brukeren med for mange valg
    matches.sort((a, b) => b.confidence - a.confidence);
    const topMatches = matches.slice(0, 12);

    console.log(
      `scan-cigar: fant ${matches.length} totale treff, returnerer topp ${topMatches.length}. ` +
        `Eksakte treff: ${topMatches.filter((m) => m.exact_match).length}.`,
    );

    return new Response(JSON.stringify(topMatches), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("scan-cigar feilet:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Ukjent feil" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

// MARK: - GPT-4o Vision-kall
async function identifyWithGPT4o(
  base64Image: string,
  ocrText: string,
  apiKey: string,
): Promise<AIGuess[]> {
  const prompt = `Du er ekspert på sigarer. Se på bildet av sigarbåndet og identifiser merket (brand), eventuelt serien (series), og wrapper-typen (wrapper).
${
    ocrText
      ? `Apple Vision OCR fant denne teksten på båndet: "${ocrText}" — bruk dette som et hint, men stol mest på bildet.`
      : ""
  }

Mange serier (f.eks. "Vintage 1999") finnes i flere wrapper-varianter med
IDENTISK serienavn på båndet — da er det ofte wrapper-fargen på selve
sigaren (ikke båndet) som avgjør hvilken variant det er. Se derfor også på
fargen til innpakningsbladet (wrapper leaf) på selve sigaren hvis den er
synlig i bildet, og bruk denne tommelfingerregelen:
- Connecticut/Connecticut Shade: lys, gyllenbrun, nesten gulaktig
- Natural/Habano: middels brun
- Maduro: mørk sjokoladebrun til nesten svart
- Sun Grown/Corojo: rødlig-brun
Sett "wrapper" til ditt beste gjetning på wrapper-typen (f.eks. "Connecticut",
"Maduro"), eller null hvis du ikke kan se sigarens overflate eller er usikker.

VIKTIG: "series" skal KUN være serienavnet (f.eks. "Vintage 1999") — ALDRI med
wrapper-typen hengende på slutten (IKKE "Vintage 1999 Connecticut"). Wrapper-
typen hører KUN i "wrapper"-feltet, aldri i "series".

NB: For La Aurora betyr teksten "CAMEROON" på båndet serien "1903 Cameroon"
— sett series="1903 Cameroon" OG wrapper="Cameroon" i det tilfellet.

NB: Logoen "VF" (bokstavene V og F i en sirkel med laurbærkrans) = merket "Vega Fina".
Sett brand="Vega Fina" — ALDRI bare "VF".

Svar med en liste av 1-3 kandidater, sortert fra mest til minst sannsynlig. Returner KUN gyldig JSON i dette formatet, ingen annen tekst:
[
  { "brand": "string", "series": "string eller null", "wrapper": "string eller null", "confidence": 0.0-1.0, "reason": "kort forklaring på norsk" }
]`;

  // 25-sekunders hard timeout på OpenAI-kallet — forhindrer at appen
  // henger ubestemt hvis OpenAI er treg eller utilgjengelig.
  const controller = new AbortController();
  const timeoutId = setTimeout(() => {
    console.warn("identifyWithGPT4o: 25s timeout — avbryter OpenAI-kall");
    controller.abort();
  }, 25_000);

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
        // GPT-5-modellene feiler hvis du sender "max_tokens" — heter
        // "max_completion_tokens" nå. Reasoning-modeller bruker også usynlige
        // "reasoning tokens" som telles MOT dette budsjettet — for en enkel
        // klassifiseringsoppgave som denne vil "minimal" reasoning_effort
        // sørge for at budsjettet faktisk går til selve JSON-svaret i stedet
        // for intern tankegang (uten dette kunne content komme tom tilbake).
        reasoning_effort: "minimal",
        max_completion_tokens: 1500,
      }),
    });
  } catch (e) {
    clearTimeout(timeoutId);
    if (e instanceof Error && e.name === "AbortError") {
      console.warn("identifyWithGPT4o: returnerer [] etter timeout");
      return [];
    }
    throw e;
  }
  clearTimeout(timeoutId);

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`OpenAI-feil (${response.status}): ${errText}`);
  }

  const data = await response.json();
  const content: string = data.choices?.[0]?.message?.content ?? "[]";
  const finishReason: string = data.choices?.[0]?.finish_reason ?? "ukjent";

  // GPT-4o kan noen ganger pakke JSON i ```json ... ``` — fjern det
  const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

  try {
    return JSON.parse(cleaned);
  } catch {
    console.error(
      `Kunne ikke parse GPT-4o-respons (finish_reason=${finishReason}):`,
      content,
    );
    return [];
  }
}

// MARK: - Form-klassifisering (mode "shape")
// Samme taksonomi som migrations/027_backfill_body_head_foot_type.sql, slik at
// body_type-verdien GPT-4o gjetter alltid kan matches direkte mot cigars-tabellen.
async function classifyShapeWithGPT4o(
  base64Image: string,
  apiKey: string,
): Promise<ShapeGuess> {
  const prompt = `Du er ekspert på sigarer. Se på bildet av HELE sigaren (ikke bare båndet) og klassifiser den fysiske formen.

Velg body_type fra NØYAKTIG én av disse verdiene: Parejo, Box-Pressed, Torpedo, Torpedo Box-Pressed, Belicoso, Pyramid, Perfecto, Salomon, Diadema, Chisel, Culebra.
Velg head_type fra: Round, Pointed, Wedge.
Velg foot_type fra: Open, Closed, Tapered.

Huskeregel: "head" er den lukkede/smale enden som klippes før røyking, "foot" er den åpne enden som tennes. En vanlig rett sigar (f.eks. Robusto, Toro, Churchill, Corona) er Parejo med Round head og Open foot — bruk dette som standardgjetning hvis du er usikker.

Returner KUN gyldig JSON i dette formatet, ingen annen tekst:
{ "body_type": "string", "head_type": "string", "foot_type": "string", "confidence": 0.0-1.0, "reason": "kort forklaring på norsk" }`;

  const controller2 = new AbortController();
  const timeoutId2 = setTimeout(() => {
    console.warn("classifyShapeWithGPT4o: 25s timeout — avbryter OpenAI-kall");
    controller2.abort();
  }, 25_000);

  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      signal: controller2.signal,
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
        max_completion_tokens: 1000,
      }),
    });
  } catch (e) {
    clearTimeout(timeoutId2);
    if (e instanceof Error && e.name === "AbortError") {
      throw new Error("Form-klassifisering tidsavbrutt etter 25s");
    }
    throw e;
  }
  clearTimeout(timeoutId2);

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`OpenAI-feil (${response.status}): ${errText}`);
  }

  const data = await response.json();
  const content: string = data.choices?.[0]?.message?.content ?? "{}";
  const finishReason: string = data.choices?.[0]?.finish_reason ?? "ukjent";
  const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

  try {
    return JSON.parse(cleaned);
  } catch {
    console.error(`Kunne ikke parse form-respons (finish_reason=${finishReason}):`, content);
    throw new Error("Kunne ikke tolke form-responsen fra GPT-4o");
  }
}

// MARK: - Wrapper-klassifisering (mode "wrapper")
// Brukes når samme bånd/serie matcher flere rader i databasen som KUN
// skiller seg på wrapper-typen (f.eks. "Vintage 1999" finnes i både
// Connecticut og Maduro). Båndet i seg selv viser sjelden wrapper-fargen
// tydelig nok — fargen sitter på selve sigarkroppen — så dette bildet er
// av HELE sigaren, ikke båndet, akkurat som "shape"-mode.
async function classifyWrapperWithGPT4o(
  base64Image: string,
  apiKey: string,
): Promise<WrapperColorGuess> {
  const prompt = `Du er ekspert på sigarer. Se på bildet av HELE sigaren (ikke bare båndet) og vurder fargen/typen på innpakningsbladet (wrapper leaf).

Velg wrapper fra NØYAKTIG én av disse verdiene hvis du klarer å se det tydelig: Connecticut, Maduro, Habano, Sun Grown, Natural, Cameroon, Corojo, Candela, Oscuro.

Hvis bildet ikke viser nok av sigarkroppen til å avgjøre fargen tydelig (for mørkt, for tett beskåret, kun båndet synlig, osv.), sett "wrapper" til null i stedet for å gjette.

Returner KUN gyldig JSON i dette formatet, ingen annen tekst:
{ "wrapper": "string eller null", "confidence": 0.0-1.0, "reason": "kort forklaring på norsk" }`;

  const controller3 = new AbortController();
  const timeoutId3 = setTimeout(() => {
    console.warn("classifyWrapperWithGPT4o: 25s timeout — avbryter OpenAI-kall");
    controller3.abort();
  }, 25_000);

  let response: Response;
  try {
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      signal: controller3.signal,
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
        max_completion_tokens: 1000,
      }),
    });
  } catch (e) {
    clearTimeout(timeoutId3);
    if (e instanceof Error && e.name === "AbortError") {
      throw new Error("Wrapper-klassifisering tidsavbrutt etter 25s");
    }
    throw e;
  }
  clearTimeout(timeoutId3);

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`OpenAI-feil (${response.status}): ${errText}`);
  }

  const data = await response.json();
  const content: string = data.choices?.[0]?.message?.content ?? "{}";
  const finishReason: string = data.choices?.[0]?.finish_reason ?? "ukjent";
  const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

  try {
    return JSON.parse(cleaned);
  } catch {
    console.error(`Kunne ikke parse wrapper-respons (finish_reason=${finishReason}):`, content);
    throw new Error("Kunne ikke tolke wrapper-responsen fra GPT-4o");
  }
}
