# Vitola Android — paritet-sjekkliste

Status for Android-appen sammenlignet med iOS. Oppdateres etter hvert som vi jobber.
Sist oppdatert: **2026-08-19** (full gjennomgang av iOS-kodebasen)

---

# 🔍 GAP-ANALYSE 19. aug 2026

Full sammenligning av iOS-kodebasen mot Android. Sortert etter hvor mye det haster.

## 🔴 1. Play Store-samsvar — Android har IKKE fått 1.4.3-oppryddingen

iOS ble avvist av Apple under retningslinje 1.4.3 (oppmuntrer til tobakkskonsum) og
ble ryddet 10.–12. aug. **Ingenting av dette er gjort på Android.** Google Play har
tilsvarende regler for tobakksinnhold, så dette er sannsynligvis en avvisning som
venter på å skje.

| Grep gjort på iOS | Android-status |
|---|---|
| Aktivitet-fane + venner FJERNET fra navigasjonen | ❌ `ui/activity/ActivityScreen.kt` (453 l) + `FriendsScreen.kt` fortsatt aktive |
| Alle flamme-/røyk-ikoner fjernet | ❌ `LocalFireDepartment` i ExploreScreen, CigarDetailScreen, UserProfileScreen, MerkerSheet |
| «Marker som røkt» → «Loggfør sigar» | ❌ «Marker som røkt» i ExploreScreen, CigarDetailScreen (×2), SmokingLogSheet (×2) |
| Gamifisert konsum-milepæl + community-signal fjernet | ❌ ikke sjekket/ryddet |
| Copy omrammet mot journal/oppslagsverk | ❌ ikke gjort |
| Rating-adjektiver («Fremragende») fjernet | ✅ gjort 19. aug |
| Regionsstyrt aldersgrense (21 USA / 18 ellers) | ✅ gjort 19. aug |

## 🔴 2. Betaling — plattformene har divergert helt

iOS gikk fra RevenueCat-abonnement til **StoreKit 2 med engangs livstids-Pro + tips**.
Android står igjen på den gamle modellen.

| | iOS (nå) | Android (nå) |
|---|---|---|
| Motor | StoreKit 2 direkte (`StoreManager.swift`) | RevenueCat (`ProManager.kt`, `VitolaApplication.kt`) |
| Pro | Engangs livstid `no.sederappen.pro.lifetime` ~599 kr | Abonnement `seder_pro_monthly` / `_yearly` |
| Tips | 3 consumables (19/49/99 kr) + `SupportView` to modus | ❌ finnes ikke |
| Blokkering | — | Venter fortsatt på Play-konto + `goog_`-nøkkel |

**Konsekvens:** Android selger et produkt iOS ikke lenger har. Må bygges om til
Play Billing med livstidskjøp + tips før lansering, ellers blir prismodellen
inkonsistent på tvers.

## 🟠 3. Funksjoner som mangler helt i Android

| iOS-fil(er) | Linjer | Android |
|---|---|---|
| `Scan/BarcodeScannerView.swift` + `UnknownBarcodeView.swift` + `Services/BarcodeService.swift` | 704 + 250 + 170 | ❌ ingen strekkode-skanning |
| `Admin/AdminView.swift` + `CigarFillSheet.swift` + `Services/AdminService.swift` | 436 + 213 + 396 | ❌ ingen admin (merk: `web/admin.html` dekker dette — trolig bevisst) |
| `Scan/MacroCameraView.swift` | 245 | ❌ ingen makro-kamera |
| `Shared/FeedbackSheet.swift` + `MailComposeView.swift` | 170 + 82 | ❌ ingen tilbakemeldings-ark |

## 🟠 4. Skann-motoren henger etter

`Services/ScanService.swift` (883 l) vs `data/ScanRepository.kt` (330 l).
iOS fikk 19. aug (commit 9da8020) to ting Android mangler:

- **Nedskalering av bilde før analyse** — uten dette kan edge-funksjonen bli drept (HTTP 546) på store telefonbilder
- **«Vi leste: X»-chip ved bom** + forhåndsutfylling av manuell innlegging

I tillegg: `Scan/ResultsView.swift` (994 l) har ingen tilsvarende dybde på Android.

