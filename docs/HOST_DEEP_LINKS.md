# Opening a payment link — host app integration

For the team that owns the app embedding `trydos_wallet`.

A customer receives a payment link from a shop, taps it, and lands directly on
the wallet's payment confirmation screen — shop name, amount, order reference —
without typing a code.

The library owns everything after the link arrives: parsing, routing, the
confirmation screen, the payment, the receipt. **The host owns exactly two
things**: letting the OS hand the link to the app, and passing that link to the
library. This document covers those two.

---

## 1. Dart wiring

One dependency of your choosing for receiving links — [`app_links`][app_links]
is the usual pick — and two calls.

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

That is the whole integration. Put it wherever your other library stream
subscriptions live — next to `logoutEvents`, `languageChangeEvents` and the
rest.

### Pass every link, unfiltered

`handleIncomingLink` inspects the link and returns:

* **`true`** — it carried a payment code; the library has taken responsibility
  for it.
* **`false`** — not a payment link; nothing happened, nothing was consumed.

So route **all** of your app's incoming links through it, including your own
unrelated deep links. Do not try to match paths yourself — you would duplicate
logic the library already owns, and get it wrong when the format changes.

```dart
_appLinks.uriLinkStream.listen((uri) {
  if (TrydosWallet.handleIncomingLink(uri)) return;  // wallet took it
  _myOwnRouter.handle(uri);                          // everything else
});
```

Filtering also matters for a reason that is not obvious: failed code lookups are
rate-limited server-side (10 per 15 minutes). The library validates the code
shape locally *before* any network call, so a stray link costs nothing. Doing
your own guesswork and passing junk would burn those attempts.

### Accepted link shapes

| Shape | Example |
|---|---|
| Universal / app link | `https://pay.example.com/r/v1/mp.7Kd2q` |
| Custom scheme | `rdb://r/v1/mp.7Kd2q` |
| Query parameter | `rdb://pay?code=4817302956` |
| Bare code (not a URL) | `TrydosWallet.handlePaymentCode('4817302956')` |

Codes come in three namespaces: `mp.…` (merchant request), `pr.…` (request from
another wallet user), and a 10-digit counter code. The library resolves all
three through one endpoint and opens the right screen — you never need to tell
them apart.

`handleIncomingLinkString(String)` exists for links that reach you as text
rather than a `Uri`.

### Push notifications

The backend sends the payer a localized "Payment sent … Receipt RDB-R-…"
notification. Deep-link it to the customer's receipts:

```dart
// inside your notification tap handler, with a wallet BuildContext
PaymentCodeLauncher.openMerchantPayments(context);
```

If a notification payload instead carries a payment *code*, hand it over with
`TrydosWallet.handlePaymentCode(code)` — same routing as a link.

Do not rebuild the notification text. It arrives ready in English and Arabic.

---

## 2. Android

Two intent filters in `android/app/src/main/AndroidManifest.xml`, inside the
`<activity android:name=".MainActivity">` block. Note `android:launchMode` must
be `singleTop` (Flutter's default template already sets this) so a link arriving
while the app is running reaches `uriLinkStream` instead of starting a second
activity.

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTop"
    android:exported="true">

    <!-- existing MAIN/LAUNCHER filter stays as it is -->

    <!-- Verified App Link: opens the app with no chooser dialog. -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="https"
            android:host="pay.example.com"
            android:pathPrefix="/r/v1" />
    </intent-filter>

    <!-- Custom-scheme fallback: works with no server setup at all. -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="rdb" />
    </intent-filter>
</activity>
```

`android:autoVerify="true"` requires a `assetlinks.json` file served at
`https://pay.example.com/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.yourapp",
    "sha256_cert_fingerprints": ["<your release signing SHA-256>"]
  }
}]
```

Get the fingerprint with:

```bash
keytool -list -v -keystore <your.keystore> -alias <your-alias>
```

Include the **Play App Signing** fingerprint too, not just your upload key —
otherwise verification works in debug and silently fails in production.

### Testing

```bash
# custom scheme — needs no server
adb shell am start -a android.intent.action.VIEW -d "rdb://r/v1/mp.test123"

# app link
adb shell am start -a android.intent.action.VIEW -d "https://pay.example.com/r/v1/mp.test123"

