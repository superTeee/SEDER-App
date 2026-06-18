# Vitola — Produktstrategi og MVP+ plan

*Skrevet som konkret arbeidsdokument, ikke teoretisk rapport. Bruk det direkte til å bygge videre.*

---

## A. Produktvisjon (kort)

**Vitola er den private sigarjournalen din.** Skann båndet, få den identifisert, logg opplevelsen — bygg opp et personlig arkiv over hva du har røkt, hva du har liggende i humidoren, og hva du vil prøve.

Tre ord som styrer alle beslutninger fremover: **Scan. Log. Remember.**

Vitola er *ikke* et sosialt nettverk, *ikke* en markedsplass, og *ikke* en app som oppmuntrer til å røyke mer. Det er et personlig referanseverk — nærmere Untappd-modellen (logging + arkiv) enn Instagram-modellen (deling + oppmerksomhet), men uten alkohol/tobakk-andpåen i tonen.

---

## B. Informasjonsarkitektur (anbefalt)

Flat struktur, fire hovedområder + en knapp i midten:

```
┌─────────┬─────────┬─────────┬─────────┐
│ Humidor │ (Scan)  │ Journal │ Profil  │
└─────────┴─────────┴─────────┴─────────┘
```

- **Humidor** — det du har / det du vil ha (Wishlist er en filtrert visning *inni* Humidor, ikke egen fane)
- **Scan** — sentral handling, ikke en "fane" med innhold, men en FAB/knapp som åpner kamera
- **Journal** — historikk over check-ins (det du har røkt og logget)
- **Profil** — badges, levels, innstillinger, abonnement

**Discover/Feed: bevisst utelatt fra MVP.** Begrunnelse i punkt T (risiko) og R/S (backlog). Et sosialt feed krever moderering, kritisk masse av brukere og en helt annen kostnadsprofil — det er en *fase 2*-satsing, ikke noe som skal forsinke MVP+.

---

## C. Prioritert hovednavigasjon

1. **Humidor** (startskjerm/landing — du har allerede bestemt dette i tidligere arbeid)
2. **Scan**-knapp i midten av tab bar (mest brukte handling skal være én tap unna, alltid synlig)
3. **Journal**
4. **Profil**

Ingen hamburger-meny, ingen gjemte handlinger. Fire ting synlig, alt annet er én nivå dypere (f.eks. Wishlist = filter i Humidor, Innstillinger = inni Profil).

---

## D. Forbedret scan → match → handling-flow

```
[Kamera] → [OCR + bildeanalyse] → [Match-motor] → [Resultat-skjerm] → [Handling]
```

Match-motoren prøver i denne rekkefølgen (billigst først — se punkt O):

1. Lokalt DB-oppslag (eksakt/nær-eksakt treff på merke+serie+vitola)
2. Fuzzy-søk i lokal DB (typos, forkortelser)
3. Cache-oppslag (samme bilde/tekst-signatur skannet før, av deg eller andre)
4. OpenAI Vision-fallback (kun hvis 1–3 ikke gir treff over terskel)

Resultatet rutes til tre forskjellige skjermer basert på *confidence score* — se punkt E.

**Handling etter match** (uansett confidence-nivå) er alltid ett av tre:
- **Logg nå** (check-in) → går til punkt F
- **Legg i humidor** → går til punkt G
- **Legg i wishlist** → går til punkt H (egentlig samme tabell, se punkt J)

---

## E. Flow for høy / medium / lav confidence

| Nivå | Terskel (eksempel) | Skjerm | Microcopy | Handling |
|---|---|---|---|---|
| **Høy** | ≥ 0.85 | Full sigarkort vises direkte | *"Vi fant den: Arturo Fuente Hemingway Short Story"* | Bekreft → gå rett til Logg/Humidor/Wishlist |
| **Medium** | 0.5–0.85 | 2–3 kandidater vises som valg | *"Vi er ikke 100% sikre — er det en av disse?"* | Bruker velger riktig kort, eller "Ingen av disse" |
| **Lav** | < 0.5 | Manuell registrering | *"Vi klarte ikke å identifisere denne. Vil du registrere den selv?"* | Skjema med merke/serie/vitola — bidrar til punkt I |

