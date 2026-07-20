# Vitola Android — paritet-sjekkliste

Status for Android-appen sammenlignet med iOS. Oppdateres etter hvert som vi jobber.
Sist oppdatert: 2026-07-20

### Feed → Aktivitet + deling (paritet)
- ✅ Backend: migrasjon 115 (delings-felt på tasting_logs) + get_activity/set_entry_sharing/get_public_journal_entry + public-journal edge function — delt
- ✅ Fane «Feed» → «Aktivitet» (scrollbar liste av delte journal-hendelser: rating/bilde/notat + «＋ ønskeliste», trykk → sigar). Journal beholdt som egen fane — begge plattformer
- ✅ Del-etter-lagring-ark (Del i appen / Del eksternt) koblet på journal-logging; ekstern deling → native delings-ark med offentlig lenke — begge plattformer
- 🟡 Del-prompt kun på hoved-logg (CigarDetail). Hurtighandling-logg + journal-redigering mangler prompten. iOS-QuickActions/JournalView + Android tilsvarende: TODO
- 🟡 Offentlig lenke peker på edge-funksjonen midlertidig; pen vitola.app/j-URL + universal links (AASA/assetlinks + entitlements) gjenstår

### Kvittering → humidor (paritet)
- ✅ parse-receipt edge function (GPT-vision leser varelinjer + match_cigar-matching) — delt backend
- ✅ «Legg til sigarer fra kvittering» i +-menyen på Humidor-fanen (ny meny: Ny humidor / Kvittering) — begge plattformer
- ✅ Bekreft-skjerm: standard-humidor for alle + overstyring per rad, antall/pris redigerbart, ukjente varer → «Legg til manuelt» — begge plattformer
- 🟡 Android kamera bruker thumbnail (TakePicturePreview); galleri gir full oppløsning. iOS bruker full kamera-oppløsning. Vurder full-res kamera (FileProvider) senere.

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
