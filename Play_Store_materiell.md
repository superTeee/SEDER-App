# SEDER — Google Play-materiell

Alt du trenger å lime inn i **Play Console** når utviklerkontoen er godkjent. Bygger på iOS-metadataen, tilpasset Play.

---

## 1. Butikkoppføring (Store listing)

**Appnavn** (maks 30 tegn):
```
SEDER - Digital humidor
```

**Kort beskrivelse** (maks 80 tegn):
```
Skann sigarbånd, bygg din digitale humidor og før tasting-journal.
```

**Fullstendig beskrivelse** (maks 4000 tegn):
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

Aldersgrense 18+. Krever konto.
```

**Kategori:** Livsstil (Lifestyle)
**Merkeord/tags:** cigar, humidor, tasting

---

## 2. Kontaktinfo + URL-er

- **E-post:** support@sederappen.no
- **Nettsted:** https://sederappen.no
- **Personvernerklæring:** https://sederappen.no/personvern.html
- **Sletting av konto (URL til Data safety):** https://sederappen.no/slett-konto.html

---

## 3. Grafikk (må lages/lastes opp)

| Ressurs | Krav | Status |
|---|---|---|
| App-ikon | 512×512 PNG | Bruk samme SEDER-«S»-ikon som iOS (finnes) |
| Feature graphic | 1024×500 PNG | **Må lages** (banner, vises øverst i Play) |
| Telefon-screenshots | Min. 2, 16:9 eller 9:16, 320–3840 px | Bruk de samme motivene som iOS (skann, humidor, journal, utforsk, venner) |
| (Valgfritt) Nettbrett-screenshots | — | Ikke nødvendig |

---

## 4. Innholdsvurdering (IARC-spørreskjema)

Svar ærlig; tobakk gir 18+.

- **Kategori:** Verktøy / Referanse / Livsstil (ikke spill).
- **Refererer appen til tobakk/alkohol/narkotika?** → **Ja** (appen handler om sigarer). Presiser at appen *ikke* selger tobakk og ikke oppfordrer til bruk.
- **Vold, seksuelt innhold, gambling, skremmende innhold:** → **Nei** på alt.
- Resultat blir typisk **PEGI 18 / ESRB Mature** — riktig for en sigar-app.

---

## 5. Data safety (datasikkerhet-skjema)

**Samler appen inn data?** → **Ja**
**Deles data med tredjeparter?** → **Nei** (kun databehandlere: Supabase = backend, RevenueCat = kjøp)
**Krypteres data under overføring?** → **Ja** (HTTPS/TLS)
**Kan brukeren be om sletting?** → **Ja**, i appen (Innstillinger → Slett konto) og via https://sederappen.no/slett-konto.html

Datatyper som samles (alle: «App-funksjonalitet», koblet til bruker, IKKE brukt til sporing/annonser):

| Datatype (Play-kategori) | Hva |
|---|---|
| Personlig info → Navn | onboarding/profil |
| Personlig info → E-postadresse | innlogging |
| Bilder | skann-, journal- og profilbilder |
| App-aktivitet → Annet brukergenerert innhold | sigarnotater, vurderinger, humidor-data, by/sted |
| App-info og ytelse → *ingen* | (ingen crash-/analyseverktøy) |
| Kjøpshistorikk | via RevenueCat (abonnement) |

Ikke oppgi: posisjon (enhet), kontakter, helse, økonomi/betalingsinfo (Google håndterer betaling), søkehistorikk, enhets-ID, annonsedata.

---

## 6. Abonnement (Play Console → Monetize → Products → Subscriptions)

Opprett med **samme produkt-ID-er som iOS** (RevenueCat deler offering på tvers):
- `seder_pro_yearly` — 1 år
- `seder_pro_monthly` — 1 måned

Koble deretter Android-appen til RevenueCat (Play service-account-JSON + produktene), og lim `goog_`-nøkkelen inn i `ProConfig` (Android).

---

## 7. Rekkefølge til slutt

1. Opprett appen i Play Console (pakkenavn `com.tomerikheggedal.vitola`).
2. Fyll butikkoppføring + grafikk + innholdsvurdering + Data safety (over).
3. Opprett abonnementene + koble RevenueCat + lim inn `goog_`-nøkkel → bygg ny AAB.
4. Last opp AAB til intern testing → så produksjon.
5. (Manuell utrulling anbefales, som iOS, for koordinert lansering.)
