// /api/prime?slug=<slug>
// «Primer» Facebooks cache for en delings-lenke — samme som å kjøre URL-en i
// Facebook Sharing Debugger, bare automatisk i bakgrunnen. Appen kaller dette
// idet en ekstern delings-lenke lages, slik at Facebook har Open Graph-kortet
// klart FØR brukeren limer inn lenken (FB-appen henter det ikke selv ved liming).
//
// Krever en Facebook App-token i env: FB_APP_TOKEN = "<app-id>|<app-secret>".
// App-secret ligger KUN her server-side (Vercel env), aldri i klient-appen.

const BASE = "https://seder-app-pearl.vercel.app";

module.exports = async (req, res) => {
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");

  const slug = (req.query && req.query.slug ? String(req.query.slug) : "").trim();
  if (!slug) {
    res.statusCode = 400;
    res.end(JSON.stringify({ ok: false, error: "missing slug" }));
    return;
  }

  const token = process.env.FB_APP_TOKEN;
  if (!token) {
    // Ikke satt opp ennå — svar pent så app-flyten ikke feiler.
    res.statusCode = 200;
    res.end(JSON.stringify({ ok: false, error: "FB_APP_TOKEN not configured" }));
    return;
  }

  const shareUrl = `${BASE}/j/${encodeURIComponent(slug)}`;
  const endpoint = `https://graph.facebook.com/v19.0/?id=${encodeURIComponent(shareUrl)}&scrape=true&access_token=${encodeURIComponent(token)}`;

  try {
    const r = await fetch(endpoint, { method: "POST" });
    const data = await r.json().catch(() => ({}));
    res.statusCode = 200;
    res.end(JSON.stringify({ ok: r.ok, fb: data && data.id ? "scraped" : data }));
  } catch (e) {
    res.statusCode = 200;
    res.end(JSON.stringify({ ok: false, error: String(e) }));
  }
};
