// log-card/index.ts
// Genererer et offentlig delbart HTML-kort for en røykelog.
// URL: /functions/v1/log-card?id={tasting_log_uuid}
// Brukes til deling på Facebook/Instagram via copy-URL i appen.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const logId = url.searchParams.get("id");

  if (!logId) {
    return new Response("Missing ?id=", { status: 400 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  // Hent logg + sigar-info
  const { data: log, error } = await supabase
    .from("tasting_logs")
    .select("*, cigars(brand, series, vitola, flavor_notes)")
    .eq("id", logId)
    .single();

  if (error || !log) {
    return new Response("Log not found", { status: 404 });
  }

  const cigar = log.cigars;
  const brand = cigar?.brand ?? "Ukjent sigar";
  const series = cigar?.series ?? "";
  const vitola = cigar?.vitola ?? "";
  const rating = log.rating;
  const photoUrl = log.photo_url ?? "";

  // Score-label
  const scoreLabel = (r: number) => {
    if (r >= 95) return "Exceptional";
    if (r >= 90) return "Excellent";
    if (r >= 85) return "Very good";
    if (r >= 80) return "Good";
    if (r >= 70) return "Average";
    return "Not for me";
  };

  // Dato
  const smokedDate = new Date(log.smoked_at).toLocaleDateString("nb-NO", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });

  const title = `${brand}${series ? ` ${series}` : ""}${vitola ? ` · ${vitola}` : ""}`;
  const scoreText = rating ? `${rating} · ${scoreLabel(rating)}` : "";
  const description = [scoreText, `Røkt ${smokedDate}`].filter(Boolean).join(" — ");
  const ogImage = photoUrl || "https://wpcricosogcmzebkplwp.supabase.co/storage/v1/object/public/log-photos/og-fallback.jpg";

  // Score-farge
  const scoreColor = (r: number) => {
    if (r >= 90) return "#C9A227";
    if (r >= 80) return "#A07010";
    if (r >= 70) return "#888888";
    return "#7A4A30";
  };

  const color = rating ? scoreColor(rating) : "#888888";

  const html = `<!DOCTYPE html>
<html lang="no">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${title}</title>

  <!-- Facebook / Open Graph -->
  <meta property="og:type" content="article"/>
  <meta property="og:title" content="${title}"/>
  <meta property="og:description" content="${description}"/>
  ${photoUrl ? `<meta property="og:image" content="${photoUrl}"/>` : ""}
  <meta property="og:url" content="${req.url}"/>
  <meta property="og:site_name" content="Vitola"/>

  <!-- Twitter Card -->
  <meta name="twitter:card" content="${photoUrl ? "summary_large_image" : "summary"}"/>
  <meta name="twitter:title" content="${title}"/>
  <meta name="twitter:description" content="${description}"/>
  ${photoUrl ? `<meta name="twitter:image" content="${photoUrl}"/>` : ""}

  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #1a1208;
      color: #f5ead8;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      background: #251c0e;
      border-radius: 20px;
      max-width: 480px;
      width: 100%;
      overflow: hidden;
      box-shadow: 0 8px 40px rgba(0,0,0,0.6);
    }
    .photo {
      width: 100%;
      height: 260px;
      object-fit: cover;
    }
    .body {
      padding: 24px;
    }
    .brand {
      font-size: 22px;
      font-weight: 700;
      line-height: 1.2;
    }
    .series {
      font-size: 15px;
      color: #c8b090;
      margin-top: 4px;
    }
    .vitola {
      font-size: 13px;
      color: #9a836a;
      margin-top: 2px;
    }
    .score-chip {
      display: inline-block;
      margin-top: 16px;
      padding: 6px 14px;
      border-radius: 999px;
      font-size: 15px;
      font-weight: 600;
      background: ${color}22;
      color: ${color};
      border: 1px solid ${color}55;
    }
    .date {
      margin-top: 14px;
      font-size: 13px;
      color: #9a836a;
    }
    .footer {
      margin-top: 20px;
      padding-top: 16px;
      border-top: 1px solid #3a2e1e;
      font-size: 12px;
      color: #6a5840;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .leaf { font-size: 16px; }
  </style>
</head>
<body>
  <div class="card">
    ${photoUrl ? `<img class="photo" src="${photoUrl}" alt="${title}"/>` : ""}
    <div class="body">
      <div class="brand">${brand}</div>
      ${series ? `<div class="series">${series}</div>` : ""}
      ${vitola ? `<div class="vitola">${vitola}</div>` : ""}
      ${rating ? `<div class="score-chip">${rating} · ${scoreLabel(rating)}</div>` : ""}
      <div class="date">Røkt ${smokedDate}</div>
      <div class="footer">
        <span class="leaf">🍃</span>
        <span>Vitola — sigarjournalen din</span>
      </div>
    </div>
  </div>
</body>
</html>`;

  return new Response(html, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "public, max-age=300",
    },
  });
});
