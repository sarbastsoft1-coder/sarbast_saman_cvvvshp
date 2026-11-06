# Roni — Customer App Design System

The Roni storefront runs in **dark mode by default** and in **Kurdish Sorani
(RTL)**. Both are load-bearing constraints, not preferences: a screen that
ignores them is not "a bit off", it is unreadable or unusable.

This document describes the system the app is now built on. Everything here is
implemented — the tokens are code, not a proposal.

---

## 1. Where things live

| Concern | File |
|---|---|
| Spacing, radii, type scale, motion, elevation | `lib/boutique/core/theme/boutique_tokens.dart` |
| Semantic colours (light + dark) | `lib/boutique/core/theme/boutique_colors.dart` |
| `ThemeData`, text theme, component themes | `lib/boutique/core/theme/boutique_theme.dart` |
| Shared component kit | `lib/boutique/widgets/store_components.dart` |
| Money formatting | `lib/boutique/core/constants/money.dart` |

Read a colour with `RoniPalette.of(context)`. Never with a raw literal.

```dart
final p = RoniPalette.of(context);
Container(color: p.card);   // follows the active theme
```

---

## 2. Tokens

### Spacing — 4pt grid

`xxs 2 · xs 4 · sm 6 · md 8 · lg 12 · xl 16 · xxl 20 · xxxl 24 · huge 32 · giant 40 · massive 48`

Two shortcuts worth knowing:

- `BoutiqueTokens.gutter` (16) — standard screen inset.
- `BoutiqueTokens.sectionGap` (20) — vertical rhythm between page sections.

### Radius — 7 steps

`radiusXs 8 · radiusSm 12 · radiusMd 16 · radiusLg 20 · radiusXl 24 · radiusXxl 32 · radiusPill 999`

### Type — 9 sizes

`display 28 · title1 22 · title2 18 · title3 16 · title4 15 · body 14 · bodySmall 13 · label 13 · caption 12`

Plus `micro 11` for badges, `price 16` / `priceLarge 24` for money, and
`overline 11 w700` for section eyebrows.

The theme's `TextTheme` maps these onto the Material slots
(`displayLarge`, `headlineMedium`, `titleLarge`, `titleMedium`, `titleSmall`,
`bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`,
`labelSmall`), so screens should prefer `Theme.of(context).textTheme.*` and
fall back to `BoutiqueTokens.*` when they need a specific weight.

### Motion — 9 durations

`instant 120 · fast 160 · base 200 · emphasized 240 · sheet 320 · route 340 · entrance 420 · pulse 600 · shimmer 1100`

Curves: `curveStandard` (easeOutCubic), `curveEmphasized` (easeOutBack),
`curveExit` (easeInCubic), `curveAmbient` (easeInOut).

### Hit targets

`tapTarget 44` — the floor for anything a finger has to hit.
`tapTargetCompact 40` — icon buttons inside a card.

---

## 3. Colour

`RoniPalette` resolves per brightness. The light and dark sets cover the same
roles, so a screen written against the palette works in both.

| Role | Token |
|---|---|
| Page background | `p.bg` |
| Card / raised surface | `p.card`, `p.surface` |
| Inset / nested block | `p.soft`, `p.surfaceSunken` |
| Primary text | `p.fg` |
| Secondary text | `p.muted` |
| Tertiary text, hints | `p.onSurfaceVariant` |
| Hairline border | `p.line` |
| Strong border / edge | `p.borderStrong` |
| Brand accent | `p.brand2` |
| Sale / danger | `p.sale`, `p.saleSoft` |
| Rating gold | `p.gold` |
| Success | `p.ok` |

### Status colours

Each status carries a foreground and a wash: `p.statusProcessing` /
`p.statusProcessingWash`, and the same for `Shipped`, `Delivered`, `Cancelled`.

The foregrounds were re-picked so every pair clears **4.5:1** contrast. The
previous values scored 2.37:1 (processing), 2.99:1 (delivered), 4.12:1
(shipped) and 4.37:1 (cancelled) — a status badge a customer cannot read is
the same as no status at all.

---

## 4. Money — one formatter, everywhere

The app used to render prices two different ways: a global `formatPrice()`
producing `"35,000 د.ع"` and a per-product `formatAmount()` producing
`"$78.00"`. The same number could look different on the card, in the cart and
at checkout.

Now every price goes through `Money`:

