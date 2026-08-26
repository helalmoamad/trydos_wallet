# trydos_wallet_example

تطبيق تجريبي لمكتبة `trydos_wallet`.

## التشغيل

بيانات الاعتماد تأتي من بيئة البناء، وليست مكتوبة في المصدر. انسخ القالب:

```bash
cp .env.json.example .env.json
```

ضع فيه توكن حيّاً، ثم:

```bash
flutter run --dart-define-from-file=.env.json
```

`.env.json` مستثنى في `.gitignore` فلا يُرفع.

بدلاً من الملف يمكن تمريرها مباشرة:

```bash
flutter run \
  --dart-define=WALLET_TOKEN=<jwt> \
  --dart-define=WALLET_REFRESH_TOKEN=<jwt>
```

بدون `WALLET_TOKEN` يبدأ التطبيق بحالة غير مسجّل الدخول — مفيد لتجربة شاشات
تسجيل الدخول.

| المتغيّر | الافتراضي |
|---|---|
| `WALLET_TOKEN` | *(فارغ — غير مسجّل الدخول)* |
| `WALLET_REFRESH_TOKEN` | *(فارغ)* |
| `WALLET_BASE_URL` | `https://trydos_wallet_develop.ramaaz.dev/` |
| `WALLET_KYC_BASE_URL` | `https://api.ramaaz-digital-bank.online/` |

## فحص أمني

```bash
semgrep --config ../.semgrep/trydos-wallet.yaml ../lib lib android
```
