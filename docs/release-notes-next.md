## Transactions you enter offline are kept, and sent later

Saving a transaction with no connection used to fail, and what you had typed
was gone. It is now kept on the device and sent when there is a connection
again — on opening the app, when the connection returns, and when you pull
to refresh.

Anything still waiting says so under the row. If the server refuses one, the
row says why, in its own words, and offers to try again or discard it.
Deleting something that was never sent simply takes it out of the queue; no
request is made for a transaction the server never had.

Two things behave differently while you are offline, both deliberately. You
cannot create a new category or payee from the transaction form, because
those need the server to issue an id. And signing out asks first if anything
is still waiting, naming how many — signing out discards them.

## Unsent transactions stay with the account that entered them

If a second account signs in on the same device — or a session expires and
somebody else signs in — anything still waiting to be sent is no longer
theirs to send. It is set aside rather than deleted, and comes back when the
account that entered it signs in again.

The same applies if you mistype your server address: the queue is set aside,
and correcting the address brings it back.

## Errors say what the server actually said

Every error in the app was replacing the server's own explanation with a
generic sentence. If the server said which field it rejected, you were told
"Invalid request" instead.

The server's own words now appear inside a translated sentence — "Invalid
request: Amount must be positive" — so the part that tells you what to fix
survives, in every language. Two long-standing side effects of the same bug
are fixed with it: a server with the API switched off now says so, rather
than claiming you are not signed in; and a server error names its status
instead of reporting "Unexpected response from server" every time.

This has been broken since the app first talked to a server.

## Smaller things

Italian called a transaction *operazione* in a few places and *movimento*
everywhere else; it is *movimento* throughout now. Counts of one no longer
read "1 transactions". A refusal the server did not explain reads "Refused"
rather than "Refused:" with nothing after it, and a very long one no longer
stretches a row down the screen.
