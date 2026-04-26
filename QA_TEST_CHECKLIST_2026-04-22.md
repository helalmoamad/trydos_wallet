# QA Test Checklist - 2026-04-22

1. Financial Ledger Filter by Asset
- Select a currency on Home (example: USD).
- Confirm transactions reload with asset filter (assetSymbol=USD).
- Deselect currency and confirm full unfiltered transactions return.
- Confirm pagination still works before and after filter change.

2. Shimmer on Reload and Filter Change
- Change selected currency while transactions are visible.
- Confirm transactions shimmer appears during reload.
- Confirm old list is not shown while loading.
- Confirm load-more still shows bottom loader only (not full shimmer).

3. Persist Hide Balance State
- Hide balances using eye icon on Home.
- Close and reopen app.
- Confirm hidden state is restored.
- Show balances again, reopen app, confirm shown state is restored.

4. Manual Account Input Auto Hyphen
- Open Send Transfer modal in Account input mode.
- Type 00125555 and confirm it becomes 0012-5555 automatically.
- Continue editing and confirm only one hyphen remains after first 4 digits.
- Switch to Phone input and confirm auto hyphen is not applied.

5. Realtime Wallet Events (WebSocket) - 2026-04-26
- Start app and confirm socket connects/authenticates (`Connected...` then `Authenticated by server`).
- Send `ledger:created` for a new id and confirm transaction appears at top of list.
- Send duplicate `ledger:created` with same id and confirm no duplicate row is added.
- With asset filter active (example: USD), send `ledger:created` for another asset (example: SYP) and confirm it is ignored.
- Send `ledger:completed` / `ledger:failed` / `ledger:cancelled` for an existing id and confirm only `status` updates.
- Send `ledger:completed` / `ledger:failed` / `ledger:cancelled` for a non-existing id and confirm no row is created.
- Send `balance:updated` and confirm balance card values refresh without full page reload.
- Change app language (EN/AR) and confirm realtime transaction title/metadata text follows active language with fallback.
