import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Sletter den innloggede brukerens konto (Play/App Store-krav).
// Identifiserer brukeren fra JWT-en, sletter profilraden + auth-brukeren med
// service-role. verify_jwt=true sikrer at kun en innlogget bruker kan kalle den,
// og at brukeren kun kan slette SEG SELV.
Deno.serve(async (req: Request) => {
  const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), { status: 405, headers: { ...cors, "Content-Type": "application/json" } });
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const authHeader = req.headers.get("Authorization") ?? "";

  // Hvem kaller? (fra brukerens egen JWT)
  const userClient = createClient(url, anon, { global: { headers: { Authorization: authHeader } } });
  const { data: { user }, error: userErr } = await userClient.auth.getUser();
  if (userErr || !user) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401, headers: { ...cors, "Content-Type": "application/json" } });
  }

  const admin = createClient(url, service);
  const uid = user.id;

  // Fjern mest identifiserende rad først (best effort).
  await admin.from("profiles").delete().eq("id", uid);

  // Slett selve auth-brukeren (innlogging umulig etterpå).
  const { error: delErr } = await admin.auth.admin.deleteUser(uid);
  if (delErr) {
    return new Response(JSON.stringify({ error: delErr.message }), { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }

  return new Response(JSON.stringify({ ok: true }), { headers: { ...cors, "Content-Type": "application/json" } });
});
