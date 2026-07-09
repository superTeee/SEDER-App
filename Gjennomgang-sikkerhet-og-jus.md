# Vitola — gjennomgang av kode, sikkerhet og norsk regelverk

*9. juli 2026. Kodegjennomgang kjørt på Claude Fable mot iOS-koden og alle Supabase-migrasjoner. Juridisk kartlegging kjørt mot primærkilder (Lovdata, Helsedirektoratet, Datatilsynet, EU-domstolen).*

---

## Del 1 — Sikkerhet

### Kritisk: tre hull i backend-SQL-en

Alle tre er verifisert direkte i migrasjonsfilene. De ligger i de sosiale funksjonene — de nyeste delene av appen.

#### 1. `get_feed()` lar hvem som helst lese hvem som helst sin feed

`supabase/migrations/075_post_reports_and_user_blocks.sql:112`

```sql
CREATE OR REPLACE FUNCTION public.get_feed(p_user_id UUID, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
...
LANGUAGE sql STABLE SECURITY DEFINER
```

Funksjonen kjører som eier (`SECURITY DEFINER`) og tar brukerens ID som **parameter fra klienten**. Den kaller aldri `auth.uid()`. Enhver innlogget bruker kan sende inn en fremmed UUID og få tilbake det offerets feed — inkludert offerets venners innlegg og koblede smakslogger. RLS på `posts` omgås fullstendig.

**Fiks:** fjern `p_user_id` og bruk `auth.uid()` inne i funksjonen. Klienten (`FeedService.swift:20`) slutter å sende ID.

#### 2. `toggle_post_like()` lar deg like og avlike som andre brukere

`supabase/migrations/072_feed.sql:212`

```sql
CREATE OR REPLACE FUNCTION public.toggle_post_like(p_post_id UUID, p_user_id UUID)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
```

Samme feil: `SECURITY DEFINER` med klientstyrt `p_user_id`. Den INSERT-er og DELETE-r i `post_likes` på vegne av hvilken som helst bruker. `search_path` er riktig satt, men det hjelper ikke her.

**Fiks:** dropp parameteren, bruk `auth.uid()`. Klienten: `FeedService.swift:94`.

#### 3. Vennskap kan forfalskes

`supabase/migrations/003_friends.sql:106-108`

```sql
create policy "friendships_update_recipient"
  on friendships for update
  using (auth.uid() = recipient_id);
```

Policyen har `USING`, men **ingen `WITH CHECK`**. `USING` sjekker raden slik den var *før* oppdateringen; `WITH CHECK` sjekker den *etter*. Uten den siste kan mottakeren skrive om raden fritt.

Angrepet: konto A oppretter en forespørsel til konto B (insert-policyen krever bare at `requester_id = auth.uid()`, mottakeren er fri). B — som er mottaker og dermed består `USING` — oppdaterer raden og setter `requester_id` til offerets UUID og `status = 'accepted'`. Resultatet er et akseptert vennskap med en person som aldri ble spurt.

Det låser opp offerets innlegg (`posts_select` i 072), private humidor (`humidor_friends_select_public` i 041), profil (`profiles_friends_select` i 041) og `get_friend_profile`.

**Fiks:** legg til `WITH CHECK` som fryser `requester_id` og `recipient_id`, eller flytt godta/avslå til en `SECURITY DEFINER`-RPC som bare får endre `status`.

---

### Bør fikses

**E-postregistrering er brukket.** `AuthService.swift:122` sender `redirectTo: vitola://auth/callback`, men `vitola` er ikke registrert i `CFBundleURLSchemes` — hverken i `Info.plist` eller `project.yml`. Bare Google-skjemaet ligger der. Bekreftelseslenken i e-posten kan altså ikke åpne appen, og `handleDeepLink` kjører aldri.

**`lookup_barcode` og `save_barcode` mangler `SET search_path`.** `045_cigar_barcodes.sql:41` og `:62`. De eneste gjenværende `SECURITY DEFINER`-funksjonene uten den. Kjent privilege-escalation-vektor.

**`post_likes` og `post_comments` er lesbare for alle innloggede.** `072_feed.sql:64` og `:87` bruker `USING (auth.uid() IS NOT NULL)`. Kommentarinnhold lekker på innlegg man ikke har tilgang til.

**Storage-policyer finnes ikke i migrasjonene.** `log-photos`, `humidor-photos` og `avatars` er opprettet manuelt i Dashboard. `037_tasting_logs_photo.sql:14` sier det rett ut. Det er konfigurasjonsdrift — miljøet kan ikke reproduseres eller revideres.

**`fetchOcrVocabulary` er kappet på 1000 rader.** `CigarService.swift:402`. Ingen `.range()`-paginering. OCR-vokabularet mangler alle merker etter rad ~1000, så skanning av dem blir dårligere.

