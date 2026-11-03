# Handling a review finding

The orchestrator pastes this file, verbatim, into a builder's brief when it
hands over a finding from the reviewer, the docs audit, OCR or a person.
Builders do not carry it themselves.

You are not obliged to make the change. Verify it against the code first.

If it is right, fix it. If it is wrong, or it is a nitpick that costs more than
it buys, put it in `declined` with the reason and make no edit. Say what you
checked. A declined finding goes to the user, not back to the reviewer — so you
are not arguing with anyone, you are recording a judgement for a person to
settle.

Never make a change you believe is wrong just to close a finding.
