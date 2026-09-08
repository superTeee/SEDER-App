# HANDOVER — SEDER (Vitola) cigar app

> Overleveringsdokument for en ny AI-utvikler som overtar videre utvikling.
> Skrevet basert på hele prosjekthistorikken, ikke bare dagens kildekode.
> Sist oppdatert: 4. september 2026.

---

## 1. Hva produktet er

**SEDER** (tidligere navn **Vitola** — bundle-ID, pakkenavn og fagordet «vitola» beholdes) er en **«Shazam for sigarer»**: du tar bilde av sigarbeltet, appen kjenner den igjen, og du kan logge, vurdere og organisere sigarene dine.

**Problemet det løser:** sigarentusiaster har ingen god måte å (a) identifisere en ukjent sigar fra båndet, (b) føre en personlig smaksdagbok, og (c) holde oversikt over hva som ligger i humidoren(e). SEDER samler skann → journal → humidor i én app, med en voksende, produsent-verifisert sigardatabase i bunn.

**Plattformer:**
- **iOS** — SwiftUI, iOS 17+ (hovedplattform, «kilden til sannhet» for design).
- **Android** — Jetpack Compose, Material3 (skal være en tro kopi av iOS).
- **Backend** — Supabase (Postgres + Auth + Storage + Edge Functions).
- **Markedsside** — `web/index.html`, hostet på Vercel → vitola.app.

**Nøkkelfakta:**
- Supabase-prosjekt: `wpcricosogcmzebkplwp`
- Bundle ID / pakkenavn: `com.tomerikheggedal.vitola` · Apple Team: `H7NS3V5EFA`
- GitHub: `github.com/superTeee/Vitola-App` (HTTPS remote, branch `main`)
- Prosjektmappe (Tom sin Mac): `~/Documents/My Projects/Cigar App/`
- iOS marketing-versjon alltid `1.0`; build-nummer bumpes i `iOS/project.yml` + `project.pbxproj` (2 steder i pbxproj).

---

## 2. Arbeidsdeling og samarbeidsform (viktig kontekst)

- **Tom** (eier) tar alle design- og produktbeslutninger og er svært visuell. Han har ADHD og foretrekker: ett steg av gangen, tydelig anbefaling fremfor mange likestilte valg, visuelle/konkrete forklaringer, og en kort statusoppsummering til slutt i hvert svar.
- **AI-utvikleren** gjør alt det tekniske (kode, DB-migrasjoner, bygg, signing). Tom kan ikke lese kode flytende — forklar endringer visuelt og konkret.
- **Git-flyt:** AI committer lokalt, **Tom pusher selv fra GitHub Desktop**. Sky-sandboksen kan ikke pushe (ingen GitHub-innlogging) og kan ikke slette filer på fil-mounten (se «Kjente fallgruver»).
- Tom bygger selv i Xcode / Android Studio — **AI kan ikke kompilere**. Derfor: verifiser alltid klamme-/parentes-balanse etter redigeringer, og be Tom om øverste linje i en byggfeil hvis noe brekker.

---

## 3. Teknologistack

### iOS
- SwiftUI (iOS 17+), Swift.
- `supabase-swift` SDK (Auth, Postgrest, Storage, Functions).
- `GoogleSignIn` (Google-innlogging).
- `Kingfisher` (bildelasting/-cache).
- Apple Vision (OCR på båndtekst) + AVFoundation (kamera).
- Egen `BandCropView` for bildeutsnitt (byttet ut Mantis — se arkitekturvalg).
- StoreKit 2 via `StoreManager` for «SEDER Pro»-kjøp.

### Android
- Jetpack Compose + Material3.
- `supabase-kt` SDK.
- `Coil` (`AsyncImage`) for bilder.
- Google ML Kit (OCR).
- **RevenueCat** planlagt for betaling (Play Billing) — **ikke konfigurert ennå** (placeholder-nøkkel).
- `ThemeState` (SharedPreferences) for tema.

### Backend / felles
- Supabase Postgres (RLS på nesten alle tabeller), Storage (bøtter for sigar-/logg-/humidor-/bånd-bilder), Edge Functions (Deno/TypeScript).
- OpenAI GPT-4o vision brukes server-side i edge functions (skann-fallback, kvitteringstolking).

---

## 4. Overordnet arkitektur

