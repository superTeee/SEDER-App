# Vitola — Android (Jetpack Compose)

Native Android-versjon av Vitola. Bruker **samme Supabase-backend** som iOS
(database, RPC-er, storage). Bygget i Kotlin + Jetpack Compose.

## Oppsett (én gang)

1. Installer **Android Studio** (siste stabile).
2. Åpne mappa `android/` i Android Studio (**File → Open** → velg `android`).
3. Studio kjører «Gradle sync» automatisk og laster ned:
   - Gradle-wrapperen (du trenger ikke lage den selv)
   - Alle avhengigheter (Compose, Supabase-kt, Coil, Ktor)
4. Koble til en Android-telefon (USB, med USB-debugging på) **eller** start en
   emulator (Device Manager → Create Device).
5. Trykk **Run ▶**.

> Første sync tar noen minutter. Er en avhengighetsversjon utdatert, foreslår
> Studio en oppdatering — godta den, eller si ifra så justerer vi.

## Hva som er med i denne MVP-en

- **Utforsk**: merkeliste + fritekstsøk (merke/serie/vitola) mot Supabase.
- **Merkeside**: alle sigarer for ett merke.
- **Sigar-detalj**: opprinnelse, format+mål, smaksnoter, konstruksjon,
  styrke/kropp/smaksintensitet/sødme, verifisert-merke.
- **Humidor**: stubb (krever innlogging — neste steg).

## Neste steg (planlagt, i rekkefølge)

1. **Google-innlogging** (Play Services + Supabase Auth) → låser opp Humidor.
2. **Humidor**: liste + kort (samme design som iOS), legg til / flytt sigar.
3. **Journal**, **Feed**, **Profil**.
4. Bildeopplasting (Supabase Storage) + Coil-caching.
5. Splash + app-ikon.

## Testmiljø (TestFlight-ekvivalent)

- **Google Play Console → Internal testing**: nærmest TestFlight (installeres
  via Play Store, auto-oppdaterer, ingen review). Krever Play Developer-konto
  ($25 engangs).
- **Firebase App Distribution**: gratis, sender AAB/APK til testere via lenke
  uten Play-konto — bra for tidlig fase.

(Konto-oppsettet gjør du selv; appen er klar til å produsere release-bygg.)

## Merk

- Supabase anon-nøkkel ligger i `data/Supabase.kt` — trygt i kildekode, RLS
  beskytter dataene (samme prinsipp som iOS).
- Dette er første scaffold. Supabase-spørringenes DSL og enkelte
  bibliotek-versjoner kan trenge små justeringer ved første kompilering — det
  fikser vi fortløpende, akkurat som kompileringsfeil i Xcode.
