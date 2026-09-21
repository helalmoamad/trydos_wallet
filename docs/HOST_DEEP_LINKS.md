# Opening a payment link — host app integration

For the team that owns the app embedding `trydos_wallet`.

A customer on the Trydos store taps **"Open the wallet app"**, this app opens,
and the payment confirmation screen is already filled in — shop name, amount,
order reference. No code typed, no QR scanned.

The library owns everything from the moment the link reaches it: parsing,
routing, the confirmation screen, the payment, the receipt. **The host owns
exactly two things**: letting the OS hand the link to the app, and passing that
link to the library. This document covers those two.

---

## 1. The link, exactly as Trydos sends it

```
https://rdb-ms.yazan-adnof.workers.dev/?code=MERPAY%3Amp.cwewkCUKhUSP-MjXRCTJxg
```

| Part | Value |
|---|---|
| host | `rdb-ms.yazan-adnof.workers.dev` |
| path | `/` |
| parameter | `code` |
| value, decoded | `MERPAY:<request_code>` |

`<request_code>` is the payment request's `request_code` — case-sensitive, no
fixed length, and it may contain `-`, `_` and `.`.

The value is **byte-for-byte the same payload the QR carries**. One payload,
two transports — which is why the library runs both through the same parser.

### Already handled, and pinned by tests

No library work is outstanding. All of these resolve to
`mp.cwewkCUKhUSP-MjXRCTJxg` today:

| Shape | Status |
|---|---|
| `…workers.dev/?code=MERPAY%3Amp.…` — **the live one** | ✅ |
| `…workers.dev/?code=mp.…` — no envelope, the "be tolerant" case | ✅ |
| `…workers.dev/pay/mp.…` — path style | ✅ |
| `rdb://pay?code=MERPAY%3Amp.…` — custom scheme | ✅ |
| `…workers.dev/` — no code at all | ✅ ignored, app opens normally |
| `…workers.dev/?code=MERPAY%3A` — envelope, no code | ✅ ignored |

So if Trydos changes the link shape (their §5), nothing here needs to change.

---

## 2. Dart wiring — the whole integration

One dependency for receiving links — [`app_links`][app_links] is the usual pick
— and two calls.

```yaml
# pubspec.yaml (host app)
dependencies:
  app_links: ^6.3.2
```

```dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _wireDeepLinks();
  }

  Future<void> _wireDeepLinks() async {
    // 1. The link that launched the app from closed.
    TrydosWallet.handleIncomingLink(await _appLinks.getInitialLink());

    // 2. Links that arrive while the app is already running.
    _linkSubscription = _appLinks.uriLinkStream.listen(
      TrydosWallet.handleIncomingLink,
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
```

Put it wherever your other library stream subscriptions live — next to
`logoutEvents`, `languageChangeEvents` and the rest.

### Pass every link, unfiltered

`handleIncomingLink` returns:

* **`true`** — it carried a payment code; the library has taken it from here.
* **`false`** — not a payment link; nothing happened, nothing was consumed.

So route **all** incoming links through it, your own deep links included:

```dart
_appLinks.uriLinkStream.listen((uri) {
  if (TrydosWallet.handleIncomingLink(uri)) return;  // wallet took it
  _myOwnRouter.handle(uri);                          // everything else
});
```

Do not pre-filter by host or path. You would duplicate logic the library owns
and get it wrong the next time Trydos changes the shape — and the library
validates the code locally *before* any network call, so a stray link costs
nothing. Failed lookups are throttled at ten per fifteen minutes; guesswork on
your side would spend those.

`handleIncomingLinkString(String)` exists for links that reach you as text, and
`handlePaymentCode(String)` for a bare code — from a push payload, say.

---

## 3. What happens after the app opens

```
link tapped in Trydos
        │
TrydosWallet.handleIncomingLink(uri)
        │
   code extracted, MERPAY: stripped, namespace checked
        │
        ├── not ours ──────▶ false; your router handles it
        │
        ├── wallet UI up ──▶ delivered at once
        │
        └── wallet UI not up yet ──▶ buffered
             (cold start, or the customer is still on your login screen)
                  │
                  ▼
            replayed the moment the wallet mounts
                  │
                  ▼
            waits for balances to load, then opens the payment screen:
            lookup → confirm → pay → receipt
```

| Situation | Behaviour |
|---|---|
| App closed, link tapped | Buffered, opened once the wallet is up and balances have loaded |
| App open, wallet showing | Opens at once |
| **Not signed in** | Buffered; opens after login — the code survives the round trip |
| Payment sheet already open | A second link is queued, not stacked |
| Two links before the wallet mounts | The most recent opens — it is the one the customer is looking at |
| Code missing or unreadable | Ignored; the app opens normally, no error screen |
| Already paid / expired / cancelled | The payment screen says which, and offers "ask the shop for a new code" |
| Payer is not the buyer | Works. Paying someone else's code is supported, by design |

The wait on balances is deliberate: the confirmation screen names the wallet
that pays and whether its balance covers the amount. Opening it mid-load would
tell a customer who owns a USD wallet that they have none.

---

## 4. Android

