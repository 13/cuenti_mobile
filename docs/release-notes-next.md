## Signing in with no connection

Opening the app without a network used to sign you out. The check that asks
the server who you are could not reach it, and that was read as the session
having expired — so the app forgot your session, threw away every figure it
had cached for exactly this situation, and put you in front of a sign-in
form that could not reach the server either. Whatever you typed was refused,
twice.

It now tells the two apart. A server that answers and refuses your session
still signs you out; a server that cannot be reached does not. You land where
you left off, on the last figures the app fetched, with the offline notice at
the top.

If you do reach the sign-in screen with no connection — after signing out, or
on a device that has been away for a while — your saved username and
fingerprint are offered as they always were, and now they work: the app signs
you in against the credentials your last sign-in left on the device. A
password the server has actually rejected is still refused, and a session
that expired stays expired. After a fortnight with no contact, the app asks
the server again.

## Transfers

Transfers have their own screen, in the navigation bar and the drawer. It is
the transaction list showing only transfers, so everything you can do to a
transaction you can still do here, and new entries made from it start as
transfers.

It works offline, and so does the type filter on the transactions list. Until
now, narrowing to transfers while offline simply failed unless you had
happened to use that exact filter online in the last fortnight, because the
app only kept the answers to questions it had already asked. It now assembles
the answer from the transactions it already holds. Scrolling for more works
the same way.

What you see offline is what reached the device, so the oldest transfers may
be missing, and the date at the top of the screen says how old the figures
are. Where the app cannot tell whether a transfer is missing or simply absent,
it says so rather than showing you an empty list.
