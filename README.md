# keyed

[![CRAN status](https://www.r-pkg.org/badges/version/keyed)](https://CRAN.R-project.org/package=keyed)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/grand-total/keyed)](https://cran.r-project.org/package=keyed)
[![Monthly downloads](https://cranlogs.r-pkg.org/badges/keyed)](https://cran.r-project.org/package=keyed)
[![R-CMD-check](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/gcol33/keyed/graph/badge.svg)](https://app.codecov.io/gh/gcol33/keyed)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Explicit Key Assumptions for Flat-File Data**

The `keyed` package brings database-style primary key protections to R data frames. Declare which columns must be unique, and `keyed` enforces that constraint through filters, joins, and mutations — erroring immediately when assumptions break instead of failing silently downstream.

## Quick Start

```r
library(keyed)

# Declare a primary key — errors if not unique
customers <- read.csv("customers.csv") |> key(customer_id)

# Key persists through transformations
active <- customers |> dplyr::filter(status == "active")
has_key(active)
#> [1] TRUE

# Watch for automatic drift detection
customers <- customers |> watch()
modified  <- customers |> dplyr::mutate(score = score + 10)
check_drift(modified)
#> Drift detected
#> Modified: 3 row(s)
#>   score: 3 change(s)
```

## Statement of Need

In databases, you declare `customer_id` as a primary key and the engine enforces uniqueness. With CSV and Excel files, you get no such guarantees — duplicates slip in silently, joins produce unexpected row counts, and data assumptions are implicit.

Existing validation packages (pointblank, validate) offer comprehensive rule engines but require upfront schema definitions. For analysts working interactively with flat files, this overhead is often too high. The result: assumptions go unchecked, and errors surface far from their source.

`keyed` addresses this gap with four lightweight mechanisms:

| Feature | What it does |
|---------|--------------|
| **Keys** | Declare unique columns, enforced through transformations |
| **Locks** | Assert conditions (no NAs, row counts, coverage) at pipeline checkpoints |
| **UUIDs** | Track row identity through filters, joins, and reshaping |
| **Watch & Diff** | Auto-snapshot before each transformation, cell-level drift reports |

These features are designed for CSV-first workflows without database infrastructure or version control — where SQLite is overkill but silent corruption is unacceptable.

## Features

### Keys

Declare which columns must be unique. Keys persist through base R and dplyr operations, and block any transformation that would break uniqueness.

```r
# Single or composite keys
customers <- key(customers, customer_id)
sales     <- key(sales, region, year)

# Keys survive filtering
active <- customers[customers$status == "active", ]
has_key(active)
#> [1] TRUE

# Uniqueness-breaking operations are blocked
customers |> dplyr::mutate(customer_id = 1)
#> Error: Key is no longer unique after transformation.
#> i Use `unkey()` first if you intend to break uniqueness.
```

### Join Diagnostics

Preview join cardinality before executing:

```r
diagnose_join(customers, orders, by = "customer_id")
#> Cardinality: one-to-many
#> customers: 1000 rows (unique)
#> orders:    5432 rows (4432 duplicates)
#> Left join will produce ~5432 rows
```

### Locks

Assert conditions at pipeline checkpoints. Locks error immediately — no silent continuation.

```r
customers |>
  lock_unique(customer_id) |>
  lock_no_na(email) |>
  lock_nrow(min = 100)
```

Available locks:

| Function | Checks |
|----------|--------|
| `lock_unique(df, col)` | No duplicate values |
| `lock_no_na(df, col)` | No missing values |
| `lock_complete(df)` | No NAs in any column |
| `lock_coverage(df, threshold, col)` | % non-NA above threshold |
| `lock_nrow(df, min, max)` | Row count in range |

### UUIDs

Generate stable row identifiers when your data has no natural key. UUIDs survive all transformations and enable row-level tracking.

```r
customers <- add_id(customers)

# Track which rows were added or removed
filtered <- customers |> dplyr::filter(name != "Bob")
compare_ids(customers, filtered)
#> Lost: 1 row (7b1e4a9c2f8d3601)
#> Kept: 2 rows
```

### Watch & Diff

`watch()` turns drift detection from a manual ceremony into an automatic safety net. Watched data frames auto-snapshot before each dplyr verb, so `check_drift()` always gives you a cell-level report of what the last transformation changed.

```r
# Watch a keyed data frame — stamps a baseline automatically
customers <- key(df, customer_id) |> watch()

# Every dplyr verb auto-snapshots before executing
filtered <- customers |> dplyr::filter(status == "active")
check_drift(filtered)
#> Drift detected
#> Removed: 153 row(s)
#> Unchanged: 847 row(s)

# Cell-level detail through a pipe chain
result <- filtered |> dplyr::mutate(score = score + 10)
check_drift(result)
#> Drift detected
#> Modified: 847 row(s)
#>   score: 847 change(s)
```

For manual one-off comparisons, `stamp()` and `diff()` still work directly:

```r
# Manual stamp + check
customers <- customers |> stamp()
customers$score[1] <- 999
check_drift(customers)

# Cell-level diff between any two keyed data frames
diff(old_version, new_version)
#> Key: customer_id
#> Removed: 2 row(s)
#> Added: 5 row(s)
#> Modified: 3 row(s)
#>   email: 2 change(s)
#>   segment: 1 change(s)
```

Use `unwatch()` to stop automatic stamping, or `clear_all_snapshots()` to free memory.

## Installation

```r
# Install from CRAN
install.packages("keyed")

# Or install development version from GitHub
# install.packages("pak")
pak::pak("gcol33/keyed")
```

## When to Use Something Else

| Need | Better Tool |
|------|-------------|
| Enforced schema | SQLite, DuckDB |
| Full data validation | pointblank, validate |
| Production pipelines | targets |

## Documentation

- [Quick Start](https://gillescolling.com/keyed/articles/quickstart.html)
- [Design Philosophy](https://gillescolling.com/keyed/articles/philosophy.html)
- [Function Reference](https://gillescolling.com/keyed/reference/index.html)

## Support

> "Software is like sex: it's better when it's free." — Linus Torvalds

I'm a PhD student who builds R packages in my free time because I believe good tools should be free and open. I started these projects for my own work and figured others might find them useful too.

If this package saved you some time, buying me a coffee is a nice way to say thanks. It helps with my coffee addiction.

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
