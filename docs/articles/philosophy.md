# Design Philosophy

## The Flat-File Reality

Most data analysis doesn’t happen in databases. It happens with: - CSV
exports from business systems

- Excel files from collaborators

- Periodic data dumps with no schema

- Multiple versions of “the same” file

In this world, there’s no enforced uniqueness constraint, no foreign key
validation, no schema migration. The constraints exist only in your
head—or in scattered comments that nobody reads.

``` r

# customer_id should be unique... I think?
# email shouldn't have NAs... right?
customers <- read.csv("customers_march_v3_FINAL.csv")
```

When assumptions break, you discover it downstream: wrong row counts
after a join, duplicated records in a report, a model that suddenly
performs differently. By then, the damage is done.

## Detection, Not Enforcement

keyed takes a pragmatic approach: **detect problems early, don’t try to
prevent them absolutely**.

This differs from database thinking:

| Database Approach               | keyed Approach                        |
|---------------------------------|---------------------------------------|
| Reject invalid data             | Accept data, warn about violations    |
| Enforce constraints globally    | Check at explicit boundaries          |
| Transactions ensure consistency | No transactions, graceful degradation |
| Schema prevents corruption      | Catches corruption after the fact     |

Why not enforce constraints? Because in flat-file workflows:

1.  **Data arrives pre-corrupted** — You can’t reject an export you
    already received

2.  **Transformations happen outside your control** — Upstream systems
    change without notice

3.  **R’s copy semantics lose attributes** — Metadata can vanish
    unexpectedly

4.  **Session boundaries reset state** — No persistent enforcement
    possible

Rather than fighting this reality, keyed accepts it. The goal is
catching problems when you can still fix them—at import, before joins,
during validation—not preventing problems that are already inevitable.

## Boundary Checks

Checks run at meaningful moments, not continuously:

``` r

df <- data.frame(id = 1:3, value = c("a", "b", "c"))

# Check happens HERE - at key definition
df <- key(df, id)

# No check here - just a filter
df_filtered <- df |> filter(id > 1)

# No check here - just adding a column
df_enriched <- df |> mutate(upper = toupper(value))

# Check happens HERE - at explicit assertion
df |> lock_no_na(value)
```

This keeps the package lightweight. You opt into validation where it
matters:

| Boundary | Example |
|----|----|
| Key definition | [`key()`](https://gillescolling.com/keyed/reference/key.md) validates uniqueness |
| Explicit assertions | [`lock_unique()`](https://gillescolling.com/keyed/reference/lock_unique.md), [`lock_no_na()`](https://gillescolling.com/keyed/reference/lock_no_na.md) |
| Before joins | [`diagnose_join()`](https://gillescolling.com/keyed/reference/diagnose_join.md) |
| Drift checks | [`stamp()`](https://gillescolling.com/keyed/reference/stamp.md) → [`check_drift()`](https://gillescolling.com/keyed/reference/check_drift.md) |

## Strict Enforcement

When operations break key assumptions, keyed errors and requires
explicit acknowledgment:

``` r

df <- data.frame(id = 1:3, x = c("a", "b", "c")) |>
  key(id)

# This would create duplicate ids - keyed stops you
df |> mutate(id = 1)
#> Error in `mutate()`:
#> ! Key is no longer unique after transformation.
#> ℹ Use `unkey()` first if you intend to break uniqueness.
```

To proceed, use
[`unkey()`](https://gillescolling.com/keyed/reference/unkey.md) to
explicitly acknowledge you’re breaking the key:

``` r

df |> unkey() |> mutate(id = 1)
#> # A tibble: 3 × 2
#>      id x    
#>   <dbl> <chr>
#> 1     1 a    
#> 2     1 b    
#> 3     1 c
```

Why error instead of warn?

1.  **Silent key removal is dangerous** — You might not notice the
    warning

2.  **Explicit is better than implicit** — If you want to break the key,
    say so

3.  **Catches mistakes early** — Before they corrupt downstream analysis

## What keyed Doesn’t Do

These are deliberate non-goals:

| Feature | Why Not |
|----|----|
| Transactions | Requires infrastructure flat-file workflows don’t have |
| Version history | Use Git for that |
| Foreign key enforcement | Can’t enforce across independent files |
| Cascading updates | No persistent state between sessions |
| Type validation | Use vctrs or typed data frames |

Each would require infrastructure that contradicts the flat-file
context. keyed stays minimal by design.

## Summary

keyed helps you:

1.  **Define keys explicitly** — `key(df, col1, col2)`

2.  **Check assumptions at boundaries** —
    [`lock_unique()`](https://gillescolling.com/keyed/reference/lock_unique.md),
    [`lock_no_na()`](https://gillescolling.com/keyed/reference/lock_no_na.md)

3.  **Diagnose joins before problems occur** —
    [`diagnose_join()`](https://gillescolling.com/keyed/reference/diagnose_join.md)

4.  **Track row identity** —
    [`add_id()`](https://gillescolling.com/keyed/reference/add_id.md),
    [`compare_ids()`](https://gillescolling.com/keyed/reference/compare_ids.md)

5.  **Detect drift between versions** —
    [`stamp()`](https://gillescolling.com/keyed/reference/stamp.md),
    [`check_drift()`](https://gillescolling.com/keyed/reference/check_drift.md)

The package warns when assumptions break. It doesn’t enforce correctness
absolutely. This constraint is intentional—it keeps keyed appropriate
for the messy, schema-free world where most data analysis actually
happens.
