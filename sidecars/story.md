# Story: keyed

## Claim
Primary keys for data frames read from flat files, checked through dplyr pipelines, with assumption checks, join previews, row identifiers and drift reports.

## Audience
R users working interactively with CSV and Excel exports in dplyr, without a database or a validation framework, who have been hit by duplicated keys after a join.

## Relation
- to: none (joinspy is an optional backend of `diagnose_join()`)
- phrase: none
- home: README, "keyed or pointblank / validate?"; Design Philosophy (non-goals)

## Arcs

### A1 The key holds through the pipeline
- question: "will I notice when a step duplicates my key?"
- answer: the key is metadata carried by dplyr methods; checked when key values or the row count change; error on duplicates
- evidence: R/dplyr-methods.R, tests
- limits: base subsetting and operations outside dplyr are not checked; `unkey()` to break the key on purpose
- home: Design Philosophy
- also: README (Usage), Quick Start

### A2 Checks at chosen points
- question: "how do I assert the other things I assume?"
- answer: `lock_*()` functions warn by default, error with `.strict = TRUE`
- home: Quick Start
- also: README

### A3 Row identity and drift
- question: "which rows did this step lose or change?"
- answer: `add_id()` / `compare_ids()`; `watch()` / `check_drift()`; `diff()` on keyed frames
- home: Quick Start
- also: README

## Non-goals
Transactions, version history, foreign keys, cascading updates, type validation (Design Philosophy).

## Documents
- DESCRIPTION: claim, A1 to A3
- README / landing: claim, first key and failing join, one section per A2 and A3, comparison table, routing
- Quick Start: tutorial, all arcs on a monthly-export example
- Design Philosophy: explanation, A1 and non-goals

## Open
- Design Philosophy says filters and mutates are not checked ("No check here"), while `mutate()` checks when key values change and joins check when the row count changes; worth aligning the article with R/dplyr-methods.R.
