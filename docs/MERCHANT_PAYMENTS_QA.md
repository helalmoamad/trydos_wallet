# Merchant payments — what can be tested today

Three tiers: what needs nothing, what needs a real payment code, and what is
blocked on work that has not shipped anywhere yet.

---

## Preconditions

| Need | For |
|---|---|
| A **KYC-verified** RDB user with a **funded** wallet | every payment test |
| A **second, unverified** user | the KYC routing test |
| A wallet funded in the **same currency** the request names | there is no cross-asset conversion in this flow |
| A source of merchant codes | tier 2 onwards — see below |

Two ways to get a code to pay:

* **Trydos store** — `POST {base}/api/v1/customer/order/checkout/rdb` returns
  `short_code` (10 digits) and `request_code` (`mp.…`). Needs the backend branch
  `ticket/rdb-merchant-payment-requests`.
* **RDB directly** — `node scripts/merchant-payment-e2e.js` creates a test shop
  and payment requests end to end and prints what it made. Localhost only.

Running the wallet:

```bash
cd example
flutter run \
  --dart-define=WALLET_TOKEN=<jwt> \
  --dart-define=WALLET_BASE_URL=https://... \
  --dart-define=WALLET_KYC_BASE_URL=https://...
```

---

## Tier 0 — no backend, no device

```bash
flutter analyze lib test          # expect: no issues
flutter test test/merchant_payment_test.dart
```

52 tests covering the rules rather than the plumbing: exact decimal arithmetic,
code classification and trimming, link extraction, unknown statuses staying
neutral, `kind` routing, refund reporting, and the error mapping — including
that two different 403s are told apart by `code` and that a timeout is not a
failure to show.

> `flutter test` on the whole suite also runs `test/trydos_wallet_test.dart`,
> whose splash test fails with a `RenderFlex` overflow. **This is pre-existing**
> and unrelated — verified against a clean tree.

---

## Tier 1 — device, no merchant code needed

Regression on the paths that were rewired, plus the new local behaviour. None of
this needs a shop.

