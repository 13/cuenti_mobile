# Captured responses

Real responses from a real Cuenti server, kept so tests can be held to the
shapes the backend actually sends.

## Why these exist

A fixture written from a model class always agrees with that model class. It
cannot tell you the model is wrong.

The category drill-down is the case in point. It was built against
categories named by their leaf (`Miete`), shipped in v2.4.0, and stayed
broken through v2.7.0 — four releases — with eighteen passing tests over it.
This backend names a category by its **path** (`Wohnen:Miete`), so every
amount failed the join, every node came out childless, and nothing could be
drilled into. Nothing in the suite said what the server sends, so nothing
noticed.

`real_tx_envelope.json` is what found it.

## What is here

| File | Endpoint | Notes |
|---|---|---|
| `real_tx_envelope.json` | `GET /transactions` | 50 rows. `categoryName` is a path; `paymentMethod` includes `TRADE`; 20 rows are transfers with no category. |

## Capturing another

Worth doing for `/categories`, `/statistics` and `/accounts` — each is joined
against something, and each is currently only tested against invented data.

Against a server in the `test` profile:

```sh
TOKEN=$(curl -s -X POST http://localhost:8081/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"demo","password":"demo123"}' | jq -r .token)

curl -s http://localhost:8081/api/categories \
  -H "Authorization: Bearer $TOKEN" \
  | jq . > test/fixtures/real_categories.json
```

Then scrub anything identifying — real payee names, account numbers, memos —
before committing. The shapes are the point, not the contents.

## Using one

`test/helpers/real_fixture.dart` reads the envelope and derives the category
names and a matching category list from it, so a test can assert against
what the server sends rather than what a model permits:

```dart
final roots = buildCategoryBreakdown(
  {for (final name in realCategoryNames()) name: 100},
  categoriesForRealNames(),
  type: 'EXPENSE',
);
expect(roots.any((r) => r.hasChildren), isTrue);
```

A fixture that no test reads is documentation at best; wire each one into an
assertion about the join it belongs to.