```dart
Money.format(value, currency: product.currency)  // respects the data
Money.formatIqd(value)                           // "35,000 د.ع"
Money.formatUsd(value)                           // "$78.00"
```

Rules:

- Dinar never shows decimals and always carries thousands separators.
- Fiat keeps two decimals and is also grouped (`$1,250.00`).
- **A checkout summary must format with the cart's currency**, never with a
  hard-coded `$`. Mixed-currency carts must refuse to total rather than
  produce a wrong number.

---

## 5. RTL icon direction

The app forces `TextDirection.rtl`. Flutter mirrors any icon whose
`matchTextDirection` is `true`, so the glyph you write is **not** the arrow the
customer sees. Verified by rendering the icons in an RTL context:

| Written | Points |
|---|---|
| `chevron_left_rounded` | **right** |
| `chevron_right_rounded` | **left** |
| `arrow_forward_rounded` | **left** |
| `arrow_back_rounded` | **right** |
| `arrow_back_ios_rounded` | **right** |
| `navigate_next_rounded` | **left** |
| `navigate_before_rounded` | **right** |
| `west_rounded` | left (never flips) |
| `east_rounded` | right (never flips) |

Therefore:

- **Back / return** (start of an app bar, points right) → `arrow_back_rounded`,
  `arrow_back_ios_rounded`, `chevron_left_rounded`, `east_rounded`.
- **Forward / next / open detail / "see all"** (points left) →
  `arrow_forward_rounded`, `chevron_right_rounded`, `navigate_next_rounded`,
  `west_rounded`.

Classify the icon by the **action** it performs before choosing one.

For layout, use directional APIs — `EdgeInsetsDirectional`,
`AlignmentDirectional`, `PositionedDirectional`, `TextAlign.start/end` — so the
framework mirrors it for you.

---

## 6. Component kit

`lib/boutique/widgets/store_components.dart` is the shared vocabulary.

| Component | Use it for |
|---|---|
| `RoniCard` | The standard raised block. Defaults to the palette's card colour and hairline border. |
| `GoldButton` | Primary CTA — gold gradient, press scale, disabled state. |
| `GhostButton` | Secondary action beside a primary one. |
| `RoniIconButton` | Round icon button with badge and tooltip. |
| `RoniSectionHeader` | Section title with a trailing "see all" action. |
| `RoniSearchField` | The pill search bar, with optional filter suffix. |
| `StatusPill` | Order status chip. |
| `StorePanel` | A bordered surface block. |
| `StoreNotice` | Inline informational note. |
| `StoreEmpty` | Empty state — icon, title, guidance, optional action. |
| `RoniSkeleton` / `RoniSkeletonList` | Loading placeholders. |
| `RoniQuantityStepper` | Quantity control with 44px targets. |
| `RoniRatingRow` | Stars + score + review count, in one readable line. |
| `RoniTrustRow` | The reassurance strip under a product price. |
| `RoniPriceText` | A price rendered the same way everywhere. |
| `RoniAppBar` | Screen header with a back affordance and trailing actions. |
| `RoniErrorState` | Error message with a retry affordance. |

---

## 7. States every screen owes the customer

- **Loading** — a skeleton that matches the shape of the incoming content, not
  a bare spinner.
- **Empty** — an icon, one line of guidance, and a route out of the empty
  state.
- **Error** — what went wrong and a retry button.
- **Success** — a confirmation for anything the customer committed to.

---

## 8. Testing

| Test | What it protects |
|---|---|
| `test/responsive_completion_test.dart` | Every destination renders without overflow at 10 viewport sizes, at 1.2× text scale. |
| `test/layout_audit_test.dart` | Collects **all** overflow sites in one run and writes `build/layout-audit.txt`. |
| `test/customer_flows_test.dart` | The customer journeys. |
| `test/roni_features_test.dart` | The Roni economy providers (wallet, auction). |
| `test/routes_and_providers_test.dart` | Catalogue filters, cart, wishlist, orders. |
| `test/product_discount_test.dart` | Discount maths and the sale card. |

Both layout tests use a **bounded pump** (`test/support/settle.dart`) rather
than `pumpAndSettle`. The storefront runs ambient animations that never stop —
the navigation coin float, the carousel auto-advance, the flash-deal pulse —
so settling to quiescence always times out and reports a false failure
instead of a layout defect.
