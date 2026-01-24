# keyed

[![CRAN status](https://www.r-pkg.org/badges/version/keyed)](https://CRAN.R-project.org/package=keyed)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/grand-total/keyed)](https://cran.r-project.org/package=keyed)
[![Monthly downloads](https://cranlogs.r-pkg.org/badges/keyed)](https://cran.r-project.org/package=keyed)
[![R-CMD-check](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/gcol33/keyed/graph/badge.svg)](https://app.codecov.io/gh/gcol33/keyed)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Primary keys for data frames.**

In databases, you declare `customer_id` as a primary key and the database enforces uniqueness. With CSV and Excel files, you get no such guarantees - duplicates slip in silently.

keyed brings database-style protections to R data frames through four features:

| Feature | What it does |
|---------|--------------|
| **Keys** | Declare unique columns, enforced through transformations |
| **Locks** | Assert conditions (no NAs, row counts, coverage) |
| **UUIDs** | Track row identity through your pipeline |
| **Commits** | Snapshot data to detect drift |

## Installation

```r
# install.packages("pak")
pak::pak("gcol33/keyed")
```

---

## 1. Keys

Declare which columns must be unique - like a primary key in a database.

```r
library(keyed)

# Declare the key (errors if not unique)
customers <- read.csv("customers.csv") |>
  key(customer_id)

# Composite keys work too
sales <- key(sales, region, year)
```

**Keys follow your data through transformations:**

```r
# Base R
active <- customers[customers$status == "active", ]
has_key(active)
#> [1] TRUE

# dplyr
active <- customers |> filter(status == "active")
has_key(active)
#> [1] TRUE
```

**Keys block operations that would break uniqueness:**

```r
customers |> mutate(customer_id = 1)
#> Error: Key is no longer unique after transformation.
#> i Use `unkey()` first if you intend to break uniqueness.

# To proceed, explicitly remove the key first
customers |> unkey() |> mutate(customer_id = 1)
```

**Preview joins before running them:**

```r
diagnose_join(customers, orders, by = "customer_id")
#> Cardinality: one-to-many
#> customers: 1000 rows (unique)
#> orders:    5432 rows (4432 duplicates)
#> Left join will produce ~5432 rows
```

---

## 2. Locks

Assert conditions at checkpoints in your pipeline.

```r
customers |>
  lock_unique(customer_id) |>    # Must be unique
  lock_no_na(email) |>           # No missing emails
  lock_nrow(min = 100)           # At least 100 rows
```

Locks error immediately if the condition fails - no silent continuation.

**Available locks:**

| Function | Checks |
|----------|--------|
| `lock_unique(df, col)` | No duplicate values |
| `lock_no_na(df, col)` | No missing values |
| `lock_complete(df)` | No NAs in any column |
| `lock_coverage(df, threshold, col)` | % non-NA above threshold |
| `lock_nrow(df, min, max)` | Row count in range |

---

## 3. UUIDs

When your data has no natural key, generate stable row identifiers.

```r
# Add a UUID to each row
customers <- add_id(customers)
#>                .id name
#> 1 a3f2c8e1b9d04567 Alice
#> 2 7b1e4a9c2f8d3601 Bob
#> 3 e9c7b2a1d4f80235 Carol
```

**UUIDs survive all transformations:**

```r
filtered <- customers |> filter(name != "Bob")
get_id(filtered)
#> [1] "a3f2c8e1b9d04567" "e9c7b2a1d4f80235"
```

**Track which rows were added or removed:**

```r
compare_ids(customers, filtered)
#> Lost: 1 row (7b1e4a9c2f8d3601)
#> Kept: 2 rows
```

UUIDs let you trace rows through joins, filters, and reshaping - essential for debugging data pipelines.

---

## 4. Commits

Snapshot your data to detect unexpected changes later.

```r
# Save a snapshot (stored in memory for this session)
customers <- customers |> commit_keyed()

# Work with your data...
customers <- customers |>
  filter(status == "active") |>
  mutate(score = score + 10)

# Check what changed since the commit
check_drift(customers)
#> Drift detected!
#> - Row count: 1000 -> 847 (-153)
#> - Column 'score' modified
```

**How it works:**
- Each data frame can have one snapshot attached
- Snapshots persist for your R session (lost on restart)
- `check_drift()` compares current state to the snapshot
- `clear_snapshot()` removes it, `list_snapshots()` shows all

Useful for catching unexpected changes during interactive analysis.

---

## When to Use Something Else

| Need | Better Tool |
|------|-------------|
| Enforced schema | SQLite, DuckDB |
| Full data validation | pointblank, validate |
| Production pipelines | targets |

keyed gives you database-style protections without database infrastructure. For exploratory workflows where SQLite is overkill but silent corruption is unacceptable.

## Documentation

- [Quick Start](https://gcol33.github.io/keyed/articles/quickstart.html)
- [Design Philosophy](https://gcol33.github.io/keyed/articles/philosophy.html)
- [Function Reference](https://gcol33.github.io/keyed/reference/index.html)

## License

MIT
