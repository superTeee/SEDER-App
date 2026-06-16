# Cigar App — Produktstrategi & MVP-plan

> "Shazam for sigarer" — en identifikasjonsapp for nybegynnere og samlere

---

## 1. Kritisk vurdering

### Er dette et reelt problem?
**Ja.** Sigar-verden er uoversiktlig og lite digital. Nybegynnere vet sjelden hva de røyker, og det finnes ingen dominant app som løser dette. Vin har Vivino. Whisky har Distiller. Sigarer har ingenting tilsvarende.

### Hvem er målgruppen?
To tydelige segmenter:

**Primær: Nybegynnere (18–40 år)**
Røyker sigarer av og til, på fest, reise eller sammen med venner. Vil forstå mer, men vet ikke hvor de skal starte. Frustrerte over å ikke kjenne igjen hva de røyker.

**Sekundær: Entusiaster og samlere**
Har allerede en humidor. Vil ha digital oversikt, smaksnotater og historikk. Kjenner segmentet godt, men savner et godt verktøy.

### Hva er den viktigste verdien?
**Fjerne friksjon fra identifikasjon.** "Hva er dette?" besvart på 5 sekunder. Deretter: gi kontekst (smak, styrke, opprinnelse) og la brukeren lagre.

### Hva kan gjøre appen unik?
- Beltet (bandet) er visuelt unikt — ideelt for bildegjenkjenning
- Personlig humidor med smaksnotater = høy "stickiness"
- Ingen andre gjør dette spesifikt for sigarer
- Kombinasjon av AI-identifikasjon + journal gir differensiering

### Ærlig: hva er vanskelig?
- Sigardatabase er ikke offentlig tilgjengelig som én god API
- Belter kan være skitne, halvt synlige, rotete fonter
- Apple godkjenner ikke tobakksapper som fremmer salg
- Datakvalitet er avgjørende — én feil treffer tilliten

---

## 2. MVP-definisjon

### Må ha (v1.0)
- Kamerascan av sigarbeltet
- OCR + AI-matching mot database
- Sigardetalj-visning (merkevare, styrke, smaksnotater, opprinnelse)
- Lagre til personlig humidor
- Manuelt søk som fallback

### Bør ha (v1.1)
- Personlig rating + notater per sigar
- Røykehistorikk / logg
- Grunnleggende onboarding med aldersbekreftelse

### Kan vente (v2+)
- Sosiale funksjoner / deling
- Anbefalingsmotor ("siden du likte X, prøv Y")
- Kjøpslenker / priser
- Vektorsøk / image embeddings
- Barcode/QR-scanning
- Offline-database

---

## 3. Brukerflyt

```
1. Åpner appen første gang
   └─ Aldersbekreftelse (fødselsdato)
   └─ Kort intro: "Scan et sigarband for å identifisere sigaren"

2. Scan
   └─ Kameramodus åpnes
   └─ Guide-ramme for å plassere bandet
   └─ Bruker tar bilde (eller AI trigger auto-capture)
   └─ "Analyserer..." (2–5 sek)

3. Resultater
   └─ Liste med 3–5 forslag
   └─ Hvert treff viser: merke, bilde, matchgrad
   └─ Bruker trykker på riktig match
   └─ "Ikke funnet" → manuelt søk

4. Sigardetalj
   └─ Fullt informasjonskort
   └─ Smaksnotater, styrke, opprinnelse, konstruksjon
   └─ "Lagre til humidor" (CTA)

5. Lagring
   └─ Lagt til humidoren
   └─ Valgfritt: legg til personal rating + notat
   └─ Tilbake til scan
```

---

## 4. Datamodell

