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
Sigarjournal og humidor
```

**Kampanjetekst / Promotional Text** (maks 170 tegn — kan endres når som helst uten ny build):
```
Skann sigarbånd, bygg din digitale humidor og før journal med vurderinger og smaksprofil. Alt for samlingen din, på ett sted.
```

**Nøkkelord / Keywords** (maks 100 tegn, komma, ingen mellomrom):
```
sigar,cigar,humidor,journal,smaksnotat,samling,vitola,skann,rating,aficionado,kjenner,kolleksjon
```

**Beskrivelse / Description** (maks 4000 tegn):
```
SEDER er appen for deg som liker å holde orden på sigarene dine.

Skann båndet på en sigar for å kjenne den igjen, bygg din digitale humidor, og før journal over det du har røkt – med vurdering, notater og smaksprofil. Alt samlet på ett sted.

FUNKSJONER
• Skann sigarbånd og finn sigaren i databasen
• Digital humidor: hold oversikt over samlingen, antall og verdi
• Følg luftfuktighet (RH) per humidor, med historikk og graf over tid
• Tasting-journal: vurder 0–100, skriv notater og se din personlige smaksprofil
• Utforsk en voksende database med merker, serier og vitolaer
• Legg til kjøp fra kvittering – ta bilde, så fylles varelinjene inn automatisk
• Venner og aktivitet: del det du røyker og se hva andre samler på
• Nivåer og merker etter hvert som du bruker appen

SEDER er laget for voksne sigarentusiaster som vil organisere og dokumentere hobbyen sin. Appen selger ikke tobakk og oppfordrer ikke til bruk av tobakk.

Aldersgrense 17+. Krever konto.
```

**Nyheter / What's New** (v1.0):
```
Første versjon av SEDER. Skann sigarer, bygg humidor, følg luftfuktighet og før tasting-journal.
```

---

## 2. Generelle felt

- **Support-URL:** `https://sederappen.no/support`
- **Markedsførings-URL** (valgfritt): `https://sederappen.no`
- **Copyright:** `2026 Tom Erik Heggedal`
- **Kategori:** Primær = **Livsstil (Lifestyle)**. Sekundær = valgfritt (la stå tom, eller «Referanse»).
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

1. Fyll inn alt over + last opp de 5 screenshots (i rekkefølge skann → humidor → journal → utforsk → venner).
2. **IKKE** send inn ennå — vi venter på RevenueCat-nøkkelen (ellers avvises kjøp).
3. Når incidenten er borte: Claude limer inn `appl_`-nøkkel → arkiverer build → fester abonnementer + build → **Submit for Review**.