**Ingen paginering i feed, journal eller stats.** `FeedView.swift:179` henter 50 innlegg uten «last flere». `TastingService.fetchLogs` og `ProfileService.fetchOwnStats` treffer 1000-rads-taket.

**`fetchRecentLogs` for venner kan aldri returnere data.** `ProfileService.swift:82`. Eneste SELECT-policy på `tasting_logs` er `auth.uid() = user_id` (`001_initial_schema.sql:122`). Kall med en venns ID gir stille tom liste.

**Død kode.** `Views/Cigar/CigarDetailView.swift` — 1367 linjer, instansieres ingen steder. `CigarDetailViewDesign` er den som brukes.

---

### Det som faktisk er bra

Ingen `try!`, `as!` eller force-unwraps. Ingen tomme `catch {}`. Konsekvent `@MainActor` på alle ObservableObjects og `[weak self]` der det trengs. PIN-koden ligger SHA256-hashet i Keychain, ikke i UserDefaults. Ingen ATS-unntak. Ingen hemmeligheter i kildekoden — OpenAI-nøkkelen er server-side. RLS er slått på for samtlige tabeller. `print()`-kallene logger ingen tokens eller e-poster. Storage-stiene håndterer lowercase-kravet konsekvent og dokumentert.

For et soloprosjekt er Swift-koden uvanlig ryddig. Svakhetene ligger nesten utelukkende i SQL-en for de sosiale funksjonene.

Det finnes ingen `.swiftlint.yml`. Stilen er likevel påfallende konsistent.

---

## Del 2 — Norsk regelverk

### Det viktigste: røykejournalen er sannsynligvis helseopplysninger

Dette er funnet med størst praktisk konsekvens.

Artikkel 29-gruppen (nå EDPB) skrev i sin uttalelse om helsedata i apper fra 2015 at helseopplysninger omfatter *«information about a person's excessive alcohol consumption, tobacco consumption or drug use»*, og at data som logges systematisk **over tid** lettere blir helsedata enn en enkeltregistrering. EU-domstolen bekreftet en svært bred tolkning i C-21/23 (Lindenapotheke, oktober 2024): til og med bestillingsdata for reseptfrie apotekvarer er helseopplysninger.

Vitolas røykejournal er nettopp en systematisk, identifiserbar logg over én persons tobakksbruk over tid. Det treffer kjernen i uttalelsen.

Motargumentet — at dette er hobbydata om sigarnytelse, ikke helse — er reelt, og spørsmålet er ikke rettslig avgjort for denne typen app. Men rettsutviklingen går entydig i én retning, og risikoen ved å ta feil ligger hos den behandlingsansvarlige. Behandle det som helseopplysninger.

**Konsekvens:** behandlingen krever **uttrykkelig, separat samtykke** etter GDPR art. 9 nr. 2 a. Ikke bakt inn i en generell «jeg godtar personvernerklæringen»-avkrysning.

| Data | Behandlingsgrunnlag |
|---|---|
| Konto, e-post, visningsnavn, avatar, humidor, venneliste | Art. 6 nr. 1 b — avtale |
| Røykejournal, bilder og notater om egen røyking | Art. 6 nr. 1 a + **art. 9 nr. 2 a — uttrykkelig samtykke** |
| Innlegg brukeren selv publiserer i feeden | Uttrykkelig samtykke (art. 9 nr. 2 e er støtteargument, ikke fundament) |
| Sikkerhet, misbruksbekjempelse, moderering | Art. 6 nr. 1 f — berettiget interesse |

### Personvernerklæringen skal ikke «godtas»

Dagens flyt krever at brukeren godkjenner personvernerklæringen én gang. Det er faktisk uheldig. Erklæringen er oppfyllelse av **informasjonsplikten** (art. 12–13), ikke et samtykke. Å pakke alt inn i én avkrysning blander behandlingsgrunnlagene og gjør samtykket ugyldig som «bundling».

Riktig: erklæringen presenteres som informasjon med lenke. Det som krever aktiv, separat avkrysning er helseopplysningene — altså røykeloggen.

Erklæringen må inneholde alt art. 13 krever: identitet og kontaktinfo, formål og grunnlag **per formål**, den berettigede interessen der 6(1)(f) brukes, mottakere (Supabase, Apple, Google), tredjelandsoverføring og garantigrunnlag, lagringstid, rettighetene, retten til å trekke samtykke, klagerett til Datatilsynet, og om avgivelse er nødvendig for avtalen.

### Tobakksreklame: du er innenfor — men grensen er absolutt

Tobakksskadeloven § 22: *«Alle former for reklame for tobakksvarer er forbudt.»* Reklameforskriften definerer reklame som **«massekommunikasjon i markedsføringsøyemed»**. Det avgjørende er formålet.