```
   iOS (SwiftUI)                Android (Compose)
   Views → Services  ─┐      ┌─ ui → data (Repositories)
                      │      │
                      ▼      ▼
              Supabase (Postgres + Auth + Storage)
                      │
         ┌────────────┼─────────────┐
     RPC-funksjoner  RLS-policies  Edge Functions (Deno)
                                     scan-cigar (GPT-4o),
                                     parse-receipt, humidor-sensor,
                                     public-journal, log-card,
                                     delete-account, embed-band
```

- **iOS:** tynne `Views/` som snakker med `Services/` (én service per domene). Ingen tung state-container; `ExploreStore` er unntaket (observobserverbar butikk for utforsk/topp-3/dagens utvalgte).
- **Android:** `ui/`-skjermer som snakker med `data/`-repositories (én `*Repository.kt` per domene, speiler iOS-servicene).
- **All forretningslogikk som kan ligge i DB, ligger i DB** som RPC-funksjoner (fuzzy-skann-matching, founding-number-tildeling, topp-3, o.l.), slik at iOS og Android deler samme oppførsel.

---

## 5. Mappestruktur (viktige deler)

```
Cigar App/
├── iOS/
│   ├── project.yml               # XcodeGen-kilde (build-nr her)
│   ├── Vitola.xcodeproj
│   └── CigarApp/
│       ├── CigarAppApp.swift     # @main, Google Sign-In config, root-oppsett, FoundingConfig.cap = 50
│       ├── Models/               # Cigar, UserModels, HumidorModels, Feed/FriendModels
│       ├── Services/             # SupabaseConfig, Auth, Cigar, Profile, Scan, StoreManager, PIN, ...
│       └── Views/                # Explore, Journal, Humidor, Cigar, Scan, Profile, Shared
├── android/
│   └── app/src/main/java/com/tomerikheggedal/vitola/
│       ├── MainActivity.kt, VitolaApplication.kt, AppPrefs.kt
│       ├── data/                 # *Repository.kt, Cigar.kt, ProManager.kt, Supabase.kt
│       └── ui/                   # theme/, components/, explore/, journal/, humidor/, detail/, profile/
├── supabase/
│   ├── migrations/               # nummererte SQL-migrasjoner (se «Database»)
│   ├── functions/                # edge functions (Deno)
│   └── config.toml
├── web/                          # markedsside (index.html → Vercel)
├── CLAUDE.md                     # (finnes ikke i repoet i dag — se pkt. 20)
├── CHAT_HANDOFF.md               # tidligere overlevering (4. aug 2026) — nyttig historikk
├── Vitola_MVP_Plan.md, cigar-app-strategi.md, Gjennomgang-sikkerhet-og-jus.md
└── build*.command, *.command     # Toms hjelpeskript for bygg/opplasting/migrasjon
```

**Delte design-komponenter (endre disse ett sted → slår igjennom app-vidt):**
- iOS: `Views/Shared/ImageSupport.swift` (`ScoreBadge`), `Views/Shared/PhotoButtons.swift` (`EditPhotoPill`, `UploadPhotoPlaceholder`), `Views/Shared/CigarQuickActions.swift`.
- Android: `ui/components/ScoreBadge.kt`, `ui/components/SecondaryButton.kt`, `ui/components/EditablePhoto.kt`, `ui/components/VitolaChips.kt`, `ui/components/ListCard.kt`.

---

## 6. Database og datamodell

Supabase Postgres, RLS aktivert på alle tabeller **unntatt** `vitola_sizes` (se «Kjente bugs / sikkerhet»). Migrasjoner ligger i `supabase/migrations/` og kjøres ofte **for hånd** i prod — sjekk alltid at en tabell faktisk finnes i prod før du bygger på den. Siste brukte migrasjonsnummer er i 170-serien; sjekk `list_migrations` for neste ledige.

