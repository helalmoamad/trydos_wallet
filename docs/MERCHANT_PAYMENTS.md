# Paying a merchant

Implementation of the internal guide *"Paying a merchant: what the RDB customer
app and web must build"* (2026-09-15) in this Flutter package.

A customer enters or scans a code, sees who is asking for money and how much,
and pays from their wallet. This package is the mobile client, so §5 of the
guide (customer web) is out of scope here — see [Not in scope](#not-in-scope).

## The three endpoints

All with the normal user access token, like every other screen.

| Endpoint | Where |
|---|---|
| `GET /payment-requests/lookup/{code}` | `MerchantPaymentsApiService.resolveCode` |
| `GET /merchant/payments/lookup/{code}` | `MerchantPaymentsApiService.lookupMerchantPayment` |
| `POST /merchant/payments/{id}/pay` | `MerchantPaymentsApiService.payMerchantPayment` |
| `GET /merchant/payments/my` | `MerchantPaymentsApiService.fetchMyMerchantPayments` |

Every other route under `/merchant/…` — create, cancel, refund — belongs to the
shop's own server and is signature-authenticated. This client never calls them
and never signs anything.

## The flow

Two ways in, one destination.

```
 the one scanner                     "Pay a merchant"
 (reads any code)                    (types a code)
        │                                   │
        │  PaymentCode.isResolvable()       │
        │  ← a string in no namespace is    │
        │    refused before it can spend    │
        │    one of the ten lookups the     │
        │    throttle allows                │
        ▼                                   ▼
      GET /payment-requests/lookup/{code}
        │
   branch on `kind`
        │
   ┌────┴─────────────────────┐
kind=USER                 kind=MERCHANT
peer request              MerchantPayModal
(existing send flow)      → confirm → pay → receipt
```

**One scanner, not two.** `transfer_send_modal._applyScannedRaw` sends whatever
was read to the resolve endpoint and branches on what comes back. There is no
second scanner anywhere, and `MerchantPayModal` deliberately has none of its
own: the wallet scans in one place and routes on what it read.

**Typing a code has its own entry.** "Pay a merchant" sits under Send and
Receive in the scanner sheet and opens `MerchantPayModal` with an empty,
correctly-labelled **payment code** field. The transfer screen's recipient field
was left exactly as it was — accounts only, `0000-0030` — because a field
labelled "recipient account number" should not quietly accept something that is
neither a recipient nor an account.

`MerchantPayModal` mirrors the transfer screen's layout: same header, same dark
wallet card, same field chrome. Resolving a code fills the fields read-only and
switches the wallet card to the asset the request names.

## Where the rules live

| Rule (guide §) | Where |
|---|---|
| Amounts are decimal strings, never through a float (§3.1) | `DecimalAmount`; every amount model holds a `String` |
| Unknown statuses render neutrally, never "paid" (§3.2, §7) | `MerchantPaymentStatus.unknown`, `isSettled` |
| Branch on the error `code`, not the message (§3.3) | `ApiResult.errorCode` / `.statusCode`, `MerchantPaymentErrors` |
| The server decides; no optimistic state (§3.4) | `MerchantPaymentOutcome` has no "probably paid" branch |
| One idempotency key per payment, reused on retry (§3.5) | `MerchantPaymentController.idempotencyKey`, generated once per screen |
| Both languages, with fallback (§3.7) | `MerchantLocalizedText.resolve` |
| Shop name outweighs the amount (§4.2) | `MerchantPayModal._buildMerchantHeader` |
| Short balance surfaced before the tap (§4.2) | `_buildWalletCard`, with a top-up action |
| `payable: false` disables paying and offers a new code (§4.2) | `_buildBlockedCard` |
| One in-flight call; a second tap does nothing (§4.3) | `MerchantPaymentController.isInFlight` + `_isPaying` |
| Retry a lost response with the same key, then reconcile (§4.3, §9) | `MerchantPaymentController.pay` → `_reconcile` |
| `409` refreshes and shows the current state (§4.3) | `MerchantPaymentNotPayable` → `_refreshLookup` |
| Receipt with share/save (§4.4) | `SuccessfulPage` (captures a PNG) |
| `successUrl` is "return to the shop", never proof (§4.4) | `MerchantPaymentResult.successUrl`, rendered in the receipt footer |
| History as its own section, refunds shown honestly (§4.5) | `MerchantPaymentsPage`, reached from Settings |
| Scanner reuses the camera permission flow (§6) | existing `QRScannerPage` |
| Killed mid-payment → check before telling the user anything (§6) | `PendingMerchantPaymentStore` + `reconcilePendingAttempt`, run on launch and on reconnect in `home_page.dart` |
| Expiry mid-screen disables paying and refreshes (§9) | `MerchantPayModal._restartTicker` |
| KYC routed into verification with a way back (§1, §9) | `_isKycBlocked` pre-check and `MerchantPaymentNeedsKyc` → `FirstPageKyc` |
| Codes trimmed before sending (§9) | `PaymentCode.normalize` |

Error copy (§8) is in `app_strings.dart` under `merchant_error_*`, in all four
languages the wallet ships. The English and Arabic wording is the guide's.

## Decisions taken

The guide left five decisions open (§12). Two of them shaped this code:

1. **Where "pay a merchant" lives** — the *scanner* stays single, per §4.1's
   "one scan button, not two": one scanner reads every code and routes on the
   `kind` the server returns. *Typing* a code gets its own labelled entry under
   Send and Receive, which is the same §4.1's "a **Pay** action plus a QR
   scanner", and is what both the RDB guide and the Trydos store's customer copy
   ("choose *Pay a request*") assume exists.

   An earlier revision folded code entry into the transfer screen's recipient
   field. That was reverted: the field is labelled "recipient account number",
   and a payment code is neither.
2. **Source account** — not a choice. The wallet that pays is the customer's
   MAIN account **for the asset the request names**: a USD request is paid from
   the USD wallet, and its `accountNumber` is sent explicitly. There is no
   cross-asset conversion in this flow, so when no matching wallet exists the
   screen says so rather than paying from something else.
4. **Receipt sharing format** — image, reusing the wallet's existing receipt
   capture.

Decisions 3 and 5 needed nothing: the guide's own default (MAIN) is what
decision 2 resolves to, and nothing here hard-codes the assumption that a
payment comes from the payer's own wallet beyond the account number it sends.

## Payment links: wiring the host app

Full integration guide, including the Android and iOS setup:
**[HOST_DEEP_LINKS.md](HOST_DEEP_LINKS.md)**.

In short — the library owns the routing, the host owns the OS plumbing, and one
call is the whole Dart integration:

```dart
// main.dart, after TrydosWallet.init(...)
final appLinks = AppLinks();

// A link that launched the app from closed.
TrydosWallet.handleIncomingLink(await appLinks.getInitialLink());

// Links that arrive while the app is running.
appLinks.uriLinkStream.listen(TrydosWallet.handleIncomingLink);
```

Pass **every** incoming link, including your own app's unrelated deep links.
`handleIncomingLink` validates the code against the known namespaces and returns
false without doing anything when the link is not a payment link, so there is no
need to filter first — and no lookup is spent on a link that was never ours.

Accepted shapes: `https://<host>/r/v1/<code>`, `<scheme>://r/v1/<code>`,
`<scheme>://pay?code=<code>`, and a bare code via `handlePaymentCode` — which is
what a push notification payload carrying a code should call.

### What happens on a tap

```
link tapped
    │
TrydosWallet.handleIncomingLink(uri)
    │
PaymentLink.extractCode  →  not ours?  →  returns false, nothing happens
    │ ours
    ├── wallet UI listening?  ──yes──▶  delivered on TrydosWallet.paymentCodes
    │                          no  ──▶  buffered (cold start, or still on the
    │                                    host's login screen)
    ▼
home_page listens, and waits for balances to resolve
    │
    ▼
same flow a scan takes: resolve → confirm → pay → receipt
```

The wait on balances is deliberate. The confirmation screen names the wallet
that pays and whether its balance covers the amount, so opening it mid-load
would tell the customer they have no wallet for the asset. On a cold start the
code sits in the buffer until the wallet mounts and its balances land — which
also means a link tapped before login survives the login round trip and opens
afterwards, rather than being swallowed.

A second link arriving while a sheet is open is queued, not stacked.

### What the host still has to do natively

Register the paths so the OS hands the link to the app at all — an
`intent-filter` on Android, associated domains or a custom scheme on iOS. That
part is **premature until the payment link page at `/r/v1/<requestCode>`
actually exists** (open decision 2): nothing generates those links today. The
custom-scheme fallback can be registered now and tested by hand.

## Not in scope

* **§5, customer web.** A separate product. The payment link page at
  `/r/v1/<requestCode>` does not exist on any domain yet, so the backend returns
  no link and shops show the 10-digit code.
* **Notification content.** The backend sends both notifications already
  localized. `PaymentCodeLauncher.openMerchantPayments` is the deep-link target
  for the payer's "Payment sent" notification — do not rebuild the text.

Until the link page exists, shops must not print QR codes containing a link.
The only safe QR content is the code itself.

## An assumption worth flagging

The guide shows `feeAmount` alongside `amount` but does not say whether the fee
is added to the amount or already included in it. This client treats it as
**additive**: the balance check requires `amount + feeAmount`, and when the fee
is non-zero the confirmation screen shows amount, fee and total separately. If
the backend means it as inclusive, `MerchantPayModal._totalDue` is the one place
to change.

## Tests

`test/merchant_payment_test.dart` covers the rules rather than the plumbing:
exact decimal arithmetic, code classification and trimming, link extraction,
neutral handling of unknown statuses, `kind` routing, refund reporting, and the
error mapping — including that two different 403s are told apart by `code` and
that a timeout is not a failure to show.
