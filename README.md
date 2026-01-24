# keyed
[![R-CMD-check](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/gcol33/keyed/graph/badge.svg)](https://app.codecov.io/gh/gcol33/keyed)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Primary keys for data frames.**

In databases, you declare `customer_id` as a primary key and the database enforces uniqueness. With CSV and Excel files, you get no such guarantees - duplicates slip in silently.

keyed brings primary key behavior to R data frames:

```r
library(keyed)

# Declare customer_id as the primary key (must be unique)
customers <- read.csv("customers.csv") |>
  key(customer_id)
```

If `customer_id` has duplicates, you get an error immediately - not after your analysis is corrupted.

## How It Works

### 1. Define a key (like a primary key)

```r
# Single column key
users <- key(users, user_id)

# Composite key (combination must be unique)
sales <- key(sales, region, date)
```

### 2. The key follows your data

```r
# Base R - key survives subsetting
active_users <- users[users$status == "active", ]
has_key(active_users)
#> [1] TRUE

# dplyr - key survives filter, mutate, arrange, etc.
active_users <- users |> filter(status == "active")
has_key(active_users)
#> [1] TRUE
```

### 3. Get stopped if you break it

```r
# Base R
users$user_id <- 1
#> Error: Key is no longer unique after transformation.
#> i Use `unkey()` first if you intend to break uniqueness.

# dplyr
users |> mutate(user_id = 1)
#> Error: Key is no longer unique after transformation.
#> i Use `unkey()` first if you intend to break uniqueness.
```

No silent corruption. You must explicitly acknowledge breaking the key with `unkey()`.

## Real Example: Monthly Data Imports

```r
# Base R
validate_customers <- function(file) {
  df <- read.csv(file)
  df <- key(df, customer_id)
  lock_no_na(df, email)
  lock_nrow(df, min = 100)
  df
}

# dplyr
validate_customers <- function(file) {
  read.csv(file) |>
    key(customer_id) |>
    lock_no_na(email) |>
    lock_nrow(min = 100)
}

# January: clean data, works fine
jan <- validate_customers("customers_jan.csv")

# February: upstream bug introduced duplicates
feb <- validate_customers("customers_feb.csv")
#> Error: Column 'customer_id' is not unique (12 duplicates)
```

## Join Diagnostics

Before joining, understand what will happen:

```r
diagnose_join(customers, orders, by = "customer_id")
#> ── Join Diagnosis
#> Cardinality: one-to-many
#> customers: 1000 rows (unique on customer_id)
#> orders:    5432 rows (4432 duplicates on customer_id)
#>
#> Left join will produce ~5432 rows
```

No more surprise row explosions.

## Row UUIDs

Your data has no natural key? Generate one:

```r
# Add a UUID to each row
customers <- add_id(customers)
customers
#>                .id name
#> 1 a3f2c8e1b9d04567 Alice
#> 2 7b1e4a9c2f8d3601 Bob
#> 3 e9c7b2a1d4f80235 Carol

# UUIDs survive all transformations
filtered <- customers[customers$name != "Bob", ]
get_id(filtered)
#> [1] "a3f2c8e1b9d04567" "e9c7b2a1d4f80235"

# Track what changed between versions
compare_ids(customers, filtered)
#> Lost: 1 row (7b1e4a9c2f8d3601)
#> Kept: 2 rows
```

UUIDs let you trace rows through your entire pipeline - even after joins, filters, and reshaping.

## Installation

```r
# install.packages("pak")
pak::pak("gcol33/keyed")
```

## Quick Reference

| Function | What it does |
|----------|--------------|
| `key(df, col)` | Declare primary key (errors if not unique) |
| `unkey(df)` | Remove key (required before breaking uniqueness) |
| `has_key(df)` | Check if data has a key |
| `add_id(df)` | Add UUID to each row |
| `compare_ids(old, new)` | See which rows were added/removed |
| `lock_unique(df, col)` | Assert column is unique |
| `lock_no_na(df, col)` | Assert no missing values |
| `diagnose_join(x, y)` | Preview join cardinality |

## When to Use Something Else

| Need | Better Tool |
|------|-------------|
| Enforced schema | SQLite, DuckDB |
| Full data validation | pointblank, validate |
| Production pipelines | targets |

keyed gives you the primary key validation of a database without needing actual database infrastructure. For exploratory workflows where SQLite is overkill but silent corruption is unacceptable.

## Documentation

- [Quick Start](https://gcol33.github.io/keyed/articles/quickstart.html)
- [Design Philosophy](https://gcol33.github.io/keyed/articles/philosophy.html)
- [Function Reference](https://gcol33.github.io/keyed/reference/index.html)

## License

MIT