### `cigars` (hoveddatabase)
```sql
id              UUID PRIMARY KEY
brand           TEXT              -- "Davidoff"
series          TEXT              -- "Winston Churchill"
vitola          TEXT              -- "Robusto"
wrapper_country TEXT              -- "Ecuador"
wrapper_leaf    TEXT              -- "Connecticut Shade"
binder          TEXT              -- "Dominican"
filler          TEXT[]            -- ["Dominican", "Nicaraguan"]
strength        INT               -- 1 (mild) – 5 (full)
country_origin  TEXT              -- "Dominican Republic"
flavor_notes    TEXT[]            -- ["Cedar", "Cream", "Nuts"]
description     TEXT
band_image_url  TEXT
product_image_url TEXT
price_range     TEXT              -- "$15–$25"
avg_rating      DECIMAL(3,2)
ring_gauge      INT               -- 50
length_inches   DECIMAL(3,1)      -- 5.0
created_at      TIMESTAMP
```

### `profiles` (brukere)
```sql
id              UUID REFERENCES auth.users
display_name    TEXT
created_at      TIMESTAMP
```

### `humidor` (brukerens samling)
```sql
id              UUID PRIMARY KEY
user_id         UUID REFERENCES profiles
cigar_id        UUID REFERENCES cigars
quantity        INT DEFAULT 1
purchase_date   DATE
purchase_price  DECIMAL(6,2)
storage_notes   TEXT
created_at      TIMESTAMP
```

### `tasting_logs` (røykenotater)
```sql
id              UUID PRIMARY KEY
user_id         UUID REFERENCES profiles
cigar_id        UUID REFERENCES cigars
smoked_at       TIMESTAMP
rating          INT               -- 1–10
perceived_strength INT            -- 1–5
flavor_notes    TEXT[]            -- brukervalgte
pairing         TEXT              -- "Bourbon", "Kaffe"
personal_notes  TEXT
location        TEXT
created_at      TIMESTAMP
```

---

## 5. Teknisk arkitektur (MVP)

```
┌─────────────────────────────────┐
│         iOS App (SwiftUI)       │
│                                 │
│  CameraView → VisionKit (OCR)  │
│       ↓ tekst fra bandet        │
│  GPT-4o Vision (fallback AI)   │
│       ↓ strukturert match       │
│  Supabase Query (PostgreSQL)    │
│       ↓ resultater              │
│  ResultsView → DetailView       │
│       ↓ bruker lagrer           │
│  Supabase (humidor + logs)      │
└─────────────────────────────────┘

Infrastruktur:
- Auth:     Supabase Auth (Apple Sign-In + Email)
- Database: Supabase PostgreSQL
- Storage:  Supabase Storage (bilder)
- OCR:      Apple Vision Framework (on-device, gratis)
- AI:       OpenAI GPT-4o (per-kall, ~$0.01–0.03)
- Backend:  Supabase Edge Functions (TypeScript)
```

### Kostnadsestimat MVP
- Supabase Free tier: 0 kr (500 MB DB, 1 GB storage)
- OpenAI: ca. $0.02 per scan → 1000 scans = $20
- Apple Developer: $99/år
- TestFlight: inkludert

---

## 6. Bildegjenkjenning — sammenligning

| Metode | Nøyaktighet | Kompleksitet | Kostnad | Anbefalt fase |
|--------|-------------|--------------|---------|---------------|
| **OCR (Apple Vision)** | Medium | Lav | Gratis | MVP nå |
| **AI Vision (GPT-4o)** | Høy | Lav | Lav/kall | MVP nå |
| **Image embeddings** | Svært høy | Høy | Medium | v2 |
| **Custom ML-modell** | Best mulig | Svært høy | Høy | v3+ |

### Anbefalt MVP-flyt
```
1. Apple Vision → trekk ut tekst fra bandet (on-device, raskt)
2. Tekstsøk i Supabase → finn direkte treff
3. Hvis ingen treff → send bilde til GPT-4o Vision
   GPT-4o beskriver bandet → matcher mot database
4. Returner topp 3–5 forslag med konfidens
```

**Hvorfor denne rekkefølgen?**
- Apple Vision er gratis og rask (on-device)
- GPT-4o kun som fallback = lavere kostnad
- Du trenger IKKE stor treningsdataset for MVP

---

## 7. Foreslåtte screens (prioritert)

