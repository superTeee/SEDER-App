# AGENTS.md — SEDER

Instructions for AI coding agents working in this repository.

## Product

SEDER (formerly Vitola) is a cigar identification, private catalog, humidor and journaling app.

- iOS: SwiftUI, iOS 17+
- Android: Jetpack Compose / Material3
- Backend: Supabase (Postgres, Auth, Storage, Edge Functions)
- iOS is the visual/design source of truth; Android should mirror shared product behavior and design where platform conventions allow.
- Bundle/package identifiers may still use `vitola`; do not rename identifiers casually.

## Working rules

1. Understand existing code before changing it. Preserve working architecture unless there is a concrete reason to change it.
2. Prefer small, reviewable changes. Do not rewrite large areas just because another architecture is possible.
3. Keep iOS and Android in sync when changing shared behavior, terminology or design.
4. For iOS, prefer editing existing `.swift` files. The Xcode project is not reliably regenerated from `project.yml`; new Swift files can be missed unless the project is deliberately updated.
5. `ExploreView` is intentionally split into `AnyView` groups to avoid a real device-only SwiftUI stack/type-metadata crash. Do not collapse those groups back into one deep modifier chain.
6. Storage paths used with Supabase RLS must remain lowercase.
7. Ratings use two different scales: catalog `avg_rating` is 0–10; user journal ratings are 0–100. Do not mix them.
8. After behavior changes, verify both happy path and failure path. Do not silently swallow new errors unless the existing flow deliberately does so.

## Source/data integrity

Cigar specification data must not be guessed.

- Manufacturer/official brand sources are the preferred authoritative source for specifications.
- Empty/unknown is better than an inferred ring gauge, length, blend, origin or other specification.
- Retailer data must not silently replace manufacturer data.
- Keep existing provenance/source-tier semantics intact.

## Apple / tobacco compliance

SEDER must remain a neutral organization/reference/journaling utility for adults who already own cigars.

Do not add or reintroduce:

- tobacco sales or purchase facilitation
- retailer purchase links
- advertising or promotional CTAs
- language encouraging tobacco consumption
- social feed/friend/like/comment features without an explicit product/compliance decision
- recommendation language that looks like personalized encouragement to consume

Use neutral wording such as identification, cataloging, logging, journal and humidor management.

### Known current compliance discrepancies

These are open issues, not desired behavior:

- iOS `ExploreStore.loadFeaturedCigar()` still tries `fetchTasteFeaturedCigar()` first and the UI still presents `Dagens utvalgte` with a flame icon. Treat this as a compliance-risk item to neutralize before a new App Store submission.
- Android still presents `Dagens utvalgte`.
- Android `shareCigar()` currently appends `sjekk ut denne sigaren i SEDER` plus a link. This is not the intended neutral share behavior; iOS currently shares only the cigar name.
- Android can still surface `ShareAfterSaveSheet` after a quick journal log. Reassess/remove this before treating Android compliance as complete.

## Payments / Pro

Current intended commercial model:

- iOS: StoreKit 2
- SEDER Pro: one-time/lifetime non-consumable
- optional tips: consumables
- no auto-renewable subscription model
- first 50 founding members receive lifetime Pro

Important: Android `ProManager.kt` still contains RevenueCat subscription-era concepts (`isSubscriber`, monthly/yearly offering comments and entitlement logic) and a placeholder `goog_LIM_INN_HER` key. Do not simply insert a key and ship it. Align Android with the intended lifetime-Pro + optional-tip model first.

`foundingCap` / `FoundingConfig.cap` should remain 50 unless product explicitly changes it.

## Design system

Preserve the established visual language:

- dark mode is default
- semantic colors: Accent, Background, Card, Surface, TextPrimary, TextSecondary
- secondary actions are outline style, not filled
- selected/primary actions may use filled Accent
- active tab uses Accent-filled pill + light icon
- list title: brand, ~16 semibold
- subtitle: series · vitola, ~14
- section/label style: ~12 semibold with tracking
- use shared components (`ScoreBadge`, secondary-button components, photo/edit components) deliberately because changes propagate app-wide
- image edit pattern: large image/placeholder + Edit/Change affordance + Remove image where supported

## Images

- Prefer existing shared image helpers.
- Keep upload/downscale behavior conservative (~1200 px, JPEG quality ~0.7 where already established).
- Simulator may not have a camera; keep camera availability guards/fallbacks.

## Database / migrations

- Business logic intentionally lives in Supabase RPC/functions where it is shared by both apps.
- Do not assume a migration file has been applied to production; production schema may drift from repo migrations.
- Social tables may still exist in the database although the app no longer surfaces the social layer.
- `vitola_sizes` RLS status has been flagged for review. Do not enable RLS without appropriate policies or access may break.

## Secrets

This repository is public. Never commit:

- OpenAI API keys
- Supabase service-role keys
- Apple credentials / 2FA secrets
- private RevenueCat/Play secrets
- other server-side credentials

Public Supabase anon keys and OAuth client IDs may exist in client code by design, but do not broaden exposure beyond what the client requires.

## Known technical debt / cleanup

- `project.yml` still declares Mantis and RevenueCat dependencies even though current iOS crop/payment code uses custom crop behavior and StoreKit 2. Verify actual usage before removing them.
- `_to_delete/` is ignored but may still exist in historical/current trees; clean deliberately, not as part of unrelated feature work.
- `CHAT_HANDOFF.md` is git-ignored and is not currently available in the GitHub repo. Do not assume it can be read from GitHub.
- Avoid reviving dead share/social code simply because structures/tables still exist.

## Before completing a task

Check:

1. Does this preserve neutral tobacco/compliance language?
2. Did shared behavior remain consistent across iOS/Android where relevant?
3. Did any DB/storage change preserve RLS assumptions and lowercase storage paths?
4. Did any rating logic preserve 0–10 vs 0–100 scales?
5. Did the change touch a shared design component with unintended app-wide effects?
6. For iOS, did we avoid reintroducing the deep SwiftUI type chain around `ExploreView`?
7. Are secrets absent from the diff?
8. Is the requested product behavior actually implemented, rather than only updating comments/docs?

## Current takeover priorities

Based on the repository state on 4 Sep 2026:

1. Neutralize the remaining App Store compliance risks: `Dagens utvalgte` personalization/flame framing and Android promotional share copy/share-after-log behavior.
2. Verify the latest iOS and Android UI-parity commits on real builds/devices before further broad UI changes.
3. Add Android photo upload to journal/add-to-humidor flows where still missing.
4. Add safe server-side remove-photo support for immediate-upload locations before exposing Remove everywhere.
5. Redesign Android payment implementation around lifetime Pro + optional tips before configuring RevenueCat/Play.
6. Review `vitola_sizes` RLS with correct policies before enabling it.
7. Clean stale dependencies/dead code only after verifying they are unused.
