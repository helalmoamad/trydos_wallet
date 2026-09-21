# RDB wallet app — wiring the Trydos payment deep link

**To:** the team that owns the RDB app (`com.rdb.www`), which embeds the
`trydos_wallet` library
**From:** the wallet library team
**Date:** 2026-09-21
**Re:** Trydos document *"RDB deep link — reading the payment code from the
link"* (2026-09-21)

---

## Summary

Trydos has added an **"Open the wallet app"** button to its payment screen. The
customer taps it, the RDB app opens, and the payment screen should already be
filled in — shop name, amount, order reference — with nothing typed or scanned.

**The library already does all of this.** Parsing, routing, the confirmation
screen, the payment, the receipt, and the "signed out, sign in first, then
continue to the same request" case are implemented and covered by tests,
including tests that use Trydos's exact link string.

**What we need from you is two things**: let the OS hand the link to the app,
and pass that link to the library. Plus two answers Trydos is waiting on, which
are blocking the button on iPhone.

---

## 1. The link

```
https://rdb-ms.yazan-adnof.workers.dev/?code=MERPAY%3Amp.cwewkCUKhUSP-MjXRCTJxg
```

| Part | Value |
|---|---|
| host | `rdb-ms.yazan-adnof.workers.dev` |
| path | `/` |
| parameter | `code` |
| value, decoded | `MERPAY:<request_code>` |

`<request_code>` is case-sensitive, has no fixed length, and may contain `-`,
`_` and `.`. The value is byte-for-byte the same payload the Trydos QR carries.

### Shapes already handled — no library change needed

| Shape | Status |
|---|---|
| `…workers.dev/?code=MERPAY%3Amp.…` — **the live one** | ✅ |
| `…workers.dev/?code=mp.…` — no envelope | ✅ |
| `…workers.dev/pay/mp.…` — path style | ✅ |
| `rdb://pay?code=MERPAY%3Amp.…` — custom scheme | ✅ |
| `…workers.dev/` — no code | ✅ ignored, app opens normally |
| `…workers.dev/?code=MERPAY%3A` — envelope, no code | ✅ ignored |

If Trydos changes the link shape later (their §5), nothing changes here.

---

## 2. What to add to the app — the whole integration

One dependency for receiving links, and two calls.

```yaml
# pubspec.yaml
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

Put it wherever your other library subscriptions live — next to `logoutEvents`,
`languageChangeEvents` and the rest.

### How the library answers you

`handleIncomingLink` returns:

* **`true`** — the link carried a payment code; the library has taken it from
  here and will open the payment screen itself.
* **`false`** — not a payment link; nothing happened, nothing was consumed.

So route **every** incoming link through it, including your own deep links:

```dart
_appLinks.uriLinkStream.listen((uri) {
  if (TrydosWallet.handleIncomingLink(uri)) return;  // wallet took it
  _myOwnRouter.handle(uri);                          // everything else
});
```

**Please do not pre-filter by host or path.** The library validates the code
locally *before* any network call, so an unrelated link costs nothing. Failed
lookups are rate-limited to ten per fifteen minutes; guesswork on the app side
would spend those attempts on links that were never payments.

Two more entry points exist if you need them:

* `TrydosWallet.handleIncomingLinkString(String)` — a link that arrives as text.
* `TrydosWallet.handlePaymentCode(String)` — a bare code, e.g. from a push
  notification payload.

---

## 3. What the customer sees after that

```
link tapped in Trydos
        │
TrydosWallet.handleIncomingLink(uri)
        │
   code extracted → URL-decoded → "MERPAY:" stripped → namespace checked
        │
        ├── not ours ──────▶ returns false; your router handles it
        │
        ├── wallet UI up ──▶ opens at once
        │
        └── wallet UI not up yet ──▶ buffered
             (cold start, or the customer is still on your login screen)
                  │
                  ▼
            replayed the moment the wallet mounts
                  │
                  ▼
            payment screen: lookup → confirm → pay → receipt