## 🟡 5. Skjermer som er vesentlig tynnere

Ikke nødvendigvis feil, men verdt en visuell sammenligning:

| Skjerm | iOS | Android |
|---|---|---|
| Utforsk | 2406 | 941 |
| Legg til sigar manuelt | 444 | 120 |
| Cigar-detalj | 851 | 449 |
| Profil (egen) | 545 | 571 ✅ |
| Humidor-detalj | 753 | 685 ✅ |

## Anbefalt rekkefølge
1. **1.4.3-opprydding på Android** (blokkerer Play-innsending)
2. **Betalingsmodell** (Play Billing: livstid + tips)
3. Skann-nedskalering (stabilitet)
4. Strekkode + tilbakemelding + makro-kamera
5. Utforsk/AddCigar-dybde

---

### Skann-dekning (paritet — klynge A, 26. juli)
- ✅ `log_scan_event`-logging på hvert bånd-skann (treff + bom) → scan_events (dekning-datahjul) — ScanRepository
- ✅ Vennlig «ingen treff»-ark (stiplet spøkelses-sigar + årsaks-liste + prøv-på-nytt/legg-inn-manuelt) — ScanNoMatchSheets.NoMatchSheet
- ✅ Manuell-innlegging fra ingen-treff bruker nå SAMME skjerm som ellers (AddCigarSheet — full felt + vitola-chips); skann-flyt legger sigaren rett i første humidor + snackbar. (Egen ManualAddCigarSheet fjernet — én skjerm på tvers, paritet med iOS)
- 🟡 Båndbildet festes ikke til bidraget ennå (kun OCR-tekst i notat) — samme som iOS v1

### Tab-bar + senter-skann + profil-avatar (paritet — klynge B, 26. juli)
- ✅ Egen tab-bar (VitolaApp): 4 faner (Utforsk · Aktivitet | Journal · Humidor) + hevet senter-skann-knapp; aktiv fane = aksent-flate bak hvitt ikon
- ✅ Profil ut av baren → avatar øverst til venstre på alle fire toppskjermer (TopBarProfileAvatar), åpner profil-ruten
- ✅ Senter-skann åpner skann-ark (Sigarbånd / Bilde fra kamerarull) på Utforsk (scanTick → showScanChooser); gammel «Skann sigar»-FAB fjernet
### Kvittering-oppgradering + skann-ark (paritet — klynge C, 26. juli)
- ✅ Smart forhåndsvalg: `HumidorRepository.lastHumidorByCigar` ruter hver sigar til sist-brukte humidor + «sist her»-hint; nullstilles ved manuell/standard-endring
- ✅ (27. juli, forenkling) Kvittering-arket ryddet: fjernet «Grupper etter humidor», «Legg alle i» og «På kvittering»-tekst + humidor-ikon per rad. «Kjøpt hos» er nå redigerbart inline sammen med dato i toppen (ikke i kort) — begge plattformer
- ✅ Pris/stk per rad fantes fra før (→ purchase_price, vises på detalj)
- ✅ «Kvittering» flyttet inn i skann-arket (senter-knapp) → navigerer til Humidor + åpner kilde-valg (receiptTick). Fortsatt også i Humidor-«+»-menyen.

### Aktivitet: «+» / kontekst-meny / slett (paritet — klynge D, 26. juli)
- ✅ «+» øverst til høyre → ComposePostSheet: søk opp sigar → velg → samme logg-ark (0–100 + notat) → del-tilbud (ShareAfterSaveSheet); gjenbruker CigarRepository.search + SmokingLogSheet, ingen ny backend
- ✅ «...»-meny på hvert kort: eget innlegg → «Slett» (bekreftelses-dialog → JournalRepository.deleteLog + fjern fra lista); andres → «Legg til som venn» (FriendRepository.request + snackbar); begge → «Del» (setSharing→publicSlug→ACTION_SEND)