**Kjernetabeller:**
- `cigars` (~3700 rader) — sigardatabasen. Felter bl.a. `brand`, `series`, `vitola`, `common_format`, `ring_gauge`, `length_inches`, `wrapper_leaf`, `wrapper_country`, `country_origin`, `strength/body/sweetness/flavor_intensity`, `flavor_notes[]`, `avg_rating` (0–10, numeric(3,2)), `source_tier` (`manufacturer`/`community`/`retailer`), `verified_at`.
- `cigar_aliases` (~129) — alternative navn for skann-matching.
- `tasting_logs` (~57) — brukerens journal/røykelogg (`rating` 0–100, `smoke_again`, `draw/burn/flavor_rating`, `cut_type`, `personal_notes`, `store`, `photo_url`, `smoked_at`, `humidor_entry_id`).
- `humidors` (~17) + `humidor` (~102) — humidor-beholdere og oppføringer (sigar × antall × dato-i-humidor).
- `humidor_rh_readings` — luftfuktighetsmålinger (manuelle + sensor).
- `profiles` (~17) — brukerprofil (`display_name`, `bio`, city/country, `is_founding_member`, medlemsnummer, statistikk-avledninger).
- `wishlist` (~8), `favorites` (~5) — ønskeliste og favoritt-sigarer.

**Skann-/lærings-tabeller:**
- `scan_events`, `scan_misses`, `scan_debug`, `scan_resolutions` — telemetri + læringsloop.
- `cigar_image_samples` (~553) — innsamlede bånd-/sigarbilder (brukes til gjenkjenning/embedding).
- `cigar_barcodes`, `cigar_reports`, `cigar_submissions`, `cigar_measurements`, `catalog_leads` (butikkført utvalg — **kun** for å vite hva som finnes, aldri som spesifikasjonskilde), `vitola_sizes`, `embed_config`.

**Sosialt lag (DVALE — se produktbeslutninger):** `posts`, `post_likes`, `post_comments`, `post_reports`, `friendships`, `entry_likes`, `user_blocks`. Tabellene finnes fortsatt, men **appene surfacer dem ikke lenger** (fjernet av hensyn til Apple 1.4.3). Ikke bygg nytt på disse uten en bevisst beslutning.

**Viktige RPC-funksjoner (forretningslogikk i DB):**
- `match_cigar` / `match_cigar_by_band` — aksent-/fuzzy-tolerant skann-matching mot brand+series+vitola+aliases.
- `record_scan_resolution` — læringsloop: registrerer manuell løsning, forfremmer alias etter 3 distinkte brukere ELLER hvis innsender er sigarens «creator».
- `claim_founding_number` — tildeler medlemsnummer; nummer ≤ 50 gir livstids-Pro (founding member).
- `update_own_tasting_log` — oppdaterer egen logg; `photo_url` settes med rett tilordning (null fjerner bildet).
- Topp-3 / «above average» / distinct-verdier for utforsk og filter.

---

## 7. Autentisering og brukerhåndtering

- **Supabase Auth.** Innlogging via **Google Sign-In** (`GoogleSignIn` på iOS, Google client-IDs konfigureres i `CigarAppApp.swift`) og e-post.
- **PIN-lås:** `PINService` (iOS) gir en lokal PIN-kode over innlogget sesjon. NB: en tidligere krasj oppsto etter PIN-skjermen — se «Ting man må være forsiktig med».
- **Founding members:** de 50 første (`FoundingConfig.cap = 50` på iOS, `ProConfig.foundingCap = 50` på Android) får livstids-Pro via `claim_founding_number`. `FoundingWelcome`/`FoundingWelcomeDialog` vises én gang.
- **Sletting av konto:** edge function `delete-account` (+ `supabase/delete_user.sql`).
- **Aldersgrense:** regionsstyrt minstealder (21 i USA/territorier, 18 ellers) via `LegalAge`/`LegalAge`-tekster (Android) — del av tobakks-compliance.
- **RLS + lowercase storage-stier:** storage-stier MÅ være lowercase for at RLS-policyene skal treffe.

---

## 8. Eksterne API-er og tjenester

- **Supabase** — Postgres, Auth, Storage, Edge Functions.
- **OpenAI GPT-4o (vision)** — server-side i edge functions:
  - `scan-cigar` (skann-fallback, moduser «shape»/«wrapper»),
  - `parse-receipt` (kvitteringstolking for å legge flere sigarer i humidor).
- **Google Sign-In** (OAuth).
- **Apple Vision** (iOS OCR) / **Google ML Kit** (Android OCR) — på enhet.
- **StoreKit 2** (iOS-kjøp) / **RevenueCat + Play Billing** (Android, planlagt).
- **Vercel** (hosting av markedsside).
- Edge functions: `humidor-sensor` (RH-sensor-inntak), `public-journal` + `log-card` (offentlig deling/kort), `embed-band` (bilde-embeddings for gjenkjenning), `delete-account`.