| # | Step | Expected |
|---|---|---|
| 1.1 | Scan an account QR (from another user's Receive screen) | Recipient fills as before — **regression** |
| 1.2 | Scan a `PAYREQ:` request QR from another wallet | Peer request flow fills amount, purpose, expiry — **regression**, this path now goes through the shared resolve endpoint |
| 1.3 | Scan a foreign QR (Wi-Fi QR, any website QR) | Clear "this QR code is not recognised" message, and the recipient field is **not** polluted with the raw text |
| 1.4 | Transfer screen → recipient field, type digits | Accounts **only**, `0000-0030`, capped at 8 digits — **regression**: a payment code does not belong in this field |
| 1.5 | Scanner sheet → third option under Send and Receive | **Pay a merchant** opens a screen laid out like the transfer screen, whose first field is labelled *payment code* — and which has **no scanner of its own** |
| 1.6 | Type a well-formed but non-existent 10-digit code there | "This code is not valid. Check it with the shop." shown under the field; the lookup fires once, on the tenth digit |
| 1.7 | Repeat 1.6 ten times inside 15 minutes | Switches to "Too many attempts. Try again in a few minutes." and stops retrying |
| 1.7b | Resolve a code, then tap **edit** on the code field | Clears back to an empty code field, ready for another code |
| 1.8 | Settings → **Merchant payments** | Opens; empty state, or a list; pull-to-refresh works |
| 1.9 | Switch language ar / en / ku / tr | Every new string is translated; layout stays RTL-correct |

### 1.10 Deep-link plumbing without any OS setup

The routing can be exercised before any manifest work, by calling the host entry
point directly. Add a temporary debug button to the example app:

```dart
TrydosWallet.handlePaymentCode('4817302956');
```

Expected: the payment sheet opens on the same flow a scan takes. Call it while
the wallet is still loading to confirm the buffering — the sheet must wait for
balances rather than claiming you have no wallet for the currency.

---

## Tier 2 — with a real merchant code

The core of the feature. Run these against a sandbox shop.

### Happy path

| # | Step | Expected |
|---|---|---|
| 2.0 | **Scan the QR on the Trydos payment screen** from a second phone | Goes straight to the payment screen with every field filled, the code shown in the code field, and the wallet card switched to the request's asset |
| 2.1 | Scanner sheet → **Pay a merchant** → type the `short_code` | Same screen, same filled fields — typing and scanning differ only in how the code arrived |
| 2.2 | Check the figures | Amount shown exactly as the API sent it (`100.00`, not `100`); order reference; description in the user's language |
| 2.3 | Check the wallet row | Names the MAIN wallet **for the request's currency**, with its balance |
| 2.4 | Pay | Receipt: receipt number, shop, amount, order reference, date, wallet |
| 2.5 | Save / share the receipt | Image saved to gallery / share sheet opens |
| 2.6 | Store side | Polling turns `paid`; `order_ids` filled; orders appear |
| 2.7 | Settings → Merchant payments | The payment is listed |

### Refusals and edges

| # | Step | Expected |
|---|---|---|
| 2.8 | Pay with a balance below the amount | Warning **before** tapping pay, plus a top-up action; pay button disabled |
| 2.9 | Code in a currency you hold no wallet for | "You have no {symbol} wallet"; pay disabled |
| 2.10 | Let the countdown reach zero on screen | Pay disables itself and the request refreshes — the customer never taps into a failure |
| 2.11 | Pay a code someone already paid | "This request was already paid or is no longer valid" — framed as fact, not as the customer's mistake |
| 2.12 | Double-tap pay quickly | Exactly one request, one debit |
| 2.13 | Pay as the **unverified** user | Routed into identity verification, with a way back to the code |
| 2.14 | Cancel the request from the shop side, then pay | "Cancelled by the shop", with "ask the shop for a new code" |
| 2.15 | `successUrl` present on the receipt | "Return to the shop" opens the browser — and is never presented as proof of payment |

### The ones that matter most

These are the tests worth doing carefully, because they are where a bug costs a
customer real money.

| # | Step | Expected |
|---|---|---|
| 2.16 | **Airplane mode the instant you tap pay**, then restore it | No failure message while unknown. The attempt retries with the **same** key. If it went through, the original receipt comes back — **never a second debit** |
| 2.17 | **Kill the app mid-payment**, relaunch | On launch the pending attempt reconciles before anything is said. If it settled: a success message and refreshed balances. Never "payment failed" |
| 2.18 | Pay the same code twice deliberately, from two devices | One pays; the other gets "already paid". One debit total |
| 2.19 | Refund part of the payment from the merchant panel | History shows **both** figures — "Paid 100.00, Refunded 25.00" — not a net number |

For 2.16, airplane mode at the right moment is fiddly; a proxy that drops the
`POST /merchant/payments/{id}/pay` response after the server handled it is the
reliable way to reproduce it.

---

## The first real run, step by step

Once the store's `checkout/rdb` endpoint is deployed, this is the shortest path
from nothing to a paid order.

### 0. Two identities — do not mix them up

| | Who | Token | Talks to |
|---|---|---|---|
| **Store customer** | places the order | `Authorization: Bearer <Trydos customer token>` | `{store_base}/api/v1/…` |
| **Wallet payer** | pays the code | `WALLET_TOKEN` passed to the example app | the **RDB** API |

They can be two different people — anyone with an RDB account may pay a code.
The most common first-run failure is pointing `WALLET_BASE_URL` at the store
host. The store creates the request *on RDB*; the wallet talks to RDB.

### 1. Clear any pending request

A previous attempt leaves the cart locked, and checkout answers `409` with
`data.rdb_request_reference`. Cancel it:

```bash
curl -X POST "$STORE/api/v1/customer/order/rdb-request/$REF/cancel" \
  -H "Authorization: Bearer $STORE_TOKEN" -H "Accept: application/json"
```

### 2. Check out and take the code

```bash
curl -X POST "$STORE/api/v1/customer/order/checkout/rdb" \
  -H "Authorization: Bearer $STORE_TOKEN" \
  -H "Accept: application/json" -H "Content-Type: application/json" \
  -d '{"address_id": <default address id>}'
```

Keep four values from `data`: `short_code`, `request_reference`, `amount`,
`currency`.

### 3. Confirm the payer can actually pay

`currency` from step 2 must match a **funded MAIN wallet** on the RDB user, and
that user must be KYC-verified. There is no cross-asset conversion here: a USD
request is paid from the USD wallet or not at all.

### 4. Run the wallet

```bash
cd example
flutter run \
  --dart-define=WALLET_TOKEN=<rdb jwt> \
  --dart-define=WALLET_BASE_URL=<rdb api host> \
  --dart-define=WALLET_KYC_BASE_URL=<rdb kyc host>
```

### 5. Enter the code

Send screen → type the 10 digits of `short_code`. Grouping becomes
`481 730 2956`, and the lookup fires **once**, on the tenth digit — not per
keystroke.

### 6. Watch the wire

Long-press the **Settings** tab to open the in-app network inspector (debug
builds only). Two calls tell you everything:

| Call | Confirms |
|---|---|
| `GET /payment-requests/lookup/4817302956` → `"kind": "MERCHANT"` | one scanner resolved a merchant code |
| `POST /merchant/payments/{id}/pay` with `idempotencyKey` + `accountNumber` | paying by request **id**, from the currency-matched wallet |

### 7. Confirm from the store side

```bash
curl "$STORE/api/v1/customer/order/rdb-request/$REF" \
  -H "Authorization: Bearer $STORE_TOKEN" -H "Accept: application/json"
```

`status` → `paid`, `order_ids` filled, cart unlocked.

### When it fails, read it here first

| Symptom | Cause |
|---|---|
| Nothing happens as you type | Fewer than 10 digits, or the code has non-digits — that is a `mp.…` code, which only the scanner path takes |
| Lookup `404` | `WALLET_BASE_URL` points at the store instead of RDB; or the code expired; or you used `request_reference` instead of `short_code` |
| Lookup returns `kind: "USER"` | You pasted a peer request code, not a merchant one |
| `429` on lookup | Ten wrong codes in 15 minutes. Wait it out — this is brute-force protection working |
| Pay `403` | Payer not KYC-verified, or the request is reserved for a specific customer |
| Pay `400` | Balance short, or the wallet currency does not match the request |
| Pay `409` | Already paid — including by an earlier run of your own test |
| "You have no {symbol} wallet" | Step 3 |

`short_code` is **recycled by RDB** after a request ends. Never re-use one from
an earlier run: it may now belong to somebody else's request.

---

## Tier 3 — blocked, not testable

| What | Blocked on |
|---|---|
| Scanning a QR that contains a **payment link** | `payment_url` is `null` — RDB's hosted payment page is not enabled |
| Universal links / Android App Links, `assetlinks.json`, `apple-app-site-association` | No domain chosen and no page to serve; open product decision |
| An `rdb://` link arriving from the store | The store guide states plainly there is no RDB app deep link in this release |

The client half of all three is implemented and unit-tested, so when the page
ships the work is registration and verification, not development.

**Today the customer either scans the Trydos payment screen's QR or types the
10 digits.** Since 2026-09-17 the Trydos app renders the `short_code` as a QR
carrying the bare digits — no scheme, no prefix, no URL. That needs nothing from
this wallet: a 10-digit scan already routes exactly like a typed one. The
`payment_url`, `qr_payload` and `deep_link` fields remain `null`, which is why
the code itself is what gets encoded.

---

## One wording detail worth aligning

The store's own copy tells the customer:

> "Open the RDB app, choose **Pay a request**, enter this code and confirm"

The wallet now *has* a labelled entry, so the instruction works — but it is
called **"Pay a merchant"** and lives in the scanner sheet, under Send and
Receive. Either wording is fine to ship; matching them exactly is a five-minute
change on whichever side prefers to move.

Customers who scan the QR never see either label: the scanner routes them
straight to the payment screen.