In `android/app/src/main/AndroidManifest.xml`, inside
`<activity android:name=".MainActivity">`. `android:launchMode` must be
`singleTop` — Flutter's template already sets it — so a link arriving while the
app runs reaches `uriLinkStream` instead of starting a second activity.

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTop"
    android:exported="true">

    <!-- existing MAIN/LAUNCHER filter stays as it is -->

    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="https"
            android:host="rdb-ms.yazan-adnof.workers.dev" />
    </intent-filter>
</activity>
```

No `pathPrefix`: the live link's path is just `/`, and Trydos may move to
`/pay/<code>` later. Claiming the host covers both.

`autoVerify` needs `assetlinks.json` served at
`https://rdb-ms.yazan-adnof.workers.dev/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.rdb.www",
    "sha256_cert_fingerprints": ["<release signing SHA-256>"]
  }
}]
```

```bash
keytool -list -v -keystore <your.keystore> -alias <your-alias>
```

Include the **Play App Signing** fingerprint as well as the upload key.
Omitting it makes verification pass in debug and fail silently in production.

> The host is a Cloudflare Worker owned by the RDB side, so serving that file is
> a backend task, not an app one. Until it is served, the link still opens the
> app — Android just shows a chooser first.

### Testing

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://rdb-ms.yazan-adnof.workers.dev/?code=MERPAY%3Amp.cwewkCUKhUSP-MjXRCTJxg"

# did verification actually take?
adb shell pm get-app-links com.rdb.www
```

---

## 5. iOS

### Universal links

Xcode → *Signing & Capabilities* → *Associated Domains*, or
`ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:rdb-ms.yazan-adnof.workers.dev</string>
</array>
```

And serve
`https://rdb-ms.yazan-adnof.workers.dev/.well-known/apple-app-site-association`
as JSON, `Content-Type: application/json`, no redirect, no `.json` extension:

```json
{
  "applinks": {
    "details": [{
      "appIDs": ["TEAMID.com.rdb.www"],
      "components": [{ "/": "*" }]
    }]
  }
}
```

### Custom scheme — Trydos is waiting on this

Trydos cannot ask iOS whether a Universal Link has a handler; the only check
Apple allows is `canOpenURL` on a **custom scheme**. Until we give them one,
**the button stays hidden on iPhone** — so this is the item blocking iOS.

Register one in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.rdb.www</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>rdb</string>
        </array>
    </dict>
</array>
```

The library already parses `rdb://pay?code=MERPAY%3A…`, so nothing more is
needed once the scheme is registered.

### Testing

```bash
xcrun simctl openurl booted "rdb://pay?code=MERPAY%3Amp.cwewkCUKhUSP-MjXRCTJxg"
xcrun simctl openurl booted "https://rdb-ms.yazan-adnof.workers.dev/?code=MERPAY%3Amp.cwewkCUKhUSP-MjXRCTJxg"
```

Universal links do not open from Safari's address bar — tap them from Notes or
Messages, or a working setup will look broken.

---

## 6. What to send back to the Trydos team

Their §4.1 asks us two questions, and their §5 offers to change the link.

> **Link shape** — no change needed. The form in your §2 works as sent, and so
> do all three alternatives in your §5. Keep what you have.
>
> **Custom URL scheme** — `rdb://`, once registered (see §5 above). It carries
> the same `code` value, identically encoded: `rdb://pay?code=MERPAY%3A<request_code>`.
> A bare code with no `MERPAY:` prefix is also accepted.
>
> **App Store id** — *(fill in before sending)*.
>
> **Android package** — `com.rdb.www`, as you assumed.

Both answers are the host app team's to confirm; the library side of each is
already implemented and tested.

---

## 7. Do not

* **Do not parse the code yourself** and call an API with it. Pass the whole
  `Uri`. The library enforces the throttle protection, the namespace check and
  the one-endpoint rule that keep this flow safe.
* **Do not treat opening a link as proof of payment.** A link is a request to
  pay; only the payment response says money moved.
* **Do not build a payment screen from anything in the link.** It carries a code
  and nothing else — the amount and the shop name come from the server, never
  from the URL.

---

## Checklist

- [ ] `app_links` (or equivalent) added to the host app
- [ ] `getInitialLink()` passed to `TrydosWallet.handleIncomingLink`
- [ ] `uriLinkStream` piped to `TrydosWallet.handleIncomingLink`
- [ ] Unrelated links still reach your own router when it returns `false`
- [ ] Android intent-filter for `rdb-ms.yazan-adnof.workers.dev`, tested with `adb`
- [ ] iOS custom scheme `rdb://` registered — **blocks the iPhone button**
- [ ] App Store id sent to the Trydos team — **blocks the iPhone button**
- [ ] `assetlinks.json` served from the Worker *(backend)*
- [ ] `apple-app-site-association` served from the Worker *(backend)*
- [ ] `adb shell pm get-app-links com.rdb.www` reports verified

[app_links]: https://pub.dev/packages/app_links

---

For how the payment flow itself works, see
[MERCHANT_PAYMENTS.md](MERCHANT_PAYMENTS.md); for what to test, see
[MERCHANT_PAYMENTS_QA.md](MERCHANT_PAYMENTS_QA.md).
