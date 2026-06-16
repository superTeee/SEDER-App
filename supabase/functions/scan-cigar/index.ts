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
  image: string; // base64-encoded JPEG
  ocr_text?: string; // tekst funnet av Apple Vision (kan være tom)
}

interface AIGuess {
  brand: string;
  series?: string | null;
  confidence: number; // 0.0–1.0
  reason: string;
}

interface AICigarMatch {
  cigar_id: string;
  confidence: number;
  reason: string;
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { image, ocr_text }: ScanRequest = await req.json();

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

    // Steg 1: Spør GPT-4o Vision om hva den ser på sigarbåndet
    const guesses = await identifyWithGPT4o(image, ocr_text ?? "", openaiKey);

    // Steg 2: Koble AI-gjetningene mot ekte rader i "cigars"-tabellen
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const matches: AICigarMatch[] = [];

    for (const guess of guesses) {
      let query = supabase
        .from("cigars")
        .select("id")
        .ilike("brand", `%${guess.brand}%`);

      if (guess.series) {
        query = query.ilike("series", `%${guess.series}%`);
      }

      const { data, error } = await query.limit(1);

      if (!error && data && data.length > 0) {
        matches.push({
          cigar_id: data[0].id,
          confidence: guess.confidence,
          reason: guess.reason,
        });
      }
    }

    return new Response(JSON.stringify(matches), {
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
  const prompt = `Du er ekspert på sigarer. Se på bildet av sigarbåndet og identifiser merket (brand) og eventuelt serien (series).
${
    ocrText
      ? `Apple Vision OCR fant denne teksten på båndet: "${ocrText}" — bruk dette som et hint, men stol mest på bildet.`
      : ""
  }

Svar med en liste av 1-3 kandidater, sortert fra mest til minst sannsynlig. Returner KUN gyldig JSON i dette formatet, ingen annen tekst:
[
  { "brand": "string", "series": "string eller null", "confidence": 0.0-1.0, "reason": "kort forklaring på norsk" }
]`;

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            { type: "image_url", image_url: { url: `data:image/jpeg;base64,${base64Image}` } },
          ],
        },
      ],
      max_tokens: 500,
      temperature: 0.2,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`OpenAI-feil (${response.status}): ${errText}`);
  }

  const data = await response.json();
  const content: string = data.choices?.[0]?.message?.content ?? "[]";

  // GPT-4o kan noen ganger pakke JSON i ```json ... ``` — fjern det
  const cleaned = content.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

  try {
    return JSON.parse(cleaned);
  } catch {
    console.error("Kunne ikke parse GPT-4o-respons:", content);
    return [];
  }
}
