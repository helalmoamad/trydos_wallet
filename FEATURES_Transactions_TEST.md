# Testable Features List — Trydos Wallet

> Quick reference for the team: each point = one feature that can be tested in the app.

---

## 1. Entry & Navigation

1. **Welcome screen** — Open the app from the welcome screen and continue to Home.
2. **Splash screen** — Loading screen appears on app start.
3. **Tab navigation** — 4 tabs: Home / Transactions / Addresses / Settings.
4. **No-internet screen** — Disable the network, confirm the "No connection" screen appears, then auto-recovers when back online.
5. **Token update** — Pass a new token and confirm data reloads.
6. **Logout** — Sign out and clear session data.

---

## 2. Balances & Currencies

7. **Balance card** — Balances shown per currency on Home.
8. **Hide / show balance** — Eye icon, with the state persisted after closing and reopening the app.
9. **Currency selection** — Select a currency and confirm displayed data follows it.
10. **Wallet tab (manage balances)** — All available currencies listed.
11. **Load more currencies (pagination)** — Scroll down to load additional pages.
12. **Pull to refresh** — Refresh balances and currencies.
13. **Empty & error states** — "No currencies" message and a "Retry" button on load failure.

---

## 3. Transactions (Financial Ledger)

14. **Transaction history** — List of operations with type, amount and date.
15. **Filter by currency** — Pick a currency, list reloads filtered, then clear the filter.
16. **Transaction statuses** — Success / Failed / Pending shown with distinct colors.
17. **Load more (pagination)** — Scroll to load older transactions.
18. **Loading shimmer** — Appears only on reload or filter change, not on load-more.
19. **Transaction details** — Open an operation and view its full data.
20. **Receipt** — View, share and save the receipt.
21. **Grouping by month** — Month names shown localized per active language.

---

## 4. Send & Transfer

22. **Open Send modal** — Choose currency and amount.
23. **Send by account number** — Enter the account manually.
24. **Auto account formatting** — Typing `00125555` becomes `0012-5555` automatically.
25. **Send by phone number** — Switch to phone mode (no auto hyphen applied).
26. **Account lookup** — Recipient name appears; "Account not found" message on failure.
27. **Main / sub account** — Distinguish between them when sending.
28. **Transfer purpose** — Select from the purposes list (e.g. work partnership).
29. **Confirm & execute transfer** — Verify then send, and reach the success page.
30. **Amount & balance validation** — Error messages when exceeding balance or entering an invalid amount.
31. **Edit before confirm** — "Edit" button returns to change the details.

---

## 5. Receive & Payment Requests

32. **Receive modal** — Shows account name and number with a QR code.
33. **Copy account number** — Copy button with confirmation message.
34. **Download QR** — Saves to gallery with a "Saved successfully" message.
35. **Share QR** — Share the image via other apps.
36. **Create payment request** — Set amount, currency and purpose.
37. **Request validity** — Set an expiry duration or "Always", with a countdown timer.
38. **Request expiry** — "Expired code" shown after the time runs out.
39. **Request states** — Cancelled / Fulfilled / Inactive.
40. **Share / save payment request** — Share text plus the QR image.

---

## 6. QR Scanning

41. **Open QR scanner** — Camera starts and scans a code.
42. **Scan an account code** — Goes straight to the Send modal for that recipient.
43. **Scan a payment-request code** — Amount and purpose are prefilled automatically.
44. **Enable / disable scanner from Settings** — QR scanner toggle switch.

---

## 7. QR Login (Web)

45. **Scan a login code** — Read the web session code.
46. **Approve login** — Confirm and sign in on the web.
47. **Reject request** — Decline the login session.
48. **Incoming approval request (realtime)** — Approval dialog appears on the device when a new login is attempted.

---

## 8. Sessions & Security

49. **Active sessions** — List of registered devices.
50. **Terminate a session** — Delete a specific session.
51. **Login history** — Previous attempts with date and device.
52. **Load more history** — Pagination in login history.

---

## 9. Bank Deposit

53. **Open Deposit modal** — Choose the currency.
54. **Select source bank** — Bank list with load-more.
55. **Enter deposit amount** — Amount validation.
56. **Fees calculation** — Show fees and net amount before confirming.
57. **Submit deposit request** — "Deposit request submitted" message.
58. **Deposit requests table** — Previous requests and their statuses.

---

## 10. Identity Verification (KYC)

59. **Verification status** — "Unprotected account / limited access" shown for unverified users.
60. **Start a KYC session** — Choose a verification method.
61. **Session expiry** — "KYC session expired" message.
62. **Scan ID (front)** — Camera with guidance: low light, too close, too far, align the ID.
63. **Flip ID to back** — "Flip the card" prompt and back-side scan.
64. **Extract ID data** — Show the read information, with an error message when reading fails.
65. **Rescan** — "Rescan / Retry" button.
66. **Liveness detection** — Turn your face right/left, and align the face.
67. **Liveness result** — Success / Failed / Verifying.
68. **Face-to-ID matching** — Compare the selfie against the card photo.
69. **Mismatch** — "Discrepancy found" message and a "Re-match" button.
70. **ID success page** — Confirms the card scan succeeded.
71. **Full verification success page** — KYC completed and account marked verified.
72. **Video call request** — Start the verification call or postpone it ("Later").
73. **Camera / permission errors** — Deny camera permission and confirm the error message.

---

## 11. Profile

74. **Account information** — Name, email, phone, member since, account status.
75. **Edit name** — Update first and last name and save.
76. **Phone number page** — Shows the number with a "Verified" badge.
77. **Profile photo** — Upload / change the photo.
78. **My QR code** — Show the personal account QR.

---

## 12. General Settings

79. **Change language** — 4 languages: Arabic, English, Kurdish, Turkish.
80. **RTL / LTR direction** — UI direction flips automatically with the language.
81. **About Us** — Open the page.
82. **Share app** — Share button.

---

## 13. Realtime Updates (WebSocket)

83. **Connect & authenticate** — Confirm `Connected` then `Authenticated by server`.
84. **New transaction (`ledger:created`)** — Appears instantly at the top of the list.
85. **No duplicates** — Sending the same transaction twice does not duplicate the row.
86. **Respect active filter** — Transactions from a non-filtered currency are ignored.
87. **Status updates** — `completed` / `failed` / `cancelled` updates status only.
88. **Ignore unknown ids** — An update for a non-existing transaction creates no new row.
89. **Balance update (`balance:updated`)** — Balance card refreshes without a full page reload.
90. **Realtime event language** — Incoming transaction text follows the active language.
91. **Reconnect** — Drop the network and restore it; the socket reconnects automatically.

---

## 14. Developer Tools

92. **API logs** — View requests and responses in debug mode.
93. **API error listener** — Unified error messages appear when any request fails.

---

## Notes

- The **Addresses** tab is currently a placeholder screen — no testable functionality there yet.
- Repeat the core tests across all **4 languages** and in both **RTL and LTR**.
