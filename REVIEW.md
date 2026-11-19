# Review rules

What a reviewer (the review bot or a person) should look for in a pull request here.
AGENTS.md says how to work in this repository; this file says what to check in a diff.

## Severity

Tag every finding with one of these:

- **Important**: blocks the merge. A wrong result, a crash, a security problem, a test
  that would pass on broken code, or a break of one of the checks below.
- **Nit**: worth fixing but does not block. Naming, clarity, a small missing test, docs.
- **Pre-existing**: a problem the diff did not cause but sits next to it. Label it so it
  is not mistaken for a regression. It does not block this PR.

Lead with the Important findings. If there are none, say so in one line.

## What to look for

- The materialization: a model builds a semantic view on the first run, replaces it on the
  second, and switches cleanly from and to a plain view or table.
- Parity with `Snowflake-Labs/dbt_semantic_view`: the same model body works on both
  warehouses, and differences are documented.
- Version floors: the README and CHANGELOG state the DuckDB and extension versions a
  change needs.

## Diff-triggered checks

Apply a check only when its trigger matches the diff. Each one comes from a miss that
already happened, named under "Source".

- **When the diff touches AGENTS.md, CLAUDE.md, REVIEW.md or anything under `.claude/`**
  Check: Important. List every rule the change adds, loosens or removes in the review, and
  review the rest of the diff against the base branch's copy of these files, not the PR's.
  A list in the PR description does not clear it, since the PR writes both the list and
  the rules; the review bot never clears it. It is cleared only by a maintainer who has
  read the list and approves or merges the PR.
  Source: the review bot reads the root AGENTS.md, CLAUDE.md and REVIEW.md from the PR's
  own checkout (checked 2026-11-19), so a PR can rewrite the rules it is reviewed against.
  `.claude/` is included as a precaution.
- **When the diff adds or changes a result test under `integration_tests/tests`**
  Check: it compares with a FULL OUTER JOIN and `IS DISTINCT FROM`, so an extra row or a
  NULL result fails it.
  Source: two tests LEFT JOINed and all four used `!=`, which drops NULL mismatches (fixed
  in Tier 1 of the 2026-11 review).
- **When the diff changes a macro or the materialization**
  Check: an integration model or run-operation exercises the changed path, and the double
  build in CI still passes.
  Source: MATERIALIZATIONS, hooks, drop and rename were built but never asserted until #8.
- **When the diff adds a retry, a rerun, a longer timeout or a sleep to make a flaky test
  pass**
  Check: Important. A flaky test is fixed, or deleted with the reason written down. It is
  never rerun into green. A timeout raised because a job really got slower is not this.
  Source: a maintainer rule for all s-layer repos, set 2026-10-19 after a flaky failure
  was rerun instead of fixed: never re-run CI hoping for a lucky green.
- **When the diff changes a `uses:` line under `.github/workflows/`**
  Check: `.github/workflows/actions.lock` changes in the same PR, and an action is
  referenced by a release tag, not a branch or a commit SHA. Local workflows (`uses:
  ./...`) carry no ref, and the reusable review-bot workflow
  (`anentropic/github-reviewbot/...@main`) run at a branch on purpose; none of these is a
  finding.
  Source: the GitHub Actions lockfile section in AGENTS.md; a branch ref
  (`dtolnay/rust-toolchain@stable`) broke every job's setup in arrowmodel when the branch
  was force-pushed, and Dependabot never moves a branch ref.