### Vurdering 0–100 + del-vurderinger (paritet — klynge E, 27. juli)
- ✅ 0–100-poengsum (50–100-slider m/scoreLabel) i logg-arket + intensitets-barer for Styrke/Kropp/Smaksintensitet/Sødme på detaljsiden — fantes allerede fra tidligere arbeid, verifisert mot iOS
- ✅ Nytt i E: sammenleggbart «Detaljer (valgfritt)» i logg-arket med del-vurderinger Trekk/Brenning/Smak (1–5 prikker, trykk igjen = nullstill) → lagres til draw_rating/burn_rating/flavor_rating (samme kolonner journal-redigering allerede leser); addLog + NewLog utvidet

### UI-finpuss (paritet — klynge F, 27. juli)
- ✅ Utforsk-søkefeltet: hvitt (kort-farge i mørk modus) m/svak kant, ikke accent-tone — matcher iOS
- ✅ Kutt-type (Rett / V-snitt / Punch) lagt i hurtiglogg-arkets «Detaljer»-seksjon → cut_type (samme koder som journal-redigering); addLog + NewLog utvidet
- ✅ Verifisert allerede par: vitola-tekst = onSurfaceVariant (mørk secondary) i alle rader/kort; humidor-kort-spacing; filter/tema/journal
- 🟡 Gjenstår kun tyngre logg-ekstra vs iOS: røyk-dato-velger + foto+beskjæring i hurtigloggen (foto finnes allerede i journal-redigering) — egen økt ved behov

### RH-kort: to knapper + historikk-skjerm m/graf (paritet — 27. juli)
- ✅ RH-kortet har nå to knapper i bunnen: «Registrer» (ny måling) + «Historikk» (deaktivert til første måling finnes)
- ✅ Inline historikk-liste flyttet ut av humidor-detalj → egen RH-historikk-skjerm
- ✅ Historikk-skjerm: linjegraf over tid m/mål-bånd (iOS: Swift Charts; Android: Canvas), nøkkeltall (Nå / Snitt / Min–maks), full måleliste
- ✅ Android: ny nav-rute humidorRh/{id} (laster humidor + readings by id); iOS: navigationDestination i HumidorDetailView (ny kode i eksisterende fil pga. ikke-regenererende prosjekt)

### Feed → Aktivitet + deling (paritet)
- ✅ Backend: migrasjon 115 (delings-felt på tasting_logs) + get_activity/set_entry_sharing/get_public_journal_entry + public-journal edge function — delt
- ✅ Fane «Feed» → «Aktivitet» (scrollbar liste av delte journal-hendelser: rating/bilde/notat + «＋ ønskeliste», trykk → sigar). Journal beholdt som egen fane — begge plattformer
- ✅ Del-etter-lagring-ark (Del i appen / Del eksternt) koblet på journal-logging; ekstern deling → native delings-ark med offentlig lenke — begge plattformer
- ✅ Del-prompt også på hurtighandling-logg (langt trykk → «Marker som røkt») — begge plattformer. Journal-redigering utelatt bevisst (å re-spørre om deling ved redigering blir mas).
- 🟡 Offentlig lenke peker på edge-funksjonen midlertidig; pen vitola.app/j-URL + universal links (AASA/assetlinks + entitlements) gjenstår

### Kvittering → humidor (paritet)
- ✅ parse-receipt edge function (GPT-vision leser varelinjer + match_cigar-matching) — delt backend
- ✅ «Legg til sigarer fra kvittering» i +-menyen på Humidor-fanen (ny meny: Ny humidor / Kvittering) — begge plattformer
- ✅ Bekreft-skjerm: standard-humidor for alle + overstyring per rad, antall/pris redigerbart, ukjente varer → «Legg til manuelt» — begge plattformer
- ✅ Android kamera bruker nå full oppløsning (TakePicture + FileProvider → cache/camera, leses tilbake og nedskaleres til 2000px). Paritet med iOS.

### Pris + humidor-verdi (paritet)
- ✅ Prisfelt (kr per sigar) i legg-i-humidor-arket → purchase_price — begge plattformer
- ✅ Humidor-liste viser total inventarverdi (sum pris × antall) — begge plattformer

### Splash + humidor-kort (paritet, build 216)
- ✅ Splash: overlay endret fra sort til #403E3B ved 70 % opasitet, fader inn fra 0 % før logo — begge plattformer
- ✅ Humidor-kort finpuss: pille-padding +2px, luft rundt tittel/metadata +4px, RH-tekst 1px mindre + « % RH» — begge plattformer

