# Vitola Android — paritet-sjekkliste

Status for Android-appen sammenlignet med iOS. Oppdateres etter hvert som vi jobber.
Sist oppdatert: 2026-07-17

Tegnforklaring: ✅ ferdig · 🟡 delvis · ⬜ mangler

---

## Kjerneflyter (ferdig)

- ✅ Feed: alle innlegg, likes, kommentarer, nytt innlegg m/bilde, del, detaljvisning
- ✅ Feed: klikk forfatter → begrenset profil
- ✅ Utforsk: søk (merke/serie/form + smaksnoter), treff-teller
- ✅ Utforsk: avansert filter (alle iOS-kategorier), søkehistorikk
- ✅ Utforsk: Brukernes topp 3 + Dagens utvalgte
- ✅ AI-skanning av sigarbånd (scan-cigar Edge Function)
- ✅ Humidor: liste, opprett (m/type-forklaringer), legg i humidor, detalj
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
- ⬜ Ønskeliste («Legg i ønskeliste»)
- ⬜ Legg til sigar manuelt (når AI/søk ikke finner den)
- ⬜ Rapporter feil på en sigar
- ⬜ Hurtighandlinger ved langt trykk

### Humidor
- ⬜ Rediger / slett humidor
- ⬜ Cover-bilde på humidor
- ⬜ Flytt sigar mellom humidorer / fjern sigar
- ⬜ Tell ned antall ved «Marker som røkt»

### Feed
- ⬜ 3-prikks-meny på innlegg (slett eget, rapporter, blokker)

### Skanning
- ⬜ Strekkode-skanning
- ⬜ On-device OCR + form/wrapper-avklaring før AI (Android går rett på AI)

### Konto / oppstart
- ⬜ Aldersbekreftelse + personvern-samtykke
- ⬜ Onboarding av navn etter første innlogging
- ⬜ PIN-kodelås
- ⬜ Innlogging med Apple og e-post (har kun Google)

### Bilder
- ⬜ Beskjæring (cropper) ved opplasting
- ⬜ Cover-bilde på profil

### Admin
- ⬜ Hele admin-delen (datahull, fyll sigar, kø)

### Journal
- 🟡 Redigering mangler del-vurderinger (trekk/brenning/smak) og bilde-bytte

---

## iOS-restanse
- ⬜ Feed: forfatter → profil-lenke
- ⬜ Profil: «Legg til venn»-knapp (bruk request_friendship-RPC)