---

## 9. Miljøvariabler / hemmeligheter som kreves

> Ingen faktiske nøkler her. Verdier ligger i Supabase-prosjektets Secrets (edge functions) og i kildekode/Xcode/Play-konsoll (klientnøkler).

**iOS (i kildekode / Xcode-config):**
- `SupabaseConfig.projectURL` — Supabase-prosjekt-URL (offentlig).
- `SupabaseConfig.anonKey` — Supabase **anon**-nøkkel (offentlig, trygg i klient).
- Google Sign-In `clientID` + `serverClientID` (i `CigarAppApp.swift`) — OAuth-klient-IDer.

**Android:**
- Supabase URL + anon key (`data/Supabase.kt`).
- `ProConfig.revenueCatApiKey` — RevenueCat Play-nøkkel (`goog_…`). **Er en placeholder i dag** (`goog_LIM_INN_HER`); må settes før betaling virker.
- Google OAuth-klient-ID.

**Supabase Edge Function secrets (server-side, ekte hemmeligheter):**
- `OPENAI_API_KEY` — for `scan-cigar` og `parse-receipt`.
- Supabase **service role**-nøkkel er tilgjengelig for funksjonene via miljøet (aldri i klient).

**Skal ALDRI i git / klient:** OpenAI-nøkkel, Supabase service-role-nøkkel, Apple-ID-passord/2FA, ekte RevenueCat-nøkkel. (Supabase anon key og OAuth-klient-IDer i kildekode er OK.)

---

## 10. Viktige produktbeslutninger

1. **Navnebytte Vitola → SEDER** i UI, men beholder bundle-ID/pakkenavn/fagordet «vitola».
2. **Kildeverifisering er hellig:** kun **produsentens egen side** teller for spesifikasjoner. **Tomt slår gjetning** — la heller ring/lengde/blend stå tomme enn å gjette. Forhandler brukes bare når merket eksplisitt tillates, og markeres `source_tier='retailer'`.
3. **Apple 1.4.3 (tobakk)-compliance** har styrt mange valg:
   - Hele det **sosiale laget er fjernet** fra appene (Aktivitet-fane, venner, andres profiler, likes/kommentarer) — for å ikke «promotere» tobakk.
   - **Nøytralisert rating-copy** («Min vurdering», score-badge = kun tall, ingen oppfordrende språk).
   - **Regionsstyrt aldersgrense.**
   - **Dele-funksjon** deler kun sigarens navn (ingen kjøpe-CTA, ingen oppfordring).
   - **«Dagens utvalgte» er flagget som risiko** (en personlig daglig anbefaling ligner mest på «encourage consumption»). Anbefaling ligger klar: gjør den informativ i stedet for anbefalende, og dropp det smakstilpassede steget. **Ikke implementert ennå.**
4. **Founding-kohort = 50** (livstids-Pro), speilet i både klient og `claim_founding_number`.
5. **Dark mode er standard** i begge apper.
6. **Betaling:** iOS via StoreKit 2 (klart). Android via RevenueCat/Play Billing — **utsatt** (trenger Play-konto + nøkkel).

---

## 11. Viktige UI/UX-prinsipper (designsystemet)

Etablert gjennom mange iterasjoner. Hold dette konsistent app-vidt:

- **Dark mode først.** Semantiske asset-farger: `Accent` (`#8F7B51` latte), `Background`, `Card`, `Surface`, `TextPrimary`, `TextSecondary`.
- **Outline-stil overalt** (ikke fylte flater): score-badge, chips/tags, sekundærknapper og status-badges er **kun kant** i Accent + hvit/lys tekst. Fylt Accent brukes bare når noe er «valgt» eller er en primærknapp.
- **Sekundærknapper:** delt komponent, 1.2px kant. Kanten er nå **Accent @ 50% opacity** (dempet, ikke så fremtredende). Hvit tekst/ikon, ingen fyll.
- **Aktiv tab = Accent-fylt pille + hvitt ikon** (matcher FAB/primærfarge). Topp-ikoner hvite.
- **Liste-rad for sigarer (likt overalt — humidor, utforsk topp-3/dagens utvalgte, journal, profil):**
  - Tittel = **merke**, `size 16 semibold`.
  - Undertittel = **«serie · vitola»** på én linje, `size 14`.
  - Metadata-linje (f.eks. «I humidoren · 17 dager») minst.
  - Score-tag til høyre i standard `ScoreBadge`-størrelse (14), med 4–8px ekstra høyre-luft i journal/humidor.
  - **Headere** (stor tittel i detaljvisning, sheet-titler, skann-hero) er en egen kategori og skal være større — ikke dra dem til 16.
