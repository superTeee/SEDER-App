# TestFlight — Test Information (build 178)

Feltene under samsvarer med App Store Connect → TestFlight → Test Information.

---

## Beta App Description
*(Dette ser testerne dine i TestFlight-appen. Norsk.)*

Vitola er en oppslagsbok og røykejournal for sigarentusiaster.

Søk i sigardatabasen og les om dekkblad, omblad, innmat, format og smaksprofil. Hold oversikt over dine egne humidorer, og loggfør sigarene du røyker med bilde, rating og notater. Du kan legge til venner og dele loggene dine i en felles feed.

Appen selger ingenting og lenker ikke til forhandlere. Innholdet er kun for voksne, og du må bekrefte alder før du kommer inn.

---

## What to Test
*(Norsk. Oppdater denne per build.)*

**Build 178 — nytt siden sist**

Ny oppstartssekvens med bilde og logo, nytt app-ikon, og merket German Engineered Cigars med 16 sigarer.

**Områder jeg ønsker tilbakemelding på**

Utforsk-siden: søk, avansert filter, «Brukernes topp 3» og «Dagens utvalgte». Merk om noe hopper eller laster tregt når du kommer inn på siden.

Long-press på en sigar i en hvilken som helst liste — hurtigmenyen skal komme opp uansett hvor på raden du trykker.

Humidor: opprett en humidor, legg til sigarer, last opp coverbilde og velg utsnitt. Sjekk at antall og kapasitet stemmer.

Journal: loggfør en sigar med bilde, rating og notater.

Feed: legg ut et innlegg, lik og kommenter. Test også rapportering og blokkering av brukere.

Profil og venner: send og godta venneforespørsel, se smaksprofil og «Sist røkt».

Lys og mørk modus overalt — særlig ikonfarger og lesbarhet på titler.

---

## Feedback Email

theggedal@gmail.com

---

## Beta App Review Information

### Contact Information
- Fornavn: Tom Erik
- Etternavn: Heggedal
- E-post: theggedal@gmail.com
- Telefon: *(fyll inn)*

### Sign-in required
**Ja.** Appen kan brukes uten innlogging (søk og utforsk), men innlogging kreves for humidor, journal og feed — så review trenger en konto.

- Brukernavn: *(opprett en demo-konto med e-post + passord, og fyll inn her)*
- Passord: *(fyll inn)*

> Ikke oppgi din egen konto. Lag en egen `demo@…`-konto med litt innhold i: én humidor, én loggført sigar, ett feed-innlegg. Da ser reviewer at funksjonene faktisk virker.

### Notes
*(Dette leses av Apples reviewer, ikke av testerne. Skriv på engelsk — det er språket App Review jobber på, og et norsk notat blir enten oversatt maskinelt eller oversett.)*

```
Vitola is a reference database and personal tasting journal for cigar enthusiasts.

Regarding Guideline 1.4.3:
- The app does not sell any products. There are no purchase flows, no in-app
  purchases, no retailer links, no prices, and no affiliate links anywhere.
- The app does not encourage tobacco consumption. Cigar entries are neutral,
  descriptive reference data: wrapper, binder, filler, country of origin,
  ring gauge, length, strength and flavor notes.
- The app is age-gated on first launch. The user must confirm they are of
  legal smoking age before any content is shown. The app is rated 18+.

Regarding Guideline 1.2 (user-generated content):
- Feed posts and comments can be reported by any user.
- Users can block other users.
- Contact information is published in the app and on the support URL.

Sign-in is optional for browsing and search. An account is required only to
save cigars to a humidor, log a smoke, or post in the feed. Sign-in supports
Apple, Google and email. A demo account with sample data is provided above.
```

---

## Før innsending

**Export compliance** må besvares for build 178 (den står som «Missing Compliance»). Appen bruker kun standard HTTPS/TLS gjennom Apple-rammeverk, altså exempt.

**Aldersgrense** settes til 18+ i App Store Connect → App Information → Age Rating. Hyppige referanser til tobakk lander der etter Apples nye rating-system.