Tegnforklaring: ✅ ferdig · 🟡 delvis · ⬜ mangler

---

## Kjerneflyter (ferdig)

- ✅ Feed: alle innlegg, likes, kommentarer, nytt innlegg m/bilde, del, detaljvisning
- ✅ Feed: klikk forfatter → begrenset profil
- ✅ Feed: Facebook-stil (full bredde, hele bildet uten crop, 2 kommentarer forhåndsvist, skillestrek mellom innlegg) — begge plattformer
- ✅ Utforsk: søk (merke/serie/form + smaksnoter), treff-teller
- ✅ Utforsk: avansert filter (alle iOS-kategorier), søkehistorikk
- ✅ Utforsk: Brukernes topp 3 + Dagens utvalgte
- ✅ AI-skanning av sigarbånd (scan-cigar Edge Function)
- ✅ Humidor: liste, opprett (m/type-forklaringer), legg i humidor, detalj
- ✅ RH-logging per humidor: mål-RH/område, RH-kort m/rolig status, «Registrer RH»-ark, historikk (begge plattformer; DB-migrasjon humidor_rh)
- ✅ Journal: liste + rediger/slett innlegg
- ✅ Profil: hero, 4-cellers stats, smaksprofil, sist røkt, avatar-opplasting
- ✅ Innstillinger: konto, tema (system/lys/mørk), endre navn/sted, tilbakemelding, logg ut
- ✅ Begrenset profil + send venneforespørsel + godta/avslå
- ✅ Login-skjerm ved oppstart (kan hoppes over)
- ✅ Splash, app-ikon, smaksnote-ikoner
- ✅ Skrift-skalering begrenset (stor systemtekst bryter ikke layout)

---

## Gjenstår på Android

### Venner
- ✅ Egen Venner-side (venneliste, åpnes fra Venner-ikon i profil)
- ✅ Forespørsel-innboks (innkommende godta/avslå + utgående venter)
- ✅ Søk etter brukere på navn → legg til
- ✅ Vis egen vennekode («Din kode»)
- 🟡 Legg til via andres vennekode (repo-metode finnes; eget kode-felt ikke lagt til — iOS bruker navnesøk)
- ⬜ Push-varsel ved ny forespørsel

### Sigar
- ✅ Favoritter (begge plattformer: stjerne på detalj, «Favoritter»-fane i Humidor, favorittliste på profil erstatter «Merker prøvd», synlig for venner via get_favorites-RPC. Rating/butikk bevisst utelatt i v1)
- ✅ Ønskeliste (bokmerke-toggle på detalj + segmentert «Ønskeliste»-fane i Humidor, som iOS)
- ✅ Legg til sigar manuelt (fra søkeresultat → create_own_cigar, m/foreslå til delt DB)
- ✅ Rapporter feil på en sigar («Meld feil» → report_cigar)
- ✅ Hurtighandlinger ved langt trykk (humidor / røkt / ønskeliste / del)

### Humidor
- ✅ Rediger / slett humidor (3-prikks-meny → rediger-ark / slett m/bekreftelse)
- ✅ Cover-bilde på humidor («Bytt forsidebilde» → humidor-covers-bøtta)
- ✅ Flytt sigar mellom humidorer / fjern sigar (long-trykk på sigar-rad)
- ✅ Tell ned antall ved «Marker som røkt» (dekrementer humidor-oppføring, min 0)

### Feed
- ✅ 3-prikks-meny på innlegg (slett eget, rapporter m/grunn, blokker bruker)

### Skanning
- ⏭️ Strekkode-skanning — bevisst utelatt på Android (Toms valg)
- ✅ On-device OCR (ML Kit) → DB-søk → AI-fallback + form/wrapper-avklaring
  - NB: ML Kit mangler Vision sin vokabular-biasing + pålitelige konfidens, så OCR-delen er en tilnærming

### Konto / oppstart
- ✅ Aldersbekreftelse + personvern-samtykke (oppstartsporter, lagres lokalt)
- ✅ Onboarding av navn etter første innlogging (når display_name mangler)
- ✅ PIN-kodelås (SHA256 i prefs; sett i Innstillinger, opplåsing ved oppstart)
- ✅ Innlogging med Apple (Supabase OAuth) og e-post/passord, i tillegg til Google
  - NB: Apple-provideren må være aktivert i Supabase-dashbordet for at knappen skal virke