- **«Label»-stil app-vidt:** `size 12 semibold`, `tracking 0.6`, sekundærfarge (SMAKSNOTER, POENGSUM, SEKSJONER, bokstav-headere).
- **Bildeendring-mønster:** delt `EditPhotoPill`/`EditablePhoto` — stort kvadratisk bilde med «Endre»-pille øverst til høyre + «Fjern bilde» under + outline-placeholder når tomt. **«Endre og fjern skal være med overalt.»**
- **`displayName`:** merke + serie deduplisert for gjentatte ord ved siden av hverandre («Arturo Fuente» + «Fuente Fuente OpusX» → «Arturo Fuente OpusX»). Ligger på `Cigar`-modellen i begge apper.
- **Bildeutsnitt (crop):** standard = kvadratisk, sentrert, 40% av skjermen; stor draggable resize-handle (stor klikkflate); «Bruk» er en full-bredde primærknapp under bildet (ikke lenke øverst).
- **Bildekvalitet:** cover-opplastinger nedskaleres (`downscaledJPEG`, ~1200px, q≈0.7) for å spare data/RAM.

---

## 12. Features — ferdige

- Skann sigarbelte → identifikasjon (OCR → `match_cigar` → GPT-4o vision-fallback) med lærings-loop.
- Sigardatabase (~3700), utforsk med søk, A–Z merkeliste, avansert filter (alle chips åpne, vertikale bunnknapper), «Høyest vurderte» topp-3.
- Journal: logg røyking med score (0–100), «røk igjen?», del-vurderinger (trekk/brenning/smak), snitt-type, notat, bilde. Kompakt liste gruppert per måned, sammenslått endre/preview-sheet med bilde øverst.
- Humidor(er): legg til/fjern sigarer, antall, «dager i humidor», RH-målinger (manuelt + sensor via `humidor-sensor`), historikk, flytt sigar mellom humidorer, fjern-fra-humidor med bekreftelse + «gli ut»-animasjon + retur til liste.
- Kvitteringstolking (`parse-receipt`) for å legge flere sigarer i humidor.
- Ønskeliste + favoritter.
- Auth (Google + e-post), PIN-lås, founding-member-flyt (Pro for de 50 første), kontosletting, regionsstyrt aldersgrense.
- iOS-betaling (StoreKit 2 / «SEDER Pro»).
- Fullt designsystem rullet ut på iOS; Android-paritet på designsystem + kjernefeatures.
- Markedsside (vitola.app).

## 13. Features — delvis ferdige

- **Android-paritet:** designsystem + de fleste skjermer er på plass, men Android mangler fortsatt **foto-opplasting i loggfør-/legg-i-humidor-sheets** (finnes ikke der ennå — trenger repository-endring). Denne øktas iOS-polish (16px-titler, 14px-undertekst, 12px-labels, score-tag, sekundærknapp 50% kant, status-chip dark mode, fjern-knapp/animasjon, journal-endre-bilde-øverst) er **ikke speilet til Android ennå** (avtalt som neste steg).
- **«Endre + fjern bilde»-mønsteret:** ferdig i journal og enkelte sheets. Mangler på 3 «immediate-upload»-steder (cigar-detalj, humidor-detalj, profil) fordi det trengs **nye server-side «fjern bilde»-funksjoner** (finnes ikke ennå).
- **Sensor-humidor:** RH-inntak virker; bredere sensor-økosystem er tidlig.

## 14. Features — planlagte

- **Android betaling** (RevenueCat + Play Billing) — blokkert til Play-konto + `goog_`-nøkkel finnes.
- **«Dagens utvalgte» → informativ variant** (compliance-tiltak, se pkt. 10.3).
- Push-varsler (tidligere planlagt for sosialt; revurder gitt at sosialt lag er fjernet).
- Fylle inn manglende sigar-størrelser per skann (f.eks. La Barba-linjer).
- Fortsette å tette datahull i sigardatabasen etter mislykkede skann.

