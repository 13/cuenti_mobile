## Tapping the category chart works properly

Tapping a slice of the statistics pie chart now drills into that category's
subcategories when you lift your finger, which is what it should always
have done.

Before, it reacted the instant your finger touched the chart — so scrolling
the statistics page with a finger that happened to land on the chart jumped
you into whichever category was under it, and a deliberate tap was handled
twice.

Tapping a category with nothing beneath it, or the hole in the middle,
does nothing, as expected.

## Categories match more reliably

The figures and the category list come from two different parts of the
server, which do not have to agree on capitalisation or stray spaces. Where
they disagreed, no category matched: every slice became a top-level entry
with nothing to drill into, which looks exactly like a chart that ignores
you. They are now matched regardless of case or padding.

Two genuinely different categories whose names differ only in case are
still kept apart rather than quietly merged.
