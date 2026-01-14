# Design Philosophy

## Who This Package Is For

keyed targets **flat-file workflows** where you typically have:

- No version control
- No database
- No schema
- Multiple drifting CSV copies

This describes most data analysis in practice: exports from systems,
shared spreadsheets, periodic dumps. The data lives in files, not tables
with enforced constraints.

## The Problem

Flat-file workflows rely on implicit assumptions:

- “This column is unique”
- “These two columns together form a key”
- “There shouldn’t be NAs here”
- “This join should be one-to-one”

These assumptions live in your head, in scattered comments, or nowhere
at all. When data changes upstream, assumptions break silently. You
discover the problem downstream—wrong row counts after a join,
duplicated records, missing values where you expected none.

## The Approach

keyed makes assumptions explicit by attaching keys to data and **warning
when those assumptions stop being true**.

The core philosophy is **detection, not enforcement**:

- Keys are defined once and validated at creation
- Violations produce warnings, not errors (by default
- Checks happen at boundaries (joins, exports, commits), not on every
  operation
- Metadata survives transformations when possible, degrades gracefully
  when not

This differs from database thinking. Databases enforce constraints
globally and reject invalid states. keyed operates in a world where:

- Data arrives pre-corrupted
- Transformations happen outside your control
- R’s copy semantics mean attributes can vanish
- Session boundaries reset everything

Rather than fighting this, keyed accepts it. The goal is catching
problems early, not preventing them absolutely.

## What keyed Is Not

keyed deliberately avoids:

- **Transactions**: No rollback, no atomic operations
- **Version history**: No branches, no diffs over time
- **Database semantics**: No foreign key enforcement, no cascading
  updates
- **Global invariants**: No system-wide state that must stay consistent
- **Required infrastructure**: No sidecar files, no databases, no
  services

These are non-goals, not missing features. Each would require
infrastructure that contradicts the flat-file context keyed targets.

## Boundary Checks

Checks run at meaningful boundaries:

| Check at | Examples |
|----|----|
| Key creation | [`key()`](https://gcol33.github.io/keyed/reference/key.md) validates uniqueness |
| Joins | [`diagnose_join()`](https://gcol33.github.io/keyed/reference/diagnose_join.md) reports cardinality |
| Snapshots | [`commit_keyed()`](https://gcol33.github.io/keyed/reference/commit_keyed.md) and [`check_drift()`](https://gcol33.github.io/keyed/reference/check_drift.md) |
| Explicit assertions | [`assume_unique()`](https://gcol33.github.io/keyed/reference/assume_unique.md), [`assume_no_na()`](https://gcol33.github.io/keyed/reference/assume_no_na.md) |

Checks do **not** run on:

- [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
  [`select()`](https://dplyr.tidyverse.org/reference/select.html),
  [`filter()`](https://dplyr.tidyverse.org/reference/filter.html)
- [`print()`](https://rdrr.io/r/base/print.html) or casual inspection
- Every row access

This keeps the package lightweight. You opt into validation where it
matters.

## Graceful Degradation

Key metadata travels with the data through dplyr operations:

``` r

library(keyed)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

df <- data.frame(id = 1:3, x = c("a", "b", "c"))
df <- key(df, id)

# Key survives filtering
df |> filter(id > 1) |> has_key()
#> [1] TRUE

# Key survives mutation
df |> mutate(y = toupper(x)) |> has_key()
#> [1] TRUE
```

But if an operation breaks uniqueness, the key is dropped with a warning
rather than an error:

``` r

# Creates duplicates - key dropped
df |> mutate(id = 1)
#> Warning: Key modified and is no longer unique.
#> # A tibble: 3 × 2
#>      id x    
#>   <dbl> <chr>
#> 1     1 a    
#> 2     1 b    
#> 3     1 c
```

This reflects reality: sometimes transformations legitimately break
keys. keyed tells you when this happens rather than blocking the
operation.

## When to Use Something Else

keyed is the wrong tool if you need:

| Need                 | Better alternative        |
|----------------------|---------------------------|
| Enforced schema      | Database (SQLite, DuckDB) |
| Version history      | Git, git2r                |
| Type safety          | vctrs, typed data frames  |
| Full data validation | pointblank, validate      |
| Production pipelines | targets, drake            |

keyed fills a specific gap: lightweight key tracking for exploratory and
semi-structured workflows where heavier tools add friction.

## Summary

keyed helps you:

1.  Define keys explicitly with
    [`key()`](https://gcol33.github.io/keyed/reference/key.md)
2.  Check assumptions with `assume_*()` functions
3.  Diagnose joins before running them
4.  Track row identity with
    [`add_id()`](https://gcol33.github.io/keyed/reference/add_id.md)
5.  Detect drift with
    [`commit_keyed()`](https://gcol33.github.io/keyed/reference/commit_keyed.md)
    and
    [`check_drift()`](https://gcol33.github.io/keyed/reference/check_drift.md)

The package warns when assumptions break. It doesn’t enforce correctness
or provide versioning. This constraint is intentional—it keeps the
package simple and appropriate for its target context.