---

## 15. Kjente bugs / sikkerhet

- **`vitola_sizes` har RLS deaktivert** — tabellen er fullt eksponert for anon/authenticated. Vurder `ALTER TABLE public.vitola_sizes ENABLE ROW LEVEL SECURITY;` + policies (ikke aktiver uten policies — da blokkeres all tilgang). Bekreft med Tom først.
- **Simulator har ikke kamera:** `ImagePicker` må ha availability-guard + fallback til fotobibliotek (fikset, men lett å reintrodusere).
- Bygg-artefakter fra fil-mounten (`.fuse_hidden*`) og en `_to_delete/`-mappe med gamle git-låsefiler ligger i arbeidstreet; nå git-ignorert. Kan ryddes med `git gc` + sletting av `_to_delete/` på Macen.

## 16. Teknisk gjeld

- **`ExploreView.swift` har en pre-eksisterende parentes-ubalanse på −4** som balanse-sjekker rapporterer. Den er «kjent og uendret» — ikke jag den blindt; klammer (`{}`) balanserer, og filen kompilerer. Verifiser at dine egne endringer holder `{}`-balansen på 0 og ikke gjør paren-tallet verre enn −4.
- **iOS-prosjektet regenereres ikke fra `project.yml` i praksis** — legg ny Swift-kode i EKSISTERENDE `.swift`-filer, ikke lag nye filer (de blir ikke plukket opp i Xcode-prosjektet automatisk). Android: nye `.kt`-filer er OK.
- **Dobbelt datamodell** (iOS Swift + Android Kotlin) må holdes manuelt i synk — samme felt/logikk to steder.
- **Sosialt-lag-tabeller** ligger i DB men er ubrukt av appene (dvale).
- Migrasjoner kjøres ofte for hånd → risiko for drift mellom migrasjonsfiler og faktisk prod-skjema. Verifiser mot prod.

## 17. Midlertidige løsninger / hacks å rydde i

- **Android `ProConfig.revenueCatApiKey = "goog_LIM_INN_HER"`** — placeholder. `isConfigured` sjekker at nøkkelen starter med `goog_` og ikke inneholder `LIM_INN`.
- **Død kode:** `JournalLogDetailSheet` (iOS `JournalView.swift`) er ubrukt etter at endre/preview ble slått sammen — kan slettes.
- **Founding-kode «SEDER100»** (Android) henger igjen fra da cap var 100; cap er nå 50. Koden er en RevenueCat-innløsningsstreng knyttet til betaling (blokkert), så la den ligge til RevenueCat konfigureres.
- **Git på fil-mounten:** sky-sandboksen kan ikke `unlink`, så hver git-skriveoperasjon etterlater fastlåste `.lock`-filer. Arbeidsrunde: flytt (`mv`) låser til `*.moved.*` før neste commit. **Push gjøres alltid av Tom fra GitHub Desktop.** Dette er den viktigste grunnen til å ikke prøve å pushe fra sandboksen.

---

## 18. Ting en ny utvikler MÅ være forsiktig med

- **Ikke la `ExploreView.body` (og lignende) bli for dypt nestet.** En reell **krasj etter PIN-innlogging** (`EXC_BAD_ACCESS`, stack-overflow ved instansiering av SwiftUI-typemetadata på enhet, men ikke på simulator) ble løst ved å splitte en ~36-modifiers-kjede i `AnyView`-type-viskede computed properties (`exploreScreenA/B`). **Behold disse splittene** — de er ikke kosmetiske. Test alltid på ekte enhet, ikke bare simulator.
- **Storage-stier må være lowercase** (RLS).
- **`avg_rating` er 0–10, brukerrating er 0–100.** Utforsk viser `avg_rating × 10`. Ikke bland skalaene.
- **Kildeverifisering:** aldri gjett sigar-spesifikasjoner. Tomt slår gjetning.
- **Ikke gjenopplive det sosiale laget** uten en bevisst 1.4.3-vurdering.
- **Endre delte komponenter bevisst** (`ScoreBadge`, `SecondaryButton`, `EditablePhoto`, `EditPhotoPill`) — én endring slår igjennom overalt.
- **iOS: rediger eksisterende `.swift`-filer, ikke lag nye.**
- Hold **iOS og Android i synk** når du endrer felles oppførsel/design.

