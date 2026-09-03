## The category chart opens again

Tapping a category on the Income or Expense tab was supposed to show what
sits underneath it, and did nothing at all. The figures were right; the
chart simply had no structure left to open, because the app was matching the
amounts against the last part of a category's name (`Miete`) while the
server names them in full (`Wohnen:Miete`). Nothing matched, so every
category came back as though it had no subcategories.

Tapping now drills in, the breadcrumb walks back out, and the arrow on a
slice again means what it says. **If you have subcategories, expect the
chart to look different: what were separate slices now group under their
parent, and the parent opens.**

This has been broken since 2.4.0.

## Payment methods you can actually use

The payment method on a payee was offering five options, two of which —
"Card" and "Cheque" — are not methods this server has, while the ten it
does use were missing. That list now matches the one the transaction editor
has always used.

All of them also read as words now. Debit card payments, standing orders,
bank fees, securities trades and the rest were showing as the raw codes
underneath them — `DEBIT_CARD`, `STANDING_ORDER`, `FI_FEE`,
`TRADE` — in every language.
