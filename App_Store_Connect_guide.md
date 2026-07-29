# App Store Connect — oppsett for betaling (SEDER)

Følg dette i rekkefølge. Ta én del av gangen. Alt du skriver inn er markert som `kode`.

> **Viktigst av alt:** produkt-ID-ene MÅ skrives nøyaktig som her (`seder_pro_yearly` og `seder_pro_monthly`) — de kobles til RevenueCat og appen, er skiftesensitive, og kan **ikke endres** etter at de er laget.

---

## DEL 1 — Paid Apps-avtale (bank + skatt)

Uten denne avtalen aktiv virker ingen kjøp i det hele tatt. Gjør denne først.

1. Logg inn på **appstoreconnect.apple.com**.
2. Klikk **Avtaler, skatt og bank** (Agreements, Tax, and Banking) på forsiden.
3. Under **Betalte apper** (Paid Apps): klikk **Sett opp** / **Vis avtale** og godta avtalen. (Krever at du er «Account Holder» eller «Admin».)
4. **Bankinformasjon:** legg til norsk bankkonto (IBAN + BIC/SWIFT). Kontoen må stå i navnet som matcher avtalen.
5. **Skatteinformasjon:**
   - **USA:** fyll ut skjemaet **W-8BEN** (du er ikke amerikansk skattyter). Dette reduserer amerikansk kildeskatt på salg i USA.
   - **Norge:** fyll ut norsk skatteinfo hvis den spør.
6. **Kontakter:** sett opp Senior Management-, Finance- og Technical-kontakt (kan være deg på alle).
7. **Vent på status «Aktiv».** Bank-/skatt-delen kan ta litt tid å bli godkjent. Du kan gå videre til Del 2 imens, men kjøp fungerer først når avtalen er **Aktiv**.

---

## DEL 2 — Lag abonnementsproduktene

App-oppføringen finnes allerede (fra TestFlight). Nå lager vi de to abonnementene.

### 2.1 Åpne abonnementer
1. **App Store Connect → Apper → SEDER**.
2. I venstremenyen under **Monetisering** (Monetization): klikk **Abonnementer** (Subscriptions).

### 2.2 Lag en abonnementsgruppe
Begge produktene skal ligge i **samme gruppe** (da kan en bruker bare ha ett aktivt om gangen — årlig *eller* månedlig).

1. Klikk **Opprett** ved «Abonnementsgrupper».
2. **Referansenavn (Reference Name):** `SEDER Pro`  *(kun internt, ikke synlig for brukere)*
3. Lagre.
4. Gruppen trenger et **lokalisert visningsnavn** (Norsk): sett det til `SEDER Pro`.

### 2.3 Produkt 1 — Årlig
Inne i gruppen, klikk **Opprett abonnement**:

| Felt | Verdi |
|---|---|
| Referansenavn | `SEDER Pro Årlig` |
| **Produkt-ID** | `seder_pro_yearly` ← nøyaktig slik |
| Varighet | **1 år** |

Deretter:
1. **Pris:** klikk **Legg til pris** → velg **Norge (NOK)** som utgangspunkt → sett **449 kr**. Apple regner om til andre land automatisk (du kan justere etterpå).
2. **Lokalisering (Norsk bokmål):**
   - Visningsnavn: `SEDER Pro`
   - Beskrivelse: `Ubegrenset antall humidorer, avansert statistikk, journal-eksport og Pro-merke.`
3. **Vurderingsinformasjon (Review):** last opp et **skjermbilde av paywall-skjermen** i appen (Profil → Oppgrader til Pro). Legg ev. en kort note: «Pro låser opp ubegrenset humidorer, statistikk og eksport.»
4. Lagre.

### 2.4 Produkt 2 — Månedlig
Fortsatt i **samme gruppe**, klikk **Opprett abonnement** igjen:

| Felt | Verdi |
|---|---|
| Referansenavn | `SEDER Pro Månedlig` |
| **Produkt-ID** | `seder_pro_monthly` ← nøyaktig slik |
| Varighet | **1 måned** |

1. **Pris:** Norge (NOK) → **59 kr**.
2. **Lokalisering (Norsk):**
   - Visningsnavn: `SEDER Pro`
   - Beskrivelse: `Ubegrenset antall humidorer, avansert statistikk, journal-eksport og Pro-merke.`
3. **Review:** samme paywall-skjermbilde.
4. Lagre.

### 2.5 Status
Hver av dem viser først **«Mangler metadata»** → blir **«Klar til innsending»** når alt over er fylt ut. De **gjennomgås sammen med appen** ved første innsending — du sender dem ikke inn separat.

---

## Rekkefølge videre (etter Del 1–2)

3. **RevenueCat:** legg de to produktene i «default»-offeringen, knytt til entitlement `SEDER Pro`, lim inn `appl_`-nøkkelen. *(Vent til RevenueCat-incidenten er løst.)*
4. **Kampanjekode `SEDER100`:** Abonnementer → produktet `seder_pro_yearly` → **Tilbudskoder** (Offer Codes) → egendefinert kode, maks **100** innløsninger, utløpsdato, årspris ~**349** første år.
5. **Screenshots + metadata + aldersvurdering (17+).**
6. **Claude arkiverer build 273 → laster opp → du trykker «Send til review».**

---

### Huskeregler
- Produkt-ID-er kan ikke endres. Dobbeltsjekk `seder_pro_yearly` / `seder_pro_monthly` før du lagrer.
- Ikke bruk mellomrom eller store bokstaver i produkt-ID.
- Prisen kan endres senere; produkt-ID og varighet kan ikke.
- Si fra når produktene står som «Klar til innsending», så tar vi RevenueCat + resten.