Designprinsipp: **aldri lat som vi er sikre når vi ikke er det.** Lav/medium-flows skal kjennes hjelpsomme, ikke som en feilmelding. Hver "lav confidence"-registrering Tom samler inn er gratis datainnsamling for fremtidige skann (se ShapeContribution i punkt J).

---

## F. Flow for check-in / loggføring

Mål: **15–30 sekunder**, ferdig. Alt utover det er friksjon som dreper bruksfrekvens.

```
[Sigarkort] → [Rating: 1-5] → [Smaksnotater: velg 0-5 tags] → [Notat (valgfritt)] → [Lagre]
```

- Rating: enkel stjerne/slider, ett tap
- Smakstags: forhåndsdefinert chip-liste (eksempler: Jord, Kakao, Lær, Pepper, Nøtt, Tre, Krydder, Søtt, Kaffe, Sitrus, Honning, Røkt, Hø, Vanilje) — multi-select chips, ingen fritekst nødvendig
- Notat: fritekstfelt, men *ikke obligatorisk* — mange vil bare logge rating + tags
- Dato/tidspunkt: auto-utfylt, justerbart
- Valgfritt: knytt til humidor-item (trekker automatisk fra antall hvis du har den liggende)

**Ingen obligatoriske felt utover rating.** Hver ekstra obligatorisk ting halverer sannsynligheten for at folk logger i det hele tatt.

---

## G. Flow for humidor

```
[Legg til] → [Fra skann ELLER søk i DB ELLER manuelt] → [Antall + kjøpsdato + pris (valgfritt)] → [Status: I humidor]
```

Felt som faktisk betyr noe i praksis:
- Antall (du har sikkert flere av samme)
- Kjøpsdato / aldringsdato (interessant for cigar-nerder — alder på sigaren er ofte viktigere enn kjøpsdato)
- Pris (valgfritt, privat — aldri vist til andre)
- Status: `wishlist` / `owned` / `smoked_out` (se datamodell i J — dette er feltet som eliminerer behovet for egen WishlistItem-tabell)

Humidor-visningen filtreres med en enkel toggle: **"Mine" / "Wishlist"** — samme liste, samme kort, ett statusfelt avgjør hvilken bøtte den faller i.

---

## H. Flow for wishlist / historikk

**Wishlist er ikke en egen flow** — det er Humidor-listen filtrert på `status = wishlist`. Bruker trykker "Legg til i wishlist" fra et sigarkort (etter skann, søk, eller bla-gjennom), og den dukker opp i samme liste som humidoren, bare i en annen fane/filter.

**Historikk** = Journal-fanen (punkt C), som er en kronologisk liste over alle check-ins, filtrerbar på merke/serie/rating/dato. Dette er "minneboken" — kjernen i navnet *Remember*.

Fordel ved denne sammenslåingen: én datamodell, én UI-komponent (sigarkort-listen) gjenbrukes tre steder (Humidor, Wishlist-filter, søkeresultater), i stedet for å bygge og vedlikeholde tre separate skjermer.

---

## I. Flow for etterregistrering av sigarform

Når en sigar mangler `shape` (eller bruker fikk lav-confidence-match), be om det visuelt — ikke med tekst-dropdown:

```
[Vis 8-10 silhuetter av former] → [Bruker trykker på den som matcher] → [Lagre + bidra til DB]
```

- Vis silhuett-ikoner (Robusto, Torpedo, Churchill, Toro, osv.) side ved side — gjenkjenning er raskere enn å lese navn
- Når bruker velger, vis det tekniske navnet under ikonet som bekreftelse: *"Det er en Robusto (kort og tykk)"*
- Lagres som en `ShapeContribution`-rad (kobles til Cigar-id, bruker-id, tidspunkt) — dette er valideringsdata du kan bruke til å forbedre matching senere, og er separat fra selve `Cigar.shape`-feltet til en eventuell moderasjon/aggregering er på plass
- **Foot/head/cap/body-terminologi:** ikke vis disse begrepene i UI overhodet i MVP. De er interessante for sigar-nerder, men adderer kompleksitet uten å løse et reelt MVP-problem. Behold dem som tekniske kolonner i databasen (for fremtidig bruk), men skjul i grensesnittet.

