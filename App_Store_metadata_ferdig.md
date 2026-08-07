# SEDER — App Store metadata (lim inn, felt for felt)

Alt du trenger for app-versjon **1.0** → **App Store**-fanen i App Store Connect.

---

## 1. Tekstfelt (App Store-fanen)

**Navn** (maks 30 tegn) — allerede satt:
```
SEDER - Digital humidor
```

**Undertittel** (maks 30 tegn):
```
Sigarkatalog og humidor
```

**Kampanjetekst / Promotional Text** (maks 170 tegn — kan endres når som helst uten ny build):
```
Skann sigarbånd, bygg din digitale humidor og før journal med vurderinger og smaksprofil. Alt for samlingen din, på ett sted.
```

**Nøkkelord / Keywords** (maks 100 tegn, komma, ingen mellomrom):
```
sigar,cigar,humidor,katalog,journal,smaksnotat,samling,vitola,skann,database,aficionado,kolleksjon
```

**Beskrivelse / Description** (maks 4000 tegn):
```
SEDER er referanse- og samlingsappen for deg som vil holde orden på sigarene dine.

Slå opp en sigar ved å skanne båndet, bygg din digitale humidor, og før en privat journal med vurderinger og smaksprofil. Alt samlet på ett sted – som en katalog og kjeller for samlingen din.

FUNKSJONER
• Skann sigarbånd og slå opp sigaren i databasen
• Omfattende oppslag: dekkblad, opphav, styrke, format og smaksprofil
• Digital humidor: hold oversikt over samlingen, antall og verdi
• Følg luftfuktighet (RH) per humidor, med historikk og graf over tid
• Privat journal: vurder 0–100, skriv notater og se din personlige smaksprofil
• Utforsk en voksende katalog med merker, serier og vitolaer
• Legg til kjøp fra kvittering – ta bilde, så fylles varelinjene inn automatisk

SEDER er et oppslags- og organiseringsverktøy for voksne sigarentusiaster som vil dokumentere og holde styr på samlingen sin. Appen selger ikke tobakk, viser ikke hvor man kan kjøpe tobakk, og oppfordrer ikke til bruk av tobakk.

Kun for personer over 18 år. Krever konto.
```

**Nyheter / What's New** (v1.0):
```
SEDER er et oppslags- og samlingsverktøy for sigarentusiaster: skann og slå opp sigarer, bygg din digitale humidor, følg luftfuktighet og før en privat smaksjournal.
```

---

## 2. Generelle felt

- **Support-URL:** `https://sederappen.no/support`
- **Markedsførings-URL** (valgfritt): `https://sederappen.no`
- **Copyright:** `2026 Tom Erik Heggedal`
- **Kategori:** Primær = **Referanse (Reference)** ⟵ endret. Sekundær = **Verktøy (Utilities)** eller Livsstil. (Referanse-kategorien understreker at appen er en katalog/oppslagstjeneste, ikke livsstil/konsum — viktig for 1.4.3.)
- **Personvern-URL** (under App Privacy): `https://sederappen.no/personvern.html`

---

## 3. Aldersvurdering (Age Rating)

Åpne aldersvurderings-spørreskjemaet. Svar **Ingen/None** på alt UNNTATT:

- **«Alkohol, tobakk eller narkotika – bruk eller referanser»** → velg **Ja / Frequent or Intense**.
  *(Appen handler om sigarer = tobakk. Dette gir 17+/18+.)*

Alt annet (vold, skremmende innhold, gambling, seksuelt innhold, urestriktert web) → **Ingen/Nei**.

Resultatet blir automatisk **17+** (eller 18+ i Apples nye system). Det er riktig for en sigar-app.

---

## 4. App Privacy («nutrition label»)

Spørsmål: «Samler du inn data?» → **Ja**.
Ingen av dataene brukes til **sporing (tracking)** på tvers av apper → svar **Nei** på tracking.
All data er **koblet til brukeren** (konto), men **ikke** brukt til tracking eller annonser.

Legg inn disse datatypene, alle med formål **App-funksjonalitet (App Functionality)**, **koblet til bruker (Linked)**, **ikke brukt til sporing**:

| Datatype (Apple-kategori) | Hva det er |
|---|---|
| **Contact Info → E-postadresse** | innlogging |
| **Identifiers → Bruker-ID** | konto-identifikator |
| **User Content → Bilder** | skann-bilder, journalbilder, profilbilde |
| **User Content → Annet brukerinnhold** | sigarnotater, vurderinger, humidor-data, by/sted |

Ikke legg til: Helse/Fitness, Posisjon (enhet), Betalingsinfo, Kontakter, Søkehistorikk, Diagnostikk, Annonsedata. (Vi samler ikke inn dette.)

> Merk: røykejournalen behandles som helseopplysning i personvernerklæringen (GDPR), men i Apples label hører den under **brukerinnhold**, ikke «Health & Fitness» (som er HealthKit-data).

---

## 5. Rekkefølge på det siste

1. Fyll inn alt over + last opp screenshots (rekkefølge: oppslag/skann → humidor → sigardetalj → journal → RF-graf → utforsk). MERK: ingen feed/venner-skjermbilder, ingen tente sigarer.
2. **IKKE** send inn ennå — vi venter på RevenueCat-nøkkelen (ellers avvises kjøp).
3. Når incidenten er borte: Claude limer inn `appl_`-nøkkel → arkiverer build → fester abonnementer + build → **Submit for Review**.

---

## 6. Skjermbilde-tekster (nye — 1.4.3-tilpasset)

Skyt på nytt fra den oppdaterte appen. **Ingen tente sigarer, ingen feed/venner.** Bruk utente sigarer, bånd, humidor og katalog. Forslag til overskrifter (bilde → tekst):

1. **Slå opp båndet med AI** — skann/oppslag-skjermen
2. **Full kontroll på samlingen** — humidor
3. **Alt du vil vite om sigaren** — sigardetalj (dekkblad, opphav, styrke, smak)
4. **Din private smaksjournal** — journal (utent sigar / bånd på bildet, ikke aske/glo)
5. **Følg fuktigheten over tid** — RF-graf (fremhever verktøy/referanse, ikke konsum)
6. **Finn din neste favoritt** — utforsk/katalog

Unngå de gamle: «Del øyeblikkene» (sosialt), «Husk hver opplevelse» (tent sigar), «Utvikle din sigarprofil» (kan leses som gamification av røyking).