### Bilder
- ✅ Beskjæring (cropper) ved opplasting — android-image-cropper koblet inn på avatar (1:1), cover (16:9), humidor-cover (16:9) og feed-innlegg (fritt)
- ✅ Cover-bilde på profil (banner + overlappende avatar, uploadCover → cover_url)

### Admin
- ⬜ Hele admin-delen (datahull, fyll sigar, kø)

### Journal
- ✅ Redigering: del-vurderinger (trekk/brenning/smak, 1–5 prikker) + snitt-type + bilde-bytte

---

## iOS-restanse
- ⬜ Feed: forfatter → profil-lenke
- ⬜ Profil: «Legg til venn»-knapp (bruk request_friendship-RPC)


---

# 🆕 GAP-ANALYSE 3. sept 2026 — iOS-økta 1.–3. sept (stor design/UX-overhaling)

Siden 19. aug har iOS fått en omfattende opprydding. **Ingenting av UI-endringene under er på Android ennå.**

## ✅ Delt backend (Android får gratis — ingen jobb)
- `scan-cigar` edge function v49/v50 — Google Lens autoritativ når den navngir en spesifikk sigar (strukturell skann-fiks, ikke aliaser)
- `claim_founding_number` RPC — gir automatisk gratis livstids-Pro til de 50 første (men Android trenger UI-en)
- `create_own_cigar` is_public-fiks + katalog-opprydding (Casdagli/Raíces m.m.)

## 🔴 A. Designsystem / mørk modus (stort — hele appens uttrykk)
- [ ] Mørk modus som **standard** + full mørk-modus-gjennomgang (treff-siden var hardkodet lys)
- [ ] Sekundærknapper → **outline (Accent 1.2px) + hvit tekst/ikon** overalt
- [ ] Tekstfelt + dropdowns → **outline + hvit tekst** (ikke lys fyll)
- [ ] Score-badges → outline (var fylt latte)
- [ ] Chips/badges (Tidlig tester, score) → latte-kant + hvit tekst
- [ ] Skillestreker → subtil bakgrunnstone (TextSecondary 14%), ikke lys systemstrek
- [ ] **Serif-font fjernet** — system-font overalt (var på sigarnavn + skann-animasjon)
- [ ] FAB-ikon-vekt matcher tab-ikoner; **aktiv fane = FAB-farge (Accent)**; topp-toolbar-ikoner hvite
- [ ] Butikk-forslag-chips: 4px margin rundt raden

## 🔴 B. Founding / Pro
- [ ] Founding-kohort **50** (var 100) + auto gratis livstids-Pro til de 50 første
- [ ] **«Gratulerer»-skjerm** ved lansering med «Pro er låst opp – gratis, for alltid»-kort
- [ ] (Betalingsmodell: Play Billing livstid + tips — fra 19. aug, fortsatt åpen)

## 🔴 C. Journal (stor omlegging)
- [ ] Naviger automatisk til Journal etter **hver** logg (uansett hvor du logget fra)
- [ ] Kompakte journal-kort: lite kvadratisk thumbnail til venstre, nøkkelinfo høyre
- [ ] **Sammenslått detalj+endre-ark**: stort kvadratisk bilde + navn øverst, fullt redigerbart under (ikke lenger to ark)
- [ ] «+»-knapp i journal med velger: Skann sigarbånd / Søk etter sigar / Fra humidoren min
- [ ] «Fra humidoren min» **gruppert per humidor-navn**
- [ ] Fjernet «Del»-ark etter logging; kvadratiske bilde-proporsjoner

## 🟠 D. Crop / bilde
- [ ] Egen crop-ramme: **stort gripbart håndtak**, 40% sentrert kvadrat som standard, primær «Bruk»-knapp under bildet, trygg topp-linje
- [ ] Kamera-utilgjengelig-fallback → bibliotek (unngår krasj uten kamera)
- [ ] **Felles bilde-endre-mønster: «Endre»-pille + «Fjern bilde»** overalt et bilde kan endres
- [ ] Bilde-komprimering ved opplasting (cover 1200px/0.7)