---

## J. Datamodell (forslag)

**Prinsipp: minimer antall tabeller i MVP. Slå sammen der det er mulig, bruk constrained text-felt i stedet for lookup-tabeller.**

### Kjernetabeller

**Cigar** *(allerede i prod — Supabase `cigars`, 322 rader, 10 merker)*
id, brand, series, vitola, wrapper_country, wrapper_leaf, binder, filler[], strength (1-5), country_origin, flavor_notes[], description, band_image_url, product_image_url, price_range, avg_rating, ring_gauge, length_inches, shape, created_at

→ `CigarFormat`, `CigarShape`, `CigarFoot`, `CigarHead` blir **ikke** egne tabeller i MVP. De er constrained text-kolonner direkte på Cigar (shape er allerede dette). En lookup-tabell gir ingen verdi før du trenger flerspråklig oversettelse eller admin-redigerbare lister — det er en "later"-ting.

**User**
id, email, display_name, avatar_url, level_code (denormalisert, se punkt M), subscription_tier (`free`/`plus`/`collector`), created_at

**ScanResult** *(kritisk for kostnadskontroll — se punkt O)*
id, user_id, image_signature (hash), ocr_raw_text, ocr_normalized_text, text_signature (hash), matched_cigar_id (nullable), confidence_score, resolution_method (`local_db`/`fuzzy`/`cache`/`openai`/`manual`), created_at

**CheckIn**
id, user_id, cigar_id, humidor_item_id (nullable), rating (1-5), taste_tags[], note, smoked_at, created_at

**HumidorItem** *(absorberer WishlistItem)*
id, user_id, cigar_id, status (`wishlist`/`owned`/`smoked_out`), quantity, purchase_date, age_date, price (nullable, privat), created_at

**TasteTag**
id, label, category (valgfritt: jord/søtt/krydret/tre — for fremtidig filtrering/anbefaling)

**ShapeContribution**
id, user_id, cigar_id, submitted_shape, created_at

**Badge** / **UserBadge**
Badge: id, code, name, description, icon, category (se punkt L)
UserBadge: id, user_id, badge_id, earned_at

### Bevisste forenklinger

| Forslag fra brief | MVP-beslutning | Hvorfor |
|---|---|---|
| WishlistItem (egen tabell) | Slått sammen i HumidorItem.status | Samme felt, samme UI-komponent, halverer kompleksitet |
| UserLevel (egen tabell) | Denormalisert `level_code` på User | Level beregnes fra antall check-ins/badges — ingen grunn til egen tabell før du trenger historikk over level-progresjon |
| CigarFormat/Shape/Foot/Head (egne tabeller) | Text-kolonner på Cigar | Ingen lookup-behov i MVP; kan migreres senere uten datatap |
| Rating (egen tabell) | Felt på CheckIn | En rating uten en check-in-kontekst gir ikke mening i denne appen |
| CigarCard | UI-konsept, ikke databasetabell | Genereres on-the-fly fra Cigar + evt. CheckIn-data ved deling |
| CommunityContribution | Utelatt helt fra MVP | Hører til Discover/Feed-fasen (se punkt S) |

---

## K. UI-tekst / microcopy (forslag)

Gjennomgående tone: **varm, kunnskapsrik venn — ikke en reklame for tobakk.**

| Situasjon | Tekst |
|---|---|
| Tom skjerm, humidor | *"Humidoren din er tom (foreløpig). Skann en sigar for å begynne arkivet ditt."* |
| Høy confidence-match | *"Vi fant den: [navn]"* |
| Medium confidence | *"Vi er ikke 100% sikre — er det en av disse?"* |
| Lav confidence | *"Vi klarte ikke å identifisere denne automatisk. Vil du registrere den selv? Du hjelper oss bli bedre."* |
| Check-in lagret | *"Logget. [X] sigarer i journalen din nå."* |
| Badge tildelt | *"Ny merke låst opp: [navn]"* (ikke "gratulerer, du har røkt nok!") |
| Quota nådd (free) | *"Du har brukt dine [X] gratis skann denne måneden. Oppgrader til Plus for ubegrenset skanning."* |
| Onboarding | *"Vitola hjelper deg huske hver sigar — hva den var, hvor du fikk den, og hva du tenkte om den."* |

