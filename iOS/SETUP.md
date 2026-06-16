# Vitola — Xcode Setup Guide

Følg disse stegene i rekkefølge etter at filene er klare.

---

## Steg 1: Opprett Xcode-prosjekt

1. Åpne **Xcode**
2. `File → New → Project`
3. Velg **iOS → App**
4. Fyll inn:
   - **Product Name:** `Vitola` (eller velg eget navn)
   - **Organization Identifier:** `com.DITT_NAVN.vitola`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Fjern haken** ved "Include Tests" (kan legges til senere)
5. Lagre i ønsket mappe

---

## Steg 2: Legg til Supabase Swift SDK

1. I Xcode: `File → Add Package Dependencies`
2. Lim inn URL: `https://github.com/supabase/supabase-swift`
3. Klikk **Add Package**
4. Velg produkt: **Supabase** ✓
5. Klikk **Add Package**

---

## Steg 3: Kopier kildefilene

Dra disse filene fra `iOS/CigarApp/` inn i Xcode-prosjektet ditt:

```
CigarAppApp.swift          → Erstatt standard App-fil
Models/
  Cigar.swift
  UserModels.swift
Services/
  SupabaseConfig.swift     ⚠️ Husk å oppdatere URL og nøkkel!
  AuthService.swift
  CigarService.swift
  ScanService.swift
Views/
  ContentView.swift
  Auth/AuthView.swift
  Scan/ScanView.swift
  Scan/ResultsView.swift
  Cigar/CigarDetailView.swift
  Humidor/HumidorView.swift
```

> Tips: Opprett mappestruktur i Xcode først (høyreklikk → New Group), dra deretter filer inn.

---

## Steg 4: Legg til fargekonstanter (Assets)

I `Assets.xcassets`, opprett disse fargene:

| Navn | Light | Dark |
|------|-------|------|
| `Accent` | `#8B4513` (saddle brown) | `#C4813A` |
| `Background` | `#FAF8F5` | `#1C1A18` |
| `Surface` | `#F0EBE3` | `#2C2926` |

---

## Steg 5: Info.plist-tillatelser

Legg til disse nøklene i `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Vitola bruker kameraet til å scanne sigarbandet</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Velg et bilde av et sigarband fra biblioteket ditt</string>
```

---

## Steg 6: Oppdater SupabaseConfig.swift

```swift
// Finn URL og nøkkel i Supabase Dashboard → Settings → API
static let projectURL = URL(string: "https://DITT_ID.supabase.co")!
static let anonKey = "din_anon_nøkkel_her"
```

---

## Steg 7: Kjør SQL-migrasjonen

1. Gå til [supabase.com](https://supabase.com) og logg inn
2. Åpne prosjektet ditt → **SQL Editor**
3. Lim inn innholdet fra `supabase/migrations/001_initial_schema.sql`
4. Klikk **Run**

---

## Steg 8: TestFlight

Når appen kompilerer og fungerer:
1. `Product → Archive`
2. Last opp til App Store Connect
3. Aktiver TestFlight og inviter testere

---

## Fremtid: Supabase Edge Function for AI-scanning

Når du er klar for GPT-4o-integration:
```bash
supabase functions new scan-cigar
# Koden for denne funksjonen kommer i neste fase
```
