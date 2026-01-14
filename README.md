# keyed
[![R-CMD-check](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Explicit Key Assumptions for Flat-File Data Workflows**

The `keyed` package helps you define and maintain key assumptions in data workflows where you work with CSVs, Excel files, and other flat files without database schemas. Define keys once, validate at creation, and get warnings when assumptions break.

## Quick Start

```r
library(keyed)
library(dplyr)

# Define a key - the only required action
users <- read.csv("users.csv") |>
  key(user_id)

# Keys survive transformations
active_users <- users |>
  filter(status == "active") |>
  mutate(domain = sub(".*@", "", email))

has_key(active_users)
#> [1] TRUE

# Check assumptions
assume_unique(users, user_id)
assume_no_na(users, email)

# Diagnose joins before running them
diagnose_join(users, orders, by = "user_id")
#> ── Join Diagnosis ──
#> Cardinality: one-to-many
#> x: 1000 rows, unique
#> y: 5432 rows, 4432 duplicates
```

## Statement of Need

Working with flat files (CSVs, Excel exports) often means implicit assumptions about data structure: "this column should be unique", "these columns form a composite key", "there shouldn't be NAs here". These assumptions live in your head or scattered comments, breaking silently when data changes.

`keyed` addresses this by providing:

- **Explicit key definitions** that travel with the data through transformations
- **Graceful degradation** - warnings when keys break, not hard failures
- **Assumption checks** at boundaries (imports, exports, joins) rather than every operation
- **Optional lineage tracking** with stable row IDs
- **Drift detection** to catch changes between data versions

## Installation

```r
# install.packages("pak")
pak::pak("gcol33/keyed")
```

## Features

### Key Definition

```r
# Single key
users <- key(data, user_id)

# Composite key
orders <- key(data, customer_id, order_date)

# Check key status
has_key(users)
get_key_cols(users)
key_is_valid(users)
```

### Assumption Checks

```r
# Uniqueness
assume_unique(data, col1, col2)

# Missing values
assume_no_na(data, required_col)

# Completeness (all expected values present)
assume_complete(data, category, expected = c("A", "B", "C"))

# Coverage (reference values covered)
assume_coverage(data, id, reference = ref_data$id)

# Row count
assume_nrow(data, min = 100, max = 10000)
```

### Join Diagnostics

```r
# Analyze join before executing
diagnose_join(users, orders, by = "user_id")
#> ── Join Diagnosis ──
#> Cardinality: one-to-many
#> x: 1000 rows, unique
#> y: 5432 rows, 4432 duplicates

# For validated joins, use joinspy
# pak::pak("gcol33/joinspy")
```

### Row Identity Tracking

Opt-in stable UUIDs for lineage tracking:

```r
# Add IDs to rows
users <- add_id(users)

# IDs persist through transformations
filtered <- users |> filter(active)
get_id(filtered)  # Same IDs as original rows

# Combine data with ID handling
combined <- bind_id(batch1, batch2)  # Checks overlaps, fills missing

# Create deterministic IDs from columns
sales <- make_id(data, country, year)  # "US|2024"

# Validate ID integrity
check_id(data)
check_id_disjoint(data1, data2)

# Compare before/after
compare_ids(before, after)
#> $lost: 2 IDs
#> $gained: 5 IDs
#> $preserved: 998 IDs
```

### Drift Detection

```r
# Commit a reference snapshot
users <- commit_keyed(users)
#> ✓ Snapshot committed: a5ab1a98...

# Later, check for changes
check_drift(users)
#> ── Drift Report ──
#> ⚠ Drift detected
#> ℹ Row count: 1000 -> 1024 (+24)
#> ℹ Cell values modified
```

### Diagnostics

```r
# Quick status check
key_status(users)
summary(users)

# Compare keys between datasets
compare_keys(old_data, new_data)

# Find duplicates
find_duplicates(data, key_col)
```

## Philosophy

- **Keys are explicit**: Define once, validate at creation
- **Warnings over errors**: Alert on violations, don't block by default
- **Graceful degradation**: Key metadata survives transformations when possible, drops cleanly when not
- **Boundary checks**: Validate at joins and exports, not on every operation
- **No magic**: No hidden state, no sidecar files, no databases

## Enhanced Diagnostics

Install [joinspy](https://github.com/gcol33/joinspy) for richer join diagnostics:

```r
pak::pak("gcol33/joinspy")

# diagnose_join() automatically uses joinspy when available
diagnose_join(users, orders, by = "user_id")
#> ── Pre-Join Diagnostic Report ──
#> ... detailed whitespace, encoding, and match analysis ...
```

## Documentation

- [Getting Started](https://gcol33.github.io/keyed/articles/getting-started.html)
- [Function Reference](https://gcol33.github.io/keyed/reference/index.html)

## Support

If this package saved you some time, buying me a coffee is a nice way to say thanks.

[![Buy Me A Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/gcol33)

## License

MIT (see the LICENSE.md file)
