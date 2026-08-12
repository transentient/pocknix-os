# Release docs audit — for Cliff's rewrite pass (2026-08-12)

Working notes for the README.md / INSTALL.md rewrite. Two categories:
**substance** (facts that changed today — must fix regardless of voice) and
**voice** (flagged for your translation pass; keep or cut as you see fit).
Delete this file before release.

## Substance — outdated as of today's work

1. **INSTALL.md "Known limitations", last bullet** — "Suspending while a game is
   running may disconnect the controller in-game" — **now false.** Seamless
   suspend-mid-game works (InputPlumber 0.77.2 + deck-uhid). This is arguably the
   headline feature: no other Odin 3 distro has it. Consider promoting to the
   README "What works" table instead ("Sleep anytime — even mid-game").
2. **README "What works" suspend row** — can now say sleep works from anywhere,
   including inside a running game.
3. **README "Honest limitations"** — headphone jack line may be obsolete after
   today's UCM fix (duplicate Headphones section shadowed the correct PCM).
   Update after the on-device test.
4. **Fan curves** — Quick Access selector now includes a Max (always-100%) option;
   worth a word wherever fan curves are mentioned.
5. **INSTALL.md troubleshooting, "game froze and buttons dead" bullet** — the
   suspend/resume workaround text predates today's stack; re-verify the overlay
   jam still reproduces on the new InputPlumber/client before shipping the claim.
6. **[VERIFY] markers still open**: A.1 ROCKNIX ABL release URL + file list;
   A.2 exact Android menu names; D.2 exact non-SSH path to a terminal;
   D.4 boot order with SD still inserted. (Resolve during the SD dry-run.)

## Voice — flagged for the Siri Keaton pass

- README: "receipts in the commit log" (header) — insider framing.
- README: "and yes it glows" (RGB row) — charming but chatty for a spec table.
- README: "the glue to make them love a Qualcomm handheld" — metaphor-dense.
- README: "Honest limitations" / INSTALL "honesty section" — the framing implies
  other sections are less honest; consider plain "Limitations" / "Known issues".
- README: "inherited proudly" (license) — tone.
- INSTALL: "If words like 'partition' frighten you, bring a friend they don't" —
  funny, but decide if the register fits.
- INSTALL: "Treat them like your passport" (ABL backup) — actually good, concrete;
  suggest keeping.
- INSTALL: "the Steam Deck way: no passwords exist... nothing to attack until you
  opt in" — fine, but a security claim; phrase carefully.
- General: several ⚠️/CAPS emphasis runs close together in Part A — consider
  letting one carry the weight.

## Structure suggestions (take or leave)

- INSTALL Part A is the scariest part and rightly detailed; a one-line "what you
  will have at the end" preview at the top of A would orient first-timers.
- Troubleshooting is good and specific — consider ordering by likelihood
  (SD-card invisibility first is correct).