---

## 19. Neste anbefalte utviklingsoppgaver (prioritert)

1. **Speil denne øktas iOS-polish til Android** (avtalt neste steg): 16px liste-titler, 14px «serie · vitola», 12px labels, score-tag lik utforsk, sekundærknapp 50% kant, humidor status-chip lesbar i dark mode, fjern-fra-humidor-knapp + liste-animasjon, journal-endre (bilde øverst, detaljer åpne, mer luft over slett).
2. **Compliance: gjør «Dagens utvalgte» informativ** i stedet for anbefalende (dropp `fetchTasteFeaturedCigar()`-steget, endre tittel/tekst). Senker Apple 1.4.3-risiko. Vurder også resten av appen for oppfordrende språk før ny innsending.
3. **Følg opp App Review-anken** (sendt 24. aug) og/eller send inn en ryddet build — ofte raskere enn å vente på Board.
4. **Android foto-opplasting** i loggfør-/legg-i-humidor-sheets (repository-endring).
5. **Server-side «fjern bilde»-funksjoner** for de 3 immediate-upload-stedene, så «endre + fjern» blir komplett overalt.
6. **Android betaling** (når Play-konto + `goog_`-nøkkel finnes).
7. **Sikkerhet:** vurder RLS på `vitola_sizes`.
8. Rydd teknisk gjeld: slett `JournalLogDetailSheet`, rydd `_to_delete/`, `git gc`.

---

## 20. CLAUDE.md

Det finnes **ingen `CLAUDE.md`** i repoet i dag. De facto-instruksjonene som har styrt arbeidet ligger i:
- **`CHAT_HANDOFF.md`** (4. aug 2026) — forrige overlevering; inneholder skann-pipeline, kildeverifiseringsregel, arbeidsdeling, Xcode-arkiveringstriks, migrasjonsnumre. Les den for dypere historikk.
- `Vitola_MVP_Plan.md`, `cigar-app-strategi.md`, `Gjennomgang-sikkerhet-og-jus.md`, `App_Store_*`-doks.

**Anbefaling:** opprett en kort `CLAUDE.md` i rotmappen som destillerer pkt. 2, 10, 11 og 18 her (arbeidsform, compliance-beslutninger, designsystem, fallgruver) — det er den konteksten en ny AI-utvikler trenger før første tastetrykk.

---

## 21. Annet fra samtalene som ikke er åpenbart fra koden

- **Apple App Review-status:** en build har ligget i review; en anke ble sendt til App Review Board **24. aug 2026**. Board-anker har ingen offentlig svartid og ingen live-status; en rettet, ny innsending er ofte raskere enn å vente.
- **Deling og tobakk:** topp-høyre dele-ikon på sigar-detalj deler bevisst kun `cigar.fullName` (tekst) via systemets dele-ark — ingen kjøpe-CTA. Hold delt innhold nøytralt/journalførende, aldri «prøv denne».
- **Skann-loader** (iOS `ScanningOverlay` / Android `ScanLoader.kt`): gull-hjørner + gull-stråle + mykt vekslende tekst («Skanner sigarbeltet» → «Skanner dekkblad» → «Søker i basen»).
- **Soft wrapper-booster:** skann-kandidater ordnes etter dekkblad-treff uten å droppe noen.
- **Wrapper-guide-sheet** på avansert søk (10 dekkbladtyper med fargeprøve/opphav/smaksnoter).
- **Build-nummer** settes 3 steder (project.yml + 2× pbxproj); marketing-versjon alltid «1.0».
- **Xcode-arkivering:** destinasjon «Any iOS Device (arm64)»; hvis Archive er grået ut, bring prosjektvinduet i fokus først.
- **Tom er designer/UX-er, svært visuell, ADHD** — kommuniser i små, konkrete, visuelle steg med tydelig anbefaling, og avslutt hver melding med en kort statusoppsummering.

---

_God overtakelse. Start med å lese `CHAT_HANDOFF.md` for historikk, bygg begge apper én gang for å se dagens tilstand, og ta pkt. 18 og 19 på alvor før du rører designsystemet eller pusher noe._