Helsedirektoratets veileder sier eksplisitt at forbudet gjelder i *«alle typer medier, inklusive sosiale medier, blogger på Internett og mobiltjenester/applikasjoner»*. Apper er uttrykkelig omfattet. Veilederen nevner også **humidor som «tobakksutstyr»** — forbudet dekker reklame for utstyr.

To unntak redder en deskriptiv app (reklameforskriften § 8):

**Redaksjonell omtale** — omtale presentert med redaksjonell frihet, ikke utformet, påvirket eller finansiert av produsent, importør, grossist, agent eller forhandler.

**Private ytringer** — privatpersoner kan omtale tobakk fritt, med mindre ytringen skjer på vegne av en tobakksvirksomhet eller personen **oppnår fordeler** ved den.

En oppslagsdatabase uten salg, priser, kjøpslenker, affiliate eller annonser mangler markedsføringsøyemed og ligger utenfor reklamedefinisjonen. Merkenavn og bilder av sigarbånd er beskrivelse, ikke markedsføring. Brukernes egne bilder er private ytringer.

Dette er ikke rettslig avklart for apper spesifikt — det finnes ingen publisert sak. Men grensen er tydelig: **den krysses i det øyeblikket Vitola får én kommersiell kobling til bransjen.** Én affiliate-lenke, én sponsor, én kasse gratis sigarer til omtale. Helsedirektoratet fører tilsyn (§ 35) og kan gi pålegg om retting og tvangsmulkt (§ 36), overtredelsesgebyr (§ 36a); forsettlig overtredelse straffes med bøter (§ 44).

Det bør derfor være en absolutt forretningsregel, og modereringen bør håndheve den også for brukerinnhold: forhandlere som poster tilbud, rabattkoder, «ambassadører» med gratisprodukter — alt dette må fjernes.

**Ingen helseadvarsel kreves i appen.** Kravene i tobakksskadeloven kap. 7 gjelder merking av pakninger og produkter, ikke apper eller nettsider.

### Aldersgrense: ikke lovpålagt, men behold den

§ 17 setter 18-årsgrense for **salg, overlatelse og innførsel** av tobakksvarer — ikke for å lese informasjon om dem. Det finnes ingen norsk hjemmel som krever aldersport for deskriptivt tobakksinnhold.

Behold den likevel: Apple forventer 18+ rating, og mindreårige kan etter Datatilsynets veiledning ikke selv samtykke til behandling av **sensitive** opplysninger — som røykeloggen sannsynligvis er. Aldersporten støtter altså samtykkets gyldighet.

En enkel «bekreft at du er over 18» holder. Sterk aldersverifisering kreves ikke.

### DSA og brukergenerert innhold

DSA (forordning 2022/2065) er **ennå ikke norsk lov**. Digitaltjenesteloven var på høring juli–oktober 2025 med mål om ikrafttredelse sommeren 2026, men står ikke på listen over regelendringer fra 1. juli 2026. Nkom blir koordinator.

DSA gjelder likevel etter sitt eget virkeområde for tjenester som tilbys brukere i EU. Vitola er globalt tilgjengelig, så appen er formelt innenfor allerede — men håndhevingsrisikoen for en hobbyskala-app er svært lav frem til norsk gjennomføring.

Vitola lagrer brukerinnhold og sprer det offentlig → **vertstjeneste**, trolig også «nettbasert plattform». Som **mikrobedrift** er du unntatt plattformpliktene i art. 20–28 (intern klageordning, tvisteløsning, trusted flaggers) etter art. 19, og fra transparensrapportering etter art. 15 nr. 2.

Det som gjelder uansett størrelse:

**Art. 16** — meldefunksjon for ulovlig innhold, elektronisk og lett tilgjengelig, også for ikke-brukere, med mulighet for begrunnelse og kontaktinfo.

**Art. 17** — begrunnelse til brukeren når innhold fjernes eller konto suspenderes.

**Art. 14** — vilkårene må beskrive modereringspraksis.

Du har allerede rapportering og blokkering. Utvid rapporteringen til å fungere uten innlogging, og send begrunnelse ved fjerning.

### Øvrige plikter

**Databehandleravtale med Supabase (art. 28) er påkrevd.** Supabase tilbyr en standard-DPA som må aktivt inngås. Verifiser at prosjektet ligger i EU-region. Supabase er ikke sertifisert under EU–US Data Privacy Framework; DPA-en bruker standardkontraktsvilkår (SCC) for eventuell tilgang fra USA. Det er et gyldig overføringsgrunnlag, men skal omtales i erklæringen.

**Behandlingsprotokoll (art. 30) er påkrevd.** Unntaket for virksomheter under 250 ansatte gjelder ikke når behandlingen ikke er sporadisk *eller* omfatter særlige kategorier. Begge deler slår til. Datatilsynet har mal — et regneark holder.