| # | Screen | Funksjon |
|---|--------|----------|
| 1 | **Onboarding** | Aldersgate, verdiproposisjon, Apple Sign-In |
| 2 | **Scan** | Kamera + guideramme + auto-capture |
| 3 | **Resultatliste** | 3–5 forslag med bilde + matchindikator |
| 4 | **Sigardetalj** | Fullt kort: smak, styrke, opprinnelse, lagre-CTA |
| 5 | **Min humidor** | Rulleliste/grid av lagrede sigarer |
| 6 | **Smaksnotat** | Rating-slider, smaksvelger, fritekst |
| 7 | **Historikk** | Tidslinje over røykte sigarer |

---

## 8. Navneforslag (20)

**Premium og enkle:**
1. **Vitola** *(fagterm for sigarform — gjenkjennelig for entusiaster)*
2. **Puro** *(spansk for "ren" / "sigar" — kort og kraftig)*
3. **Ligero** *(tobakksbladtype — premium konnotasjon)*
4. **Habano** *(havanaforbindelse — premium signal)*
5. **LeafLens**
6. **BandScan**
7. **CigarID**
8. **Fuma** *(røyk på italiensk/spansk — sofistikert)*
9. **Torcedor** *(sigarrullerens tittel — insider-cred)*
10. **Volado** *(tobakksbladtype)*
11. **The Humidor**
12. **Cazador** *(jeger — "jakter på din neste sigar")*
13. **Perla** *(en vitola-type — elegant)*
14. **RingGauge**
15. **LeafID**
16. **CigarScope**
17. **Bandero**
18. **Seco** *(tobakksbladtype)*
19. **Stogie**
20. **Ember** *(gløden — emosjonell og premium)*

**Anbefaling:** `Vitola`, `Puro` eller `Ember` — korte, premium, ingen tobakkspromosjon-konnotasjon.

---

## 9. Juridiske og etiske hensyn (Norge/Europa)

### App Store
- **Kategori:** "Reference" eller "Lifestyle" — IKKE "Health & Fitness" eller tobakksrelatert
- **Beskrivelse:** Fokus på identifikasjon, samling og notater — ikke salg
- **Ingen kjøpslenker** til sigarer i appen (risiko for App Store-avvisning)
- Aldersbekreftelse ved første oppstart (fødselsdato, ikke bare "Jeg er 18+")

### GDPR (EØS/Norge)
- Minimalt datainnsamling — kun det som trengs
- Brukeren kan slette konto og all data
- Personvernerklæring på norsk og engelsk
- Ikke del data med tredjeparter uten eksplisitt samtykke

### Posisjonering
✅ "Identifiser sigaren du røyker"  
✅ "Din digitale humidor og samlingsoversikt"  
✅ "Lær mer om tobakkstradisjon og håndverk"  
❌ "Finn de beste sigarene til laveste pris"  
❌ "Kjøp sigarer direkte"  
❌ Bilder av røyking i markedsføring  

### Aldersgrense
- Norsk lov: 18 år for tobakk
- EU: varierer (16–18), bruk 18 som standard
- Implementér: fødselsdatosjekk på onboarding, ikke bypass-bar

---

## 10. Hva du faktisk bør bygge først

### Fase 0 — Fundament (2–3 uker)
1. Opprett Supabase-prosjekt med `cigars`-tabell
2. Importer 500–1000 sigarer manuelt (Cigar Aficionado-listene er offentlige)
3. Sett opp Supabase Auth med Apple Sign-In

### Fase 1 — Scan MVP (3–4 uker)
4. SwiftUI-app med kameravisning
5. Apple Vision OCR → tekst fra bilde
6. Tekstsøk mot Supabase `cigars`
7. Resultatliste + sigardetalj-screen

### Fase 2 — AI Fallback + Humidor (2–3 uker)
8. GPT-4o Vision for bilde uten klar tekst
9. Lagre-til-humidor funksjonalitet
10. Enkel smaksnotat-screen

### Fase 3 — TestFlight
11. Aldersbekreftelse + onboarding
12. Privatlivspolicy
13. TestFlight-distribusjon til betabrukere

---

> **Anbefalt første steg:** Bygg databasen. Alt annet avhenger av datakvaliteten.  
> Start med 500 sigarer fra de 20 største merkene — det dekker 80% av hva folk faktisk røyker.