## 🟠 E. Navn / katalog
- [ ] `displayName`-logikk: slå sammen gjentatte ord — «Arturo Fuente Fuente Fuente OpusX» → «Arturo Fuente OpusX»

## 🟡 F. Utforsk / filter / treff
- [ ] Avansert filter: **vertikale** bunn-knapper, **alle chips åpne** (ingen «Se alle»)
- [ ] Treff-siden (ResultsView) full mørk modus + outline-komponenter + tydelig størrelse-velger
- [ ] Verifisering-badge forenklet til binær (Verifisert / Ikke verifisert)

## Merk
- iOS-krasjfiksen (ExploreView delt i AnyView-grupper) er **Swift/SwiftUI-spesifikk** (stack overflow) — gjelder IKKE Android/Compose.

## Fortsatt åpent fra 19. aug (uendret)
1.4.3-opprydding (Aktivitet/venner, flamme-ikoner, «Marker som røkt»→«Loggfør sigar») · Play Billing · strekkode-skann · makro-kamera · tilbakemeldings-ark · skann-nedskalering · tynnere skjermer (Utforsk 941 vs 2406, AddCigar 120 vs 444, Cigar-detalj 449 vs 851).


---

# ✅ VERIFISERT 3. sept 2026 — korreksjon av 19.aug-status

Sjekket faktisk Android-kode (ikke bare sjekklista). Følgende var **allerede gjort** i commit 2455383 (etter 19. aug):
- ✅ **1.4.3-opprydding fullført**: «Marker som røkt» → «Loggfør sigar» (0 treff igjen), flamme-ikoner fjernet (0 treff), Aktivitet/venner-ruter fjernet fra navigasjon.
- ✅ **Founding-feiring finnes** (`FoundingWelcome.kt`, kobler `claim_founding_number`).

**Reelle gjenstående blokkere/gap (oppdatert):**
1. 🔴 **Betalingsmodell** — RevenueCat → Play Billing (livstid + tips). *Blokkert på ekstern oppsett: Play-konto + `goog_`-nøkkel.*
2. 🔴 **Design/UX-paritet fra sept-økta** (seksjon A–F over) — dette er den store reelle kodejobben nå.
3. 🟠 Verifiser at founding-cap = 50 og at «Pro låst opp»-kortet vises (matcher iOS).
4. 🟡 Strekkode, makro-kamera, tilbakemelding, tynnere skjermer (uendret).

---

## UTFØRT 3. sept 2026 — visuell + strukturell parity

Design-system (delte komponenter → slår igjennom app-vidt):
- Dark mode som standard (ThemeState).
- ScoreBadge → outline (Accent-kant + hvit tekst).
- Ny delt `SecondaryButton` (1.2dp Accent + hvit tekst/ikon) — rullet ut på
  cigar-detalj, humidor-detalj, utforsk, skann-treff, del-sheet, profil.
- Aktiv tab = Accent-pille + hvitt ikon (matcher FAB).
- Skillelinjer → diskret sekundærtone @ 14%.
- Chips (vitola / butikk / filter) + «Tidlig tester»/nivå-badge → outline,
  fylt Accent når valgt.

Strukturelt:
- `Cigar.displayName` (dedup av gjentatte ord, speiler iOS) + brukt i journal.
- Journal-kort → kompakt rad med lite kvadratisk miniatyrbilde (var stort topp-bilde).
- Ny delt `EditablePhoto` (Endre-pille + Fjern bilde + placeholder) i journal-endre-sheet.
- `JournalRepository.updateLog(clearPhoto=…)` — kan nå fjerne bilde (var umulig).
- Avansert filter: alle chips alltid åpne (fjernet «Se alle»); vertikale bunnknapper.
- Founding-cap 100 → 50 (matcher iOS + server-RPC).

Gjenstår:
- Foto-opplasting i loggfør-/legg-i-humidor-sheets (Android mangler helt; trenger repo-endring).
- EditablePhoto på cigar-detalj / humidor-detalj / profil (immediate-upload; trenger server-remove).
- Betaling: RevenueCat/Play Billing (blokkert — trenger Play-konto + goog_-nøkkel).
