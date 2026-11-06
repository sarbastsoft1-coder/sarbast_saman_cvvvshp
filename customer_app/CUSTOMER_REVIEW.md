# Customer app review — 3 October 2026 (Roni reskin)

## Scope

The running customer app starts at `lib/main.dart` and uses `lib/boutique/`. This pass
re-skinned that active storefront to the supplied **Roni** design — warm ivory surfaces,
bronze/gold accents, white rounded cards, gold-gradient calls to action — and added the
three Roni feature areas that had no equivalent in the app. Seller, delivery, admin, and
Laravel backend code were not changed.

Content language was deliberately **kept Kurdish (Sorani), RTL, priced in Iraqi Dinar**.
Only the visual language and the information architecture changed.

## Design system

| File | Change |
| --- | --- |
| `core/theme/boutique_colors.dart` | Repainted the palette to ivory `#FCF8F1` / `#F7EEDF` with bronze-gold `#B0802A`, a gold CTA gradient, order-status tones (processing/shipped/delivered/cancelled), and warm soft shadows. **Every pre-existing constant name was kept** so all 114 call sites across 23 files repainted without edits. |
| `core/theme/boutique_theme.dart` | Gold primary, white card theme (20 px radius + hairline border), gold filled/outlined buttons, focusable gold input borders, chip and navigation-bar themes. |
| `widgets/store_components.dart` | New kit: `RoniCard`, `GoldButton` (gradient, optional `subtitle` for running totals), `GhostButton`, `StatusPill`, `RoniSectionHeader`, `RoniSearchField`, `RoniIconButton` (count badge). Pre-existing `StorePanel`/`StoreNotice`/`StoreEmpty` retained. |

## Information architecture

The bottom bar now mirrors the mockup: **Home · Categories · Deals · Orders · Account**.

- Cart and wishlist are no longer tabs — they are pushed pages reached from the top bar and
  the account screen (`BoutiqueRoutes.openCart` / `openWishlist`).
- Tab order is `0 Home, 1 Categories, 2 Deals, 3 Orders, 4 Account`; `BoutiqueRoutes.tabRoutes`
  documents this set and route tests assert it.
- All pre-existing route names and constants are unchanged, so deep links keep working.

## New screens

| Screen | Route | Notes |
| --- | --- | --- |
| Splash | `/splash` | Ink/gold sunrise with a gold "R" monogram and a `Get Started` button. Shown once per device, advanced by tap (never a timer, so tests and deep links stay deterministic). |
| Deals | `/deals` (tab 2) | Gold flash-sale banner with a live countdown, then every discounted product, biggest saving first. |
| Roni Coins | `/coins` | Gold gradient balance card, quick actions, the earning catalogue with a once-a-day check-in, and coin history. |
| Weekend Auction | `/auction` | Live countdown to a 3-day lot, current highest bid, bid placement with confirmation, bid history, and a brand-new/delivery/warranty strip. |
| Coin Shop | `/coin-shop` | Category chips and a redeemable reward catalogue drawn from the wallet balance. |

### New providers

- `providers/coins_provider.dart` — wallet balance, earn/redeem, daily check-in, history.
  Persisted to shared preferences.
- `providers/auction_provider.dart` — lot, per-second countdown, minimum bid, bid history.
  Persisted; cancels its timer on `dispose`.

Both follow the existing `LocalStoreNotifier` pattern and keep the app's honest local-demonstration
boundary: no coins or bids are issued by a server, and no money moves.

## Screens restyled

Home, Categories/catalog, Search, Product details, Cart, Checkout, Orders, Profile, Wishlist,
Notifications (list + detail), Help, Settings, Recently viewed, Write review, Auth, Addresses.

Behaviour, provider wiring, validation, persistence, totals math, and route names were all
preserved — this was a presentation pass.

## Fixes made during the pass

- Two `RoniSectionHeader`s were placed directly in a `CustomScrollView` sliver list instead of
  inside `SliverToBoxAdapter`, which crashed the home screen at boot.
- The write-review star picker was a fixed-width row and overflowed by 32 px at 320 px; the
  stars are now `Expanded` so they fit any width.
- The checkout order summary and confirm action moved out of the scrolling form into a sticky
  `bottomNavigationBar`, matching the mockup's persistent "Place Order" bar. They were also
  being built lazily below the fold, which made them unreachable on a 390×900 screen.
- Five `textTheme.*.copyWith(...)` calls on nullable styles, and one missing colour import.
- Hardcoded terracotta tints in `product_card.dart` replaced with the palette's red family;
  the `SaleBadge` gradient is now a true red to match the mockup's discount chips.

## Deliberate omissions

Two mockup elements were **not** faked, because no supporting API exists and adding one would
have invented order maths:

- **Cart "select all" + per-line checkboxes** — `CartProvider` has no selection concept, so the
  boxes could not affect the totals and would have misled.
- **Rewards/coins toggle and express-delivery pricing at checkout** — there is no discount or fee
  logic to bind to; `CoinsProvider` is a wallet with no checkout hook. The delivery row shows the
  fee the cart already computes rather than claiming "free".

Payment Methods / Reviews / Returns rows were also left out of the profile menu — no screens or
routes exist for them, and dead controls were deliberately avoided.

## Validation

- `flutter analyze --no-pub` — clean
- `flutter test --no-pub` — 45/45 passing, including 16 new tests in `test/roni_features_test.dart`
  covering the coins wallet, the auction, and the new route map
- `flutter build web --no-web-resources-cdn --no-pub` — succeeds

New tests assert the once-per-device splash, the returning-visitor path, the five-tab bar, that
cart and wishlist are pages rather than tabs, and that every tab and Roni destination generates
a route. `customer_flows_test.dart` now treats the search screen as full-width
`SearchResultRow`s (renamed from a private widget for testability) rather than `ProductCard`s.

## Run locally

```powershell
cd C:\shop\customer_app
flutter run -d chrome --web-port=8080
```

Refreshable example links: `/#/splash`, `/#/coins`, `/#/auction`, `/#/coin-shop`,
`/#/deals`, `/#/product-details?id=1`, `/#/order-tracking?id=ORD-9412`.

## Recovery

Pre-reskin copies of `lib` and `test`: `C:\shop\.roni-reskin-backup`
(an earlier review backup remains at `C:\shop\.customer-review-backup-20260926`).

## Still required before production

Unchanged from the previous review and not addressed here:

- Connect an authenticated customer account to the Laravel API with a single live catalog
  contract; the backend's schema and fiat/token payments cannot accept these local IDs or IQD
  totals as-is.
- Implement server-authoritative prices, coupons, stock/variants, delivery charges, and orders
  before enabling real purchases.
- Integrate a payment gateway, real delivery updates, customer support, and push delivery.
- Add complete translations, a dark palette, and a currency conversion policy.
