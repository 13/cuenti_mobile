# Phase 2 Rearchitect — Manual Smoke Checklist

Run on an emulator or device against a live cuenti backend (v2.10.0+).
Automated gates already green: `flutter analyze` (0 warnings/errors),
`flutter test` (126 tests), `flutter build apk --debug`.

## Auth & session
- [ ] Fresh install → server setup: enter server URL, save
- [ ] Login with wrong password → "Invalid username or password" inline
- [ ] Login with correct credentials → lands on dashboard
- [ ] Kill app, reopen → session restored without login
- [ ] Logout → redirected to login; deep-link to /dashboard bounces to login

## Biometric lock
- [ ] Enable biometric unlock in settings
- [ ] Background the app, return → lock screen appears, fingerprint unlocks

## Dashboard
- [ ] Net worth / cash / portfolio tiles render with correct amounts
- [ ] Accounts list matches accounts screen balances
- [ ] Pull-to-refresh reloads

## Transactions (pagination is NEW behavior)
- [ ] List loads first 50; scrolling near bottom loads more (spinner row appears)
- [ ] Account filter dropdown narrows the list
- [ ] Create expense → appears in list, account balance drops accordingly
- [ ] Edit its amount → balance adjusts by the delta (not double-counted)
- [ ] Delete it → balance restored; delete is instant (optimistic) even on slow network
- [ ] Airplane mode: delete → row returns + error snackbar (revert works)

## Accounts
- [ ] Create/edit/delete account; reorder persists after refresh

## Catalog
- [ ] Categories: create child under parent, edit, delete
- [ ] Payees: create with default category, edit, delete
- [ ] Tags: create, delete

## Portfolio
- [ ] Currencies: create/edit/delete
- [ ] Assets: create, refresh price (spinner + updated price), delete
- [ ] Scheduled: create monthly, post it (transaction appears + balance moves), skip advances next occurrence, disable toggle holds

## Statistics
- [ ] Range picker changes reload charts (this month / last month / custom)
- [ ] Account filter works; charts match web app numbers

## Settings
- [ ] Dark mode toggle applies instantly and persists
- [ ] Color scheme change re-themes app
- [ ] Default currency + locale changes save (verify via profile reload)
- [ ] Password change: old wrong → error; correct → succeeds, re-login works
- [ ] Admin panel (admin user): user list + registration/API toggles work
- [ ] About screen shows version

## Known accepted quirks (Phase 2)
- Admin settings toggles briefly flicker (refetch instead of optimistic).
- Editing the amount of a transaction that has splits (created on web) is
  rejected with a validation message — split editing arrives in Phase 4.
- Transaction search filters only the pages loaded so far; server-side search
  lands in a later phase.