# check that verification actually succeeded
adb shell pm get-app-links com.example.yourapp
```

---

## 3. iOS

### Universal links

Add the domain in Xcode → *Signing & Capabilities* → *Associated Domains*, or
directly in `ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:pay.example.com</string>
</array>
```

And serve `https://pay.example.com/.well-known/apple-app-site-association` —
as JSON, with `Content-Type: application/json`, no redirects, no `.json`
extension:

```json
{
  "applinks": {
    "details": [{
      "appIDs": ["TEAMID.com.example.yourapp"],
      "components": [{ "/": "/r/v1/*" }]
    }]
  }
}
```

### Custom scheme

In `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.example.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>rdb</string>
        </array>
    </dict>
</array>
```

### Testing

```bash
xcrun simctl openurl booted "rdb://r/v1/mp.test123"
xcrun simctl openurl booted "https://pay.example.com/r/v1/mp.test123"
```

Universal links do not open from Safari's address bar — tap them from Notes or
Messages instead, or the test will look like a failure when it isn't.

---

## 4. What the customer sees

```
link tapped
    │
TrydosWallet.handleIncomingLink(uri)
    │
    ├── not a payment link ──▶ returns false, your router handles it
    │
    ├── wallet UI running ──▶ delivered immediately
    │
    └── wallet UI not up yet ──▶ buffered
         (cold start, or the customer is still on your login screen)
              │
              ▼
        replayed the moment the wallet mounts
              │
              ▼
        waits for balances to load, then opens:
        resolve → confirmation → pay → receipt
```

| Situation | Behaviour |
|---|---|
| App closed, link tapped | Buffered, then opened once the wallet is up and its balances have loaded |
| App running, wallet open | Opens immediately |
| Customer not signed in | Buffered; opens after login, so the link is not lost |
| Payment sheet already open | Second link is queued, not stacked on top |
| Two links before the wallet mounts | The most recent one opens — it is the one the customer is looking at |
| Link is not a payment link | Ignored; `false` returned, no lookup spent |
| Code invalid or expired | The confirmation screen says so and offers "ask the shop for a new code" |

The wait on balances is deliberate, not a delay to optimise away: the
confirmation screen names the wallet that pays and whether its balance covers
the amount. Opening it mid-load would tell a customer who owns a USD wallet that
they have none.

---

## 5. Do not

* **Do not parse the code yourself** and call an API with it. Pass the whole
  `Uri` and let the library route it — it enforces the rate-limit protection,
  namespace validation and the one-endpoint rule that keep this flow safe.
* **Do not treat opening a link as proof of payment.** A link is a request to
  pay. Only the payment response says money moved.
* **Do not print QR codes containing a payment link — yet.** See below.
* **Do not build your own payment screen** from anything in the link. The link
  carries a code and nothing else; the amount and the shop name come from the
  server, never from the URL.

---

## 6. Status: links are not live yet

The client side is complete and tested. What does not exist yet is the **web page
that serves `https://<host>/r/v1/<requestCode>`** — so today the backend issues
no links, and shops show the 10-digit code instead. Who builds that page, and on
which domain, is still an open product decision.

What this means practically:

* **You can wire and register the custom scheme now** (`rdb://…`) and test the
  whole flow end to end by hand. Nothing is blocked.
* **The `https` app-link half needs the domain settled first**, since
  `assetlinks.json` and `apple-app-site-association` must be served from it.
* **Shops must not print link QR codes until that page is live.** A customer who
  scans one with the phone's own camera, rather than with this app, would land on
  a page that does not exist. The only safe QR content today is the code itself —
  and the wallet's own scanner already reads that, plus account QRs and the
  existing encrypted request QRs, with no host setup at all.

---

## Checklist

- [ ] `app_links` (or equivalent) added to the host app
- [ ] `getInitialLink()` passed to `TrydosWallet.handleIncomingLink`
- [ ] `uriLinkStream` piped to `TrydosWallet.handleIncomingLink`
- [ ] Unrelated links still reach your own router when it returns `false`
- [ ] Custom scheme registered on Android and iOS, tested with `adb` / `simctl`
- [ ] "Payment sent" notification deep-linked to `openMerchantPayments`
- [ ] Domain chosen, and `assetlinks.json` + `apple-app-site-association` served *(blocked on the link page)*
- [ ] `android:autoVerify` confirmed with `adb shell pm get-app-links` *(blocked on the above)*

[app_links]: https://pub.dev/packages/app_links

---

For how the payment flow itself works, and how each rule of the internal guide
maps to the code, see [MERCHANT_PAYMENTS.md](MERCHANT_PAYMENTS.md).