```

| Situation | Behaviour |
|---|---|
| App closed, link tapped | Buffered, opens once the wallet is up and balances have loaded |
| App open, wallet showing | Opens at once |
| **Not signed in** | Buffered; opens after login — the code survives the round trip |
| Payment sheet already open | A second link is queued, not stacked |
| Two links before the wallet mounts | The most recent opens |
| Code missing or unreadable | Ignored; the app opens normally, no error screen |
| Already paid / expired / cancelled | The screen says which, and offers "ask the shop for a new code" |
| Payer is not the buyer | Works — paying someone else's code is supported by design |

The short wait for balances is deliberate: the confirmation screen names the
wallet that pays and whether its balance covers the amount, so opening it
mid-load would tell a customer who owns a USD wallet that they have none.

---

## 4. Android

In `android/app/src/main/AndroidManifest.xml`, inside
`<activity android:name=".MainActivity">`. `android:launchMode` must be
`singleTop` — Flutter's template already sets it — so a link arriving while the
app is running reaches `uriLinkStream` instead of starting a second activity.

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

No `pathPrefix` on purpose: the live link's path is just `/`, and Trydos may
move to `/pay/<code>` later. Claiming the host covers both.

`autoVerify` additionally needs this served at
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

Include the **Play App Signing** fingerprint as well as the upload key —
omitting it makes verification pass in debug and fail silently in production.

> That host is a Cloudflare Worker, so serving the file is a backend task rather
> than an app one. Until it is served the link still opens the app; Android just
> shows a chooser first.

### Testing

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://rdb-ms.yazan-adnof.workers.dev/?code=MERPAY%3Amp.cwewkCUKhUSP-MjXRCTJxg"

# did verification actually take?
adb shell pm get-app-links com.rdb.www
```

Expected: the app opens on the payment screen with
`mp.cwewkCUKhUSP-MjXRCTJxg` resolved and the fields filled.

---

## 5. iOS

### Universal links

Xcode → *Signing & Capabilities* → *Associated Domains*, or in
`ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:rdb-ms.yazan-adnof.workers.dev</string>
</array>
```

And serve, as JSON with `Content-Type: application/json`, no redirect and no
`.json` extension, at
`https://rdb-ms.yazan-adnof.workers.dev/.well-known/apple-app-site-association`:

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

### Custom scheme — this is what blocks the iPhone button

Trydos cannot ask iOS whether a Universal Link has a handler. The only check
Apple allows is `canOpenURL` on a **custom scheme**, so until we give them one
**Trydos keeps the button hidden on iPhone entirely.**

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

The library already parses `rdb://pay?code=MERPAY%3A…`, so registering the
scheme is all that is needed.

### Testing

```bash
xcrun simctl openurl booted "rdb://pay?code=MERPAY%3Amp.cwewkCUKhUSP-MjXRCTJxg"
xcrun simctl openurl booted "https://rdb-ms.yazan-adnof.workers.dev/?code=MERPAY%3Amp.cwewkCUKhUSP-MjXRCTJxg"
```

Universal links do not open from Safari's address bar — tap them from Notes or
Messages, or a working setup will look broken.

---

## 6. Reply to send to the Trydos team

Their §4.1 asks two questions and their §5 offers to change the link:

> **Link shape** — no change needed. The form in your §2 works as sent, and so
> do all three alternatives in your §5. Keep what you have.
>
> **Custom URL scheme** — `rdb://`. It carries the same `code` value with the
> same encoding: `rdb://pay?code=MERPAY%3A<request_code>`. A bare
> `<request_code>` with no `MERPAY:` prefix is accepted too.
>
> **App Store id** — `<fill in>`.
>
> **Android package** — `com.rdb.www`, as you assumed.

The scheme and the App Store id are yours to confirm; the library side of both
is implemented and tested.

---

## 7. Please do not

* **Do not parse the code yourself** and call an API with it. Pass the whole
  `Uri` — the library enforces the rate-limit protection, the namespace check,
  and the single-resolve-endpoint rule that keep this flow safe.
* **Do not treat opening a link as proof of payment.** A link is a request to
  pay; only the payment response says money moved.
* **Do not build a payment screen from anything in the link.** It carries a code
  and nothing else — the amount and the shop name come from the server, never
  from the URL.

---

## Checklist

**App**

- [ ] `app_links` (or equivalent) added
- [ ] `getInitialLink()` passed to `TrydosWallet.handleIncomingLink`
- [ ] `uriLinkStream` piped to `TrydosWallet.handleIncomingLink`
- [ ] Unrelated links still reach your own router when it returns `false`
- [ ] Android `intent-filter` for `rdb-ms.yazan-adnof.workers.dev`, tested with `adb`
- [ ] iOS custom scheme `rdb://` registered — **blocks the iPhone button**

**To send to Trydos**

- [ ] Custom scheme: `rdb://`
- [ ] App Store id

**Backend (Cloudflare Worker)**

- [ ] `/.well-known/assetlinks.json`
- [ ] `/.well-known/apple-app-site-association`
- [ ] `adb shell pm get-app-links com.rdb.www` reports verified

---

Questions on anything above: the wallet library team.