**Unngå:** "Tid for en sigar!", "Du har ikke røkt på 3 dager", noe som kan tolkes som push til konsum. Alt språk skal støtte *journalføring*, aldri *forbruk*.

---

## L. Badge- og gamification-system

7 kategorier, ingen strea­ker, ingen "tung røyker"-rammer:

1. **Journal** — antall check-ins totalt (Første logg, 10 logger, 50 logger, 100 logger)
2. **Collector** — antall unike sigarer i humidoren over tid
3. **Vitola/Format** — har logget X forskjellige former (Robusto, Torpedo, osv.)
4. **Shape Contribution** — har bidratt med formdata til fellesskapet (se punkt I)
5. **Tasting** — har brukt et bredt spekter av smakstags (f.eks. "Smakt 10 forskjellige notater")
6. **Origin/Brand ("Kapittel")** — fullført et merke/opprinnelsesland, kalt "Kapittel" (f.eks. *"Kapittel: Nicaragua — fullført"*) — gir en bok/arkiv-følelse, ikke en konkurranse-følelse
7. **Community** — *reservert for senere* (se punkt S), ingen badges her i MVP

**Visuell retning:** badges skal se ut som **frimerker eller voksforseglinger**, ikke spillbadges med neonfarger. Tenk eksklusivt bibliotek-/arkivkort, ikke mobilspill.

**Unngå helt:** streaks ("X dager i rad"), "heavy smoker"-rammer, noe som kobler belønning til *mengde konsum* per tidsenhet. Belønn bredde, kunnskap og bidrag — ikke frekvens.

---

## M. User levels (forslag)

Ikke count-basert ("nivå = antall logger / 10"), men **kunnskaps- og bredde-basert**, denormalisert som `level_code` på User-tabellen, regnet om ved hver check-in/badge:

1. Nybegynner
2. Utforsker
3. Kjenner
4. Connoisseur
5. Arkivar
6. Kurator
7. Mester-kurator
8. Vitola-legende

Hvert nivå låses opp av en kombinasjon av badges (bredde i merker/former/smaker), ikke av rå mengde. Vises subtilt i Profil — ikke som en XP-bar som dominerer appen.

---

## N. Monetiseringsmodell

Tre nivåer, der **skann-kvote og humidor-størrelse** er de primære knappene (fordi det er disse som driver OpenAI/OCR-kostnad):

| Nivå | Pris (forslag) | Skann/mnd | Humidor-størrelse | Annet |
|---|---|---|---|---|
| **Gratis** | 0 | 10 | 25 sigarer | Full journal-funksjon, badges |
| **Plus** | ~39 kr/mnd | 50 | Ubegrenset | Eksport av journal, prioritert matching |
| **Collector** | ~79 kr/mnd | Ubegrenset (fair use) | Ubegrenset | Avansert statistikk, tidlig tilgang til nye funksjoner |

**Viktig:** ingen tier skal love "ubegrenset AI" uten en fair-use-grense i de tekniske vilkårene — caching (punkt O) gjør at "ubegrenset" i praksis er billig fordi de fleste skann aldri når OpenAI.

---

## O. Kostnadskontroll / caching-strategi

Oppslagsrekkefølge ved hvert skann (billigst → dyrest):

```
1. Lokal DB (eksakt match på normalisert tekst)        ~0 kr
2. Fuzzy-søk i lokal DB (typos/forkortelser)            ~0 kr
3. ScanResult-cache (image_signature ELLER text_signature)  ~0 kr
4. OpenAI Vision (kun hvis 1-3 ikke gir treff > terskel) ~kostnad
```

- **image_signature**: perceptual hash av bildet — fanger "samme bånd skannet på nytt"
- **text_signature**: hash av OCR-normalisert tekst — fanger "samme tekst, annet bilde/vinkel"
- Hver gang OpenAI faktisk brukes, lagres resultatet i ScanResult slik at *neste* person (eller du selv) som skanner samme bånd treffer cache i steg 3
- Apple Vision OCR (gratis, on-device) brukes alltid først for selve tekstutrekkingen — OpenAI Vision er kun fallback for *tolkning*, ikke for OCR i seg selv
- Denne arkitekturen er det som gjør at "ubegrenset skann" i Collector-tier (punkt N) er økonomisk forsvarlig: jo flere brukere, jo høyere cache-hit-rate, jo lavere marginalkost per skann

