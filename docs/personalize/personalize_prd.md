# PRD — Personalized Feed (Media / Course / Learning Path)

## 1. Overview
When a learner opens the Media, Course, or Learning Path feed, we don't show the whole
catalog — we show a short, ranked list of the 12 items most worth their time. All three
feeds use the same underlying logic: first narrow the catalog down to what's actually
*appropriate* for this learner, then rank what's left by how well it fits them.

## 2. Why this matters
A catalog with thousands of items is only useful if learners can find the right thing fast.
Two risks if we get this wrong:
- **Wrong-fit content** — a primary-school learner seeing university material (or vice
  versa) erodes trust in the platform.
- **Popularity without relevance** — always showing "most popular" ignores what this
  specific learner actually needs, and never gives good-but-new content a chance.

The feed logic exists to solve both: show only what's appropriate, then rank by genuine fit.

## 3. How the feed is built

```
Request → narrow to eligible content → rank by fit → return top 12
```

### 3.1 Eligibility — what's allowed to appear at all
Before anything is ranked, content must clear two gates:

1. **Live and published.** Drafts, unpublished items, and deleted content are never shown,
   no matter how well they'd otherwise fit.
2. **Right grade level.** Every piece of content is tagged for the grade levels it suits.
   The learner's own grade determines which band of content they can see:

   | Learner is in...              | Sees content tagged for grade levels |
   |--------------------------------|----------------------------------------|
   | Primary (P1–P6)                | 1–6                                     |
   | Lower/Upper Secondary (M1–M6)  | 7–12                                    |
   | University / no school grade   | University or general audience content |

   This is a hard cutoff, not a soft preference — a university learner will never see
   primary-school content, even if it would otherwise score well.

3. **Optional narrowing by Learning Goal.** If the learner is browsing a specific goal tab
   (e.g. "Careers"), eligibility narrows further to content tagged for that goal, on top of
   the grade-level rule above. Browsing the general/trending feed skips this and uses the
   grade-level rule alone.

Whatever survives these checks is the pool of eligible content that moves on to ranking.

### 3.2 Ranking — what makes one eligible item beat another
Every eligible item gets scored on two things, combined into one number:

| Factor | Share of the score | What it captures |
|--------|---------------------|--------------------|
| **Relevance** | 45% | How closely this content matches what the learner is actually interested in |
| **Popularity (completion-based)** | 30% | How likely learners tend to *finish* this content, not just start it |
| **Recent activity (behavior)** | 18% | How closely this content resembles what the learner has recently engaged with |

The remaining share of the score is reserved for future signals (see §5) and doesn't affect
ranking today. Items are sorted by their combined score, highest first, and the top 12 are
returned. If a learner or a piece of content doesn't have enough data yet to compute any one
of these factors, that factor simply contributes nothing rather than penalizing or excluding
it — the feed still fills up using whatever signal is available, falling back to catalog order.

#### Relevance
We build a picture of each learner's interests from what they've told us:
- **Onboarding answers** — topics/goals the learner picked when they joined.
- **Career signals** — results from the career test and a personality-style interest test
  (career test carries more weight than the personality test).

If a learner has only given us one of these (say, onboarding but no career test), we use
that one fully rather than diluting it with a missing signal. Content is matched against
this interest picture — the closer the match, the higher the relevance score. A learner with
no signals at all yet gets zero relevance contribution, and the feed leans on popularity and
catalog order instead.

#### Popularity (completion-based)
This factor asks: *"of learners in this learner's peer cohort who started this, how many
actually finished it?"* It's designed as a peer signal, not a platform-wide average — the
idea is to show "learners like you tend to finish this," not "everyone tends to finish this."
- A high finish rate within the cohort signals genuinely good, engaging content — not just
  something people clicked once.
- **Cold-start rule:** if nobody in the cohort has started a piece of content yet, it gets no
  popularity boost. We don't assume new content is "average" — it earns this score once real
  learners engage with it.
- **Current limitation:** the peer-cohort mechanism is built, but the piece that groups
  learners by grade level isn't wired to real data yet. Until then, each learner's cohort is
  just themselves — so this factor currently only recognizes content the *same* learner has
  already engaged with, rather than surfacing what peers are finishing. It will start
  reflecting real peer behavior once grade-level data is fully in place — see the roadmap
  note below.

#### Recent activity (behavior)
This factor asks: *"how much does this content look like what the learner has been doing
lately?"* We look back over the learner's last 30 days of engagement and match each piece of
content they touched against the candidate:
- **What counts as engagement, and how much it weighs:** finishing a piece of content counts
  most, liking it counts next, and getting at least halfway through counts least. A recent
  action counts more than an older one — its influence fades smoothly over the 30-day window,
  so something from last week matters more than something from three weeks ago.
- **Scoped per feed:** each feed only looks at engagement with its own content type — the media
  feed reflects recent media activity, the course feed reflects recent course activity, and so
  on. Activity on one content type doesn't influence a different type's feed.
- **Cold-start rule:** a brand-new learner with no recent activity gets no behavior boost; the
  feed leans on relevance, popularity, and catalog order instead. Deleted content the learner
  once engaged with simply drops out of the calculation.

### 3.3 Worked example
A Grade 8 learner interested in Technology, who hasn't taken the career test yet, and who
recently finished a coding video:

| Content | Grade-eligible? | Relevance | Popularity | Recent activity | Result |
|---|---|---|---|---|---|
| "Intro to Coding" (Tech, M1–M3) — well-established | ✅ | High | High (this learner already finished it once) | High (matches the coding video they just finished) | Ranks 1st |
| "Intro to Coding" (Tech, M1–M3) — just published | ✅ | High | None yet (this learner hasn't started it) | High (matches the coding video they just finished) | Ranks 2nd |
| "Study Skills" (unrelated topic, M1–M3) | ✅ | Low | High (this learner finished it before) | Low (doesn't match recent coding activity) | Ranks 3rd |
| "Robotics Camp" (Tech, high-school level) | ❌ wrong grade | — | — | — | Never shown |

Robotics Camp is excluded outright by the grade rule — it's not merely ranked lower, it never
enters the running. Note how "Popularity" here reads as *this learner's own* completion
history rather than peer behavior — that's today's known limitation, not the intended
end-state (see §4–5).

## 4. Out of scope for this PRD
- Grouping popularity by grade-level peer cohort — the mechanism exists, but until grade
  level is fully queryable per learner it falls back to the learner's own activity, so it
  doesn't yet reflect real peer behavior.
- A content-diversity adjustment (avoiding a feed dominated by one category) — planned, not
  active yet; it contributes nothing to today's ranking.

## 5. Roadmap
- Wire real grade-level data into the peer cohort so popularity reflects true peer behavior
  instead of the learner's own history.
- Add a content-diversity adjustment so the feed feels less monotonic.

## 6. Glossary
- **Eligible content** — content that passed the published + grade-level (+ optional goal)
  checks and is in the running to be ranked.
- **Relevance** — how well content matches a learner's stated and inferred interests.
- **Cohort** — the group of peer learners a learner is compared against for popularity.
  Intended to be grade-level peers; currently just the learner themselves until grade-level
  data is wired in.
- **Popularity (completion-based)** — within a learner's cohort, how often learners who start
  a piece of content go on to finish it.
- **Recent activity (behavior)** — how closely a candidate resembles the content a learner has
  finished, liked, or substantially progressed through in the last 30 days, weighted by how
  recent each engagement was.