**Personvernombud:** ikke påkrevd. Krever kjernevirksomhet med sensitive data «i stor skala».

**Melding til Datatilsynet:** finnes ikke lenger som generell plikt. Kun avviksmelding ved brudd (art. 33, 72 timer). Ha en enkel rutine.

**Sletting (art. 17):** slett-konto-funksjonen dekker kjernekravet. Sørg for at sletting faktisk fjerner Storage-bilder, og at backups roteres ut innen definert tid.

**Brukervilkår (ToS)** er ikke lovpålagt, men reelt nødvendige: lisens til brukeropplastet innhold, forbud mot salgsfremmende tobakksinnhold (din § 22-beskyttelse), modererings- og utestengingsregler, ansvarsbegrensning, lovvalg.

---

## Prioritert liste

### Må fikses før lansering

1. `get_feed()` — bruk `auth.uid()`, ikke klientparameter
2. `toggle_post_like()` — bruk `auth.uid()`, ikke klientparameter
3. `friendships_update_recipient` — legg til `WITH CHECK`
4. Registrer `vitola://` som URL-skjema (e-postregistrering er brukket)
5. Uttrykkelig, separat samtykke for røykeloggen (GDPR art. 9 nr. 2 a)
6. Personvernerklæring som oppfyller art. 13 — og slutt å kreve «godkjenning» av den
7. Signer databehandleravtale med Supabase, bekreft EU-region
8. Behandlingsprotokoll etter art. 30
9. Brukervilkår med forbud mot salgsfremmende tobakksinnhold
10. Absolutt forretningsregel: null kommersiell kobling til tobakksbransjen

### Bør fikses

11. `SET search_path` på `lookup_barcode` og `save_barcode`
12. Stram SELECT-policyene på `post_likes` og `post_comments`
13. Kodifiser storage-buckets og policyer i migrasjoner
14. Paginer `fetchOcrVocabulary`, feed, journal og stats
15. Fjern eller fiks `fetchRecentLogs` for venner
16. Slett `CigarDetailView.swift` (1367 linjer død kode)
17. Utvid rapportering til DSA art. 16-nivå; begrunnelse ved fjerning (art. 17)
18. 18+ rating i App Store Connect
19. Strip EXIF/GPS fra opplastede bilder
20. Avviksrutine for personvernbrudd (art. 33)

---

## Konklusjon

**Største tekniske risiko:** `get_feed()`. Enhver innlogget bruker kan lese hvem som helst sin feed i dag. Det er et halvtimes fiks.

**Største juridiske risiko:** GDPR artikkel 9. Røykejournalen er etter beste tolkning en systematisk logg av helseopplysninger, og behandles i dag uten det uttrykkelige samtykket loven krever. Det gjelder samtlige brukere hver dag, Datatilsynet er en aktiv tilsynsmyndighet, og det er enkelt å rette.

**Tobakksreklameforbudet** er en risiko i ytterkant — lav i dag, og fullt kontrollerbar. Den materialiserer seg først den dagen appen tar imot penger eller produkter fra bransjen.

---

*Den juridiske delen er research mot primærkilder, ikke juridisk rådgivning. Enkeltvurderinger — særlig art. 9-spørsmålet og grensene for reklameforbudet i apper — er ikke rettslig avklart for denne typen tjeneste. Det er verdt en time hos jurist med personvern- og markedsføringskompetanse før enhver inntektsmodell som berører tobakksbransjen, og ved utforming av samtykketeksten for helseopplysninger.*

**Kilder:** [Tobakksskadeloven §§ 17, 22, 23, 35–36a, 44](https://lovdata.no/lov/1973-03-09-14) · [Reklameforskriften §§ 4 og 8](https://lovdata.no/dokument/SF/forskrift/1995-12-15-989) · [Helsedirektoratets veileder, kap. 4](https://www.helsedirektoratet.no/veiledere/tobakksskadeloven/reklameforbud) · [WP29 om helsedata i apper (2015)](https://ec.europa.eu/justice/article-29/documentation/other-document/files/2015/20150205_letter_art29wp_ec_health_data_after_plenary_annex_en.pdf) · [EU-domstolen C-21/23](https://curia.europa.eu/site/upload/docs/application/pdf/2024-10/cp240159en.pdf) · [Datatilsynet om særlige kategorier](https://www.datatilsynet.no/rettigheter-og-plikter/virksomhetenes-plikter/om-behandlingsgrunnlag/spesielt-om-sarlige-kategorier-av-personopplysninger/) · [GDPR art. 9 og 13](https://lovdata.no/lov/2018-06-15-38/gdpr/ARTIKKEL_9) · [DSA 2022/2065](https://eur-lex.europa.eu/legal-content/en-fr/TXT/?uri=CELEX%3A32022R2065) · [Supabase DPA](https://supabase.com/legal/dpa)