---

## P. MVP+ backlog (bygg nå / neste)

- Scan → match-motor med 4-stegs oppslag (lokal DB → fuzzy → cache → OpenAI)
- Confidence-routing (høy/medium/lav) med riktig microcopy
- Check-in-flow (rating + tags + notat, 15-30 sek mål)
- Humidor med status-filter (Mine/Wishlist)
- Journal (kronologisk historikk, filtrerbar)
- Etterregistrering av form (visuell picker)
- Badge-kategori 1-5 (Journal, Collector, Vitola/Format, Shape Contribution, Tasting)
- Gratis/Plus/Collector-betalingsgating på skann-kvote og humidor-størrelse

## Q. Should-have backlog

- Badge-kategori 6 (Origin/Brand "Kapittel")
- User levels (1-8) med beregningslogikk
- Eksport av journal (PDF/CSV) for Plus/Collector
- Avansert statistikk i Profil (smaksprofil over tid, mest loggede merker)
- Push-varsler **kun** for ikke-konsumdrevet innhold (f.eks. "Du har nådd 50 logger")

## R. Nice-to-have backlog

- CigarCard som delbart bilde (nøytral utforming, ingen kjøpslenker)
- Multi-språk støtte (norsk/engelsk)
- Bedre fuzzy-matching (Levenshtein-tuning basert på faktiske feilmatcher)
- Admin-dashboard for å se ShapeContribution-data og rydde i merkedata

## S. Later / community backlog

- Discover/Feed (sosial visning av andres check-ins)
- Badge-kategori 7 (Community)
- CommunityContribution (brukerinnsendte sigar-data, krever moderering)
- Følge andre brukere / kommentere

---

## T. Risikoer

- **App Store-avslag**: tobakksrelaterte apper granskes ekstra. Hold deg strengt til journal/arkiv-framing, ingen kjøpslenker, ingen affiliate, ingen "kjøp nå"-CTA noe sted.
- **Norsk tobakkslovgivning**: markedsføringsforbud for tobakk gjelder også digitalt — appen må aldri kunne tolkes som reklame for et produkt eller merke. Sigarkort skal se ut som arkivkort, ikke produktbilder til salg.
- **OpenAI-kostnadseksplosjon**: uten caching (punkt O) skalerer kostnad lineært med skann — caching er ikke en "nice to have", det er en forutsetning for at modellen i punkt N går opp.
- **Lav retention uten sosial krok**: uten feed/community kan engasjement falle etter første "samle alt jeg har"-fase. Badges/levels (L/M) er det som skal holde folk inne uten å bygge et fullt sosialt produkt for tidlig.
- **Datakvalitet på shape/format**: lav-confidence-flows og ShapeContribution er ubekreftet brukerdata — bør valideres/aggregeres (f.eks. "minst 3 brukere er enige") før det skrives tilbake til `Cigar.shape` automatisk.

---

## U. Hva du bør bygge først (neste 1-2 uker)

Rekkefølge er valgt slik at hver del er testbar alene og bygger på det forrige:

1. **HumidorItem.status-felt** (wishlist/owned/smoked_out) — liten endring, låser opp hele punkt G/H-flyten
2. **Check-in-flow** (punkt F) — kjernehandlingen i appen, den som faktisk genererer verdi (journal-data)
3. **ScanResult-tabell + cache-oppslag i matchemotoren** (punkt O) — gjør dette *før* du skalerer skann-volum, ikke etter
4. **Confidence-routing** (punkt E) — kobler skann-flyten til riktig skjerm basert på score
5. **Visuell shape-picker** (punkt I) — du har allerede 0 null-shapes i databasen for 10 merker, så dette handler nå om å fange *nye* merker brukere skanner

Det som **ikke** bør bygges nå: badges/levels (M/L), monetisering/betalingsgating (N), og alt i Discover/Feed. De gir ingen verdi før kjerneloopen (skann → logg → se i journal) faktisk fungerer og brukes.
