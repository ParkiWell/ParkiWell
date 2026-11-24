# Motion coach feedback architecture

The motion coach gives feedback in three tiers. Each tier degrades
gracefully to the one below it, and the app is fully functional with only
the first.

## Tier 1 — deterministic, on-device, always available

All measurement and coaching runs on the phone with no network:

- MediaPipe's bundled pose model tracks 33 body landmarks per camera frame.
- The vendored `motion_engine` package counts, times, and scores every
  tracked repetition. It issues movement-specific prompts as you practise
  and produces the post-session evaluation document.
- Prompts cover movement size, pace, smoothness, matching range on both sides,
  switching sides, and returning to the starting position during a detected
  hold. The app also speaks setup changes and waits for a clear view before
  beginning the next exercise.
- The offline overview shows measured movements, per-exercise evidence,
  and which adjustments were delivered during practice.
- Every sentence shown or spoken comes from a reviewed allowlist keyed to
  machine-readable engine codes. Nothing user-facing is generated.

This tier is the source of truth. Scores, evidence chips, reason codes,
trend deltas, and cue-frequency insights all come from it.

## Tier 2 — account backup (opt-out, signed-in accounts)

Derived results only (scores, repetition counts, allowlisted sentences)
sync to the person's account through the app's offline mutation journal.
Camera frames, video, and pose landmarks are never uploaded. Controlled by
the "Back up results to my account" toggle.

## Tier 3 — cloud AI summary (opt-in, off by default)

An optional edge function (`supabase/functions/motion_summary`) asks a
Claude model to rephrase one synced session's metrics as a short,
encouraging paragraph.

The summary service enforces several limits in code.

- The service checks the signed-in account against the session owner before
  looking up metrics.
- The provider receives a fixed set of numeric scores and repetition counts,
  including up to 10 earlier scores for the same routine.
- The service checks output length and numeric tokens before showing or
  caching the summary.
- The database permits up to 20 generation attempts per account in a rolling
  24 hours, with a one-minute cooldown and up to three attempts per session.
  The session row caches the first accepted summary.
- The on-device results remain available after a failure, offline state, or
  model refusal.

Apply `supabase/schema.sql` first, deploy with
`supabase functions deploy motion_summary` with JWT verification enabled,
and set `ANTHROPIC_API_KEY` in Supabase Edge secrets.

## Why the AI tier is not on-device today

An on-device language model was evaluated and deliberately deferred:

- Usable on-device LLMs add roughly 0.5 GB to the install and need recent
  flagship hardware; this app targets older phones held by older hands.
- Platform-provided models (Apple Foundation Models on iOS 26+, Gemini
  Nano on a small set of Android devices) cover too little of the install
  base to be the only path, so the secure cloud route would still need to
  exist.
- The offline tier already provides the movement measurements and coaching
  prompts. The cloud tier provides an optional written recap.

If platform on-device models become broadly available, the summary call
site is a single function (`getMotionSessionSummary`) behind the same
opt-in toggle, so an on-device provider can replace the edge function
without touching the feedback architecture.
