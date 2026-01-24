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

### 3. Get warned if you break it

```r
# Base R
users$user_id <- 1
#> Warning: Column 'user_id' is no longer unique. Removing key.

# dplyr
users |> mutate(user_id = 1)
#> Warning: Column 'user_id' is no longer unique. Removing key.
```

No silent corruption. You see the problem immediately.

## Real Example: Monthly Data Imports

```r
# Your validation function
validate_customers <- function(file) {
  read.csv(file) |>
    key(customer_id) |>           # Must be unique
    lock_no_na(email) |>          # No missing emails
    lock_nrow(min = 100)          # At least 100 rows
}

# January: clean data, works fine
jan <- validate_customers("customers_jan.csv")

# February: upstream bug introduced duplicates
feb <- validate_customers("customers_feb.csv")
#> Error: Column 'customer_id' is not unique (12 duplicates)

# You catch the problem before it corrupts your analysis
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

## Installation

```r
# install.packages("pak")
pak::pak("gcol33/keyed")
```

## Quick Reference

| Function | What it does |
|----------|--------------|
| `key(df, col)` | Declare primary key (errors if not unique) |
| `has_key(df)` | Check if data has a key |
| `get_key_cols(df)` | Get key column names |
| `lock_unique(df, col)` | Assert column is unique |
| `lock_no_na(df, col)` | Assert no missing values |
| `lock_nrow(df, min, max)` | Assert row count |
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
