// sederappen.no/j/<slug> — offentlig side for et delt journalinnlegg.
// Serverless-funksjon (Vercel). Serveres som EKTE text/html (i motsetning til
// Supabase-funksjons-domenet som tvinger text/plain), med Open Graph-tagger
// for pent delings-kort på Facebook/sosiale medier.
//
// Leser kun trygge visningsfelt via get_public_journal_entry (SECURITY DEFINER,
// kun delte oppføringer). Anon-nøkkelen er trygg i kildekode (Supabase-praksis).

const FB_APP_ID = "1524715886334745"; // SEDER Facebook-app (ikke hemmelig; kun app-secret er hemmelig)
const SUPABASE_URL = "https://wpcricosogcmzebkplwp.supabase.co";
const ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwY3JpY29zb2djbXplYmtwbHdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1NjE0OTQsImV4cCI6MjA5NzEzNzQ5NH0.wdTDMuY1EzZFkoFdLP-HKx-Jx_cfT1OlPjMpet9gL44";
const APP_STORE_URL = "/"; // landingssiden på samme domene

function esc(s) {
  return (s == null ? "" : String(s)).replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

function ratingStars(r) {
  if (!r) return "";
  const v = r / 20;
  let out = "";
  for (let i = 0; i < 5; i++) out += (v - i >= 1) ? "★" : (v - i >= 0.5 ? "½" : "☆");
  return out;
}

function page(body, meta) {
  const og = `
<meta property="og:type" content="website">
<meta property="fb:app_id" content="${FB_APP_ID}">
<meta property="og:site_name" content="SEDER">
${meta.url ? `<meta property="og:url" content="${esc(meta.url)}">` : ""}
<meta property="og:title" content="${esc(meta.title)}">
<meta property="og:description" content="${esc(meta.desc)}">
${meta.image ? `<meta property="og:image" content="${esc(meta.image)}">
<meta property="og:image:secure_url" content="${esc(meta.image)}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="1200">` : ""}
<meta name="twitter:card" content="${meta.image ? "summary_large_image" : "summary"}">
<meta name="twitter:title" content="${esc(meta.title)}">
<meta name="twitter:description" content="${esc(meta.desc)}">
${meta.image ? `<meta name="twitter:image" content="${esc(meta.image)}">` : ""}`;
  return `<!doctype html><html lang="no"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(meta.title)} · SEDER</title>${og}
<style>
:root{--bg:#201d19;--panel:#2a2620;--line:rgba(233,222,200,.12);--text:#efe7d7;--muted:#a89a82;--gold:#cba85f}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;line-height:1.55}
.wrap{max-width:520px;margin:0 auto;padding:0 20px 120px}
.brand{text-align:center;letter-spacing:.28em;color:var(--gold);font-size:13px;padding:22px 0 8px}
.hero{width:100%;border-radius:12px;border:1px solid var(--line);margin-top:8px;display:block}
.serif{font-family:'Iowan Old Style','Palatino Linotype',Palatino,Georgia,serif}
h1{font-size:24px;margin:16px 0 2px;font-weight:600}
.meta{color:var(--muted);font-size:14px;margin:0 0 12px}
.stars{color:var(--gold);font-size:20px;letter-spacing:2px}
.note{font-style:italic;font-size:15px;margin:14px 0}
.author{color:var(--muted);font-size:13px;margin-top:18px}
.prompt{position:fixed;left:0;right:0;bottom:0;background:var(--panel);border-top:1px solid var(--line);padding:16px 20px 22px}
.prompt .inner{max-width:520px;margin:0 auto;text-align:center}
.prompt .t{font-size:14px}
.btn{display:block;background:var(--gold);color:#241d0d;font-weight:700;text-decoration:none;padding:12px;border-radius:10px;margin-top:10px}
.link{display:block;color:var(--gold);font-weight:600;text-decoration:none;margin-top:11px;font-size:13px}
.center{max-width:520px;margin:0 auto;padding:80px 24px;text-align:center;color:var(--muted)}
</style></head><body>${body}</body></html>`;
}

module.exports = async (req, res) => {
  const slug = (req.query && req.query.slug ? String(req.query.slug) : "").trim();
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.setHeader("Cache-Control", "public, max-age=300");

  if (!slug) {
    res.statusCode = 404;
    res.end(page(`<div class="center">Fant ingen oppføring.</div>`,
      { title: "SEDER", desc: "Din digitale sigarjournal", image: null }));
    return;
  }

  let row = null;
  try {
    const r = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_public_journal_entry`, {
      method: "POST",
      headers: { apikey: ANON, Authorization: `Bearer ${ANON}`, "Content-Type": "application/json" },
      body: JSON.stringify({ p_slug: slug }),
    });
    const data = await r.json();
    row = Array.isArray(data) && data.length > 0 ? data[0] : null;
  } catch (_e) { row = null; }

  if (!row) {
    res.statusCode = 404;
    res.end(page(`<div class="brand">S E D E R</div><div class="center">Denne oppføringen er privat.</div>`,
      { title: "SEDER", desc: "Denne oppføringen er privat.", image: null }));
    return;
  }

  const title = [row.cigar_brand, row.cigar_series].filter(Boolean).join(" ");
  const metaLine = [row.cigar_vitola].filter(Boolean).join(" · ");
  const photo = row.photo_url ? `<img class="hero" src="${esc(row.photo_url)}" alt="">` : "";
  const score = row.rating ? `${row.rating}/100` : "";
  const note = row.personal_notes ? `<p class="note">«${esc(row.personal_notes)}»</p>` : "";
  // Delings-kortets beskrivelse: vitola · score/100 — notat
  const head = [metaLine, score].filter(Boolean).join(" · ");
  const desc = [head, row.personal_notes].filter(Boolean).join(" — ") || "En sigar-opplevelse på SEDER";

  const body = `
  <div class="wrap">
    <div class="brand">S E D E R</div>
    ${photo}
    <h1 class="serif">${esc(title)}</h1>
    <p class="meta">${esc(metaLine)}${score ? ` · <span class="stars">${esc(score)}</span>` : ""}</p>
    ${note}
    <div class="author">Loggført av ${esc(row.author_name)}</div>
  </div>
  <div class="prompt"><div class="inner" id="p">
    <div class="t serif">Vil du føre din egen sigarjournal?</div>
    <a class="btn" href="${APP_STORE_URL}">Last ned appen</a>
    <a class="link" href="#" onclick="document.getElementById('p').parentElement.style.display='none';return false">Fortsett til nettsiden →</a>
  </div></div>`;

  res.statusCode = 200;
  // og:title inkluderer vitola + rating, siden FB-kortet i feeden viser tittelen
  // men dropper description. Slik ser kortet: bilde + «Navn · Toro · 85/100».
  const ogTitle = [title, metaLine, score].filter(Boolean).join(" · ");
  res.end(page(body, {
    title: ogTitle, desc,
    image: row.photo_url || null,
    url: `https://sederappen.no/j/${slug}`,
  }));
};
