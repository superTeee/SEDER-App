// public-journal: offentlig HTML-side for et delt journalinnlegg.
// Uten innlogging. Leser kun trygge visningsfelt via get_public_journal_entry
// (SECURITY DEFINER, kun delte oppføringer). Mykt install-prompt nederst.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const APP_STORE_URL = "https://vitola.app"; // TODO: bytt til App Store-lenke ved lansering

function esc(s: string | null | undefined): string {
  return (s ?? "").replace(/[&<>\"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string));
}

function ratingStars(r: number | null): string {
  if (!r) return "";
  const v = r / 20; // 0–100 → 0–5
  let out = "";
  for (let i = 0; i < 5; i++) out += (v - i >= 1) ? "★" : (v - i >= 0.5 ? "½" : "☆");
  return out;
}

function page(body: string): string {
  return `<!doctype html><html lang="no"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SEDER</title>
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

Deno.serve(async (req) => {
  const url = new URL(req.url);
  let slug = url.searchParams.get("slug");
  if (!slug) {
    const parts = url.pathname.split("/").filter(Boolean);
    slug = parts[parts.length - 1] || null;
    if (slug === "public-journal") slug = null;
  }

  const headers = { "Content-Type": "text/html; charset=utf-8" };

  if (!slug) {
    return new Response(page(`<div class="center">Fant ingen oppføring.</div>`), { status: 404, headers });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data, error } = await supabase.rpc("get_public_journal_entry", { p_slug: slug });
  const row = Array.isArray(data) && data.length > 0 ? data[0] : null;

  if (error || !row) {
    return new Response(
      page(`<div class="brand">S E D E R</div><div class="center">Denne oppføringen er privat.</div>`),
      { status: 404, headers },
    );
  }

  const title = [row.cigar_brand, row.cigar_series].filter(Boolean).join(" ");
  const metaLine = [row.cigar_vitola].filter(Boolean).join(" · ");
  const photo = row.photo_url
    ? `<img class="hero" src="${esc(row.photo_url)}" alt="">`
    : "";
  const stars = ratingStars(row.rating);
  const note = row.personal_notes
    ? `<p class="note">«${esc(row.personal_notes)}»</p>` : "";

  const body = `
  <div class="wrap">
    <div class="brand">S E D E R</div>
    ${photo}
    <h1 class="serif">${esc(title)}</h1>
    <p class="meta">${esc(metaLine)}${stars ? ` · <span class="stars">${stars}</span>` : ""}</p>
    ${note}
    <div class="author">Loggført av ${esc(row.author_name)}</div>
  </div>
  <div class="prompt"><div class="inner" id="p">
    <div class="t serif">Vil du føre din egen sigarjournal?</div>
    <a class="btn" href="${APP_STORE_URL}">Last ned appen</a>
    <a class="link" href="#" onclick="document.getElementById('p').parentElement.style.display='none';return false">Fortsett til nettsiden →</a>
  </div></div>`;

  return new Response(page(body), { headers });
});
