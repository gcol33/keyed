# keyed

*the spreadsheet swears it's unique*

[![CRAN status](https://www.r-pkg.org/badges/version/keyed)](https://CRAN.R-project.org/package=keyed)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/grand-total/keyed)](https://cran.r-project.org/package=keyed)
[![Monthly downloads](https://cranlogs.r-pkg.org/badges/keyed)](https://cran.r-project.org/package=keyed)
[![R-CMD-check](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/gcol33/keyed/graph/badge.svg)](https://app.codecov.io/gh/gcol33/keyed)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Primary-key constraints for flat-file data frames, enforced through dplyr.**

Tell it which columns are unique. `keyed` validates the constraint with
`vctrs` and re-checks it after every `filter`, `mutate`, `join`, and `bind`,
erroring the moment a transformation makes the key non-unique. A database
enforces this for you; a CSV does not, so duplicates slip in and surface three
joins later as a wrong row count.

```r
library(keyed)

orders <- key(orders, order_id)

# the key is re-validated after each verb
orders |> dplyr::filter(qty > 1) |> has_key()
#> [1] TRUE

# a transformation that breaks uniqueness stops here, not downstream
orders |> dplyr::mutate(order_id = 1)
#> Error: Key is no longer unique after transformation.
#> i Use `unkey()` first if you intend to break uniqueness.
```

## Error at the source, not three joins later

A duplicate `customer_id` in a CSV is silent in base R and dplyr: the join
runs, the row count quietly inflates, and the bug shows up far from where the
assumption broke. `keyed` attaches the key as data-frame metadata and carries
it through every dplyr verb, so the same constraint a database would enforce
fails immediately, with the verb that violated it named in the error.

```r
customers <- key(customers, customer_id)   # validated unique at declaration

active <- customers[customers$status == "active", ]
has_key(active)                            # key survives base subsetting
#> [1] TRUE
```

## Preview a join before it inflates rows

`diagnose_join()` reports cardinality before the join executes, so a
one-to-many you didn't expect is visible up front:

```r
diagnose_join(customers, orders, by = "customer_id")
#> Cardinality: one-to-many
#> customers: 1000 rows (unique)
#> orders:    5432 rows (4432 duplicates)
#> Left join will produce ~5432 rows
```

## Assert conditions at checkpoints

Locks check a condition and error if it fails, so a pipeline stops at the
checkpoint instead of carrying a broken assumption forward:

```r
customers |>
  lock_unique(customer_id) |>
  lock_no_na(email) |>
  lock_nrow(min = 100)
```

| Function | Checks |
|----------|--------|
| `lock_unique(df, col)` | No duplicate values |
| `lock_no_na(df, col)` | No missing values |
| `lock_complete(df)` | No NAs in any column |
| `lock_coverage(df, threshold, col)` | % non-NA above threshold |
| `lock_nrow(df, min, max)` | Row count in range |

## Track rows that have no natural key

`add_id()` stamps a stable identifier on each row. It survives filters, joins,
and reshaping, so you can name exactly which rows a transformation dropped:

```r
customers <- add_id(customers)

filtered <- customers |> dplyr::filter(name != "Bob")
compare_ids(customers, filtered)
#> Lost: 1 row (7b1e4a9c2f8d3601)
#> Kept: 2 rows
```

## See what the last transformation changed

`watch()` marks a keyed data frame so every dplyr verb snapshots it first.
Snapshots are content-addressed (xxhash64 via `digest`) in a bounded
in-session cache, and because the key aligns rows between two states,
`check_drift()` reports changes down to the individual cell:

```r
df <- key(data.frame(id = 1:5, x = c(1, 2, 3, 4, 5)), id) |> watch()

filtered <- df |> dplyr::filter(id <= 3)
check_drift(filtered)
#> Drift detected
#> Removed: 2 row(s)
#> Unchanged: 3 row(s)

result <- filtered |> dplyr::mutate(x = x * 100)
check_drift(result)
#> Drift detected
#> Modified: 3 row(s)
#>   x: 3 change(s)
```

Compare any two keyed frames directly with `diff()`, which aligns rows by the
key and reports added, removed, and modified rows with per-column detail:

```r
old <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
new <- data.frame(id = 2:4, x = c("B", "c", "d"))

diff(old, new)
#> Key: id
#> Removed: 1 row(s)
#> Added: 1 row(s)
#> Modified: 1 row(s)
#>   x: 1 change(s)
#> Unchanged: 1 row(s)
```

Use `unwatch()` to stop auto-snapshotting, or `clear_all_snapshots()` to free
the cache.

## keyed or pointblank / validate?

| | `keyed` | pointblank, validate |
|---|---|---|
| Setup | None; declare a key inline | Upfront schema or rule set |
| Enforces through dplyr? | Yes, after every verb | No |
| Scope | Keys, locks, row IDs, drift | Full validation rule engines |
| Best for | Interactive CSV/Excel work | Batch validation, reporting |

For an enforced schema use SQLite or DuckDB; for full validation reports use
pointblank or validate. `keyed` covers the gap in between, where you are
working interactively with a flat file and want one assumption held without
standing up infrastructure.

## Installation

```r
install.packages("keyed")            # CRAN

install.packages("pak")              # development version
pak::pak("gcol33/keyed")
```

## Documentation

- [Quick Start](https://gillescolling.com/keyed/articles/quickstart.html)
- [Design Philosophy](https://gillescolling.com/keyed/articles/philosophy.html)
- [Function Reference](https://gillescolling.com/keyed/reference/index.html)

## Support

> "Software is like sex: it's better when it's free." — Linus Torvalds

I'm a PhD student who builds R packages in my free time because I believe good tools
should be free and open. I started these projects for my own work and figured others
might find them useful too.

If this package saved you some time, buying me a coffee is a nice way to say thanks.
It helps with my coffee addiction.

[![Buy Me A Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/gcol33)

## License

MIT (see the LICENSE.md file)

## Citation

```bibtex
@software{keyed,
  author = {Colling, Gilles},
  title = {keyed: Explicit Key Assumptions for Flat-File Data},
  year = {2025},
  url = {https://CRAN.R-project.org/package=keyed},
  doi = {10.32614/CRAN.package.keyed}
}
```
