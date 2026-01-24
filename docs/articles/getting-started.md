# Getting Started with keyed

## Overview

**keyed** makes key assumptions explicit in flat-file data workflows.
Define keys once, validate at creation, and let the package warn you
when assumptions break.

**Key features:**

- Define keys with
  [`key()`](https://gcol33.github.io/keyed/reference/key.md) - single or
  composite columns
- Keys survive dplyr transformations (filter, mutate, arrange, etc.)
- Assumption checks with
  [`lock_unique()`](https://gcol33.github.io/keyed/reference/lock_unique.md),
  [`lock_no_na()`](https://gcol33.github.io/keyed/reference/lock_no_na.md),
  etc.
- Join diagnostics with
  [`diagnose_join()`](https://gcol33.github.io/keyed/reference/diagnose_join.md)
- Optional row IDs for lineage tracking with
  [`add_id()`](https://gcol33.github.io/keyed/reference/add_id.md)
- Snapshot-based drift detection with
  [`commit_keyed()`](https://gcol33.github.io/keyed/reference/commit_keyed.md)
  and
  [`check_drift()`](https://gcol33.github.io/keyed/reference/check_drift.md)

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/keyed")
```

## Basic Usage

### Defining Keys

The only required action is defining a key:

``` r

library(keyed)
library(dplyr)

# Create sample data
users <- data.frame(
  user_id = 1:5,
  name = c("Alice", "Bob", "Carol", "Dave", "Eve"),
  email = c("alice@example.com", "bob@example.com", "carol@example.com",
            "dave@example.com", "eve@example.com")
)

# Define the key
users <- key(users, user_id)
users
#> # A keyed tibble: 5 x 3
#> # Key:            user_id
#>   user_id name  email            
#>     <int> <chr> <chr>            
#> 1       1 Alice alice@example.com
#> 2       2 Bob   bob@example.com  
#> 3       3 Carol carol@example.com
#> 4       4 Dave  dave@example.com 
#> 5       5 Eve   eve@example.com
```

### Keys Survive Transformations

The key persists through dplyr operations:

``` r

# Filter preserves key
active <- users |> filter(user_id <= 3)
has_key(active)
#> [1] TRUE

# Mutate preserves key
enriched <- users |> mutate(domain = sub(".*@", "", email))
get_key_cols(enriched)
#> [1] "user_id"
```

If an operation breaks uniqueness, the key degrades gracefully:

``` r

# This would create duplicates - key is dropped with warning
users |> mutate(user_id = 1)
#> Warning: Key modified and is no longer unique.
#> # A tibble: 5 × 3
#>   user_id name  email            
#>     <dbl> <chr> <chr>            
#> 1       1 Alice alice@example.com
#> 2       1 Bob   bob@example.com  
#> 3       1 Carol carol@example.com
#> 4       1 Dave  dave@example.com 
#> 5       1 Eve   eve@example.com
```

### Composite Keys

Use multiple columns as a key:

``` r

orders <- data.frame(
  customer_id = c(1, 1, 2, 2),
  order_date = c("2024-01-01", "2024-01-02", "2024-01-01", "2024-01-03"),
  amount = c(100, 150, 200, 75)
)

orders <- key(orders, customer_id, order_date)
orders
#> # A keyed tibble: 4 x 3
#> # Key:            customer_id, order_date
#>   customer_id order_date amount
#>         <dbl> <chr>       <dbl>
#> 1           1 2024-01-01    100
#> 2           1 2024-01-02    150
#> 3           2 2024-01-01    200
#> 4           2 2024-01-03     75
```

## Assumption Checks

Validate assumptions at key points in your workflow:

``` r

# Check uniqueness
lock_unique(users, user_id)

# Check for missing values
lock_no_na(users, email)

# Check row count expectations
lock_nrow(users, min = 1, max = 100)
```

## Join Diagnostics

Before joining, diagnose the cardinality:

``` r

orders <- data.frame(
  order_id = 1:6,
  user_id = c(1, 1, 2, 3, 3, 3),
  amount = c(100, 150, 200, 50, 75, 125)
)

diagnose_join(users, orders, by = "user_id")
#> 
#> ── Join Diagnosis
#> Cardinality: one-to-many
#> x: 5 rows, unique
#> y: 6 rows, 3 duplicates
```

## Row Identity Tracking

For lineage tracking, add stable UUIDs to rows:

``` r

# Add IDs
users_tracked <- users |> add_id()
users_tracked
#> # A keyed tibble: 5 x 4
#> # Key:            user_id | .id
#>   .id              user_id name  email            
#>   <chr>              <int> <chr> <chr>            
#> 1 a63e19a36d2f4e0f       1 Alice alice@example.com
#> 2 6eb5ec3eb8e1c12e       2 Bob   bob@example.com  
#> 3 e801ece25c41ffd3       3 Carol carol@example.com
#> 4 e40c0c236889ec14       4 Dave  dave@example.com 
#> 5 3807bee3a6c9bb3a       5 Eve   eve@example.com

# Check ID status
summary(users_tracked)
#> 
#> ── Keyed Data Frame Summary
#> Dimensions: 5 rows x 4 columns
#> 
#> Key columns: user_id
#> ✔ Key is unique
#> 
#> Row IDs: present (.id column)
#> ✔ 5 unique IDs, no issues
```

### Combining Data with IDs

When combining datasets, use
[`bind_id()`](https://gcol33.github.io/keyed/reference/bind_id.md) to
handle IDs properly:

``` r

# Existing data with IDs
batch1 <- add_id(data.frame(x = 1:3))

# New data without IDs
batch2 <- data.frame(x = 4:6)

# Combine - checks for overlaps and fills missing IDs
combined <- bind_id(batch1, batch2)
combined
#>                .id x
#> 1 894991fa11cb7a51 1
#> 2 90bb960bd0fba1c7 2
#> 3 d25b1c34be34400a 3
#> 4 93e9f05a7e95cba8 4
#> 5 6f1c3cb228cffb81 5
#> 6 f0da2010158942fe 6
```

### Composite IDs from Columns

Create deterministic IDs from column values:

``` r

sales <- data.frame(
  country = c("US", "UK", "US"),
  year = c(2023, 2023, 2024),
  revenue = c(1000, 800, 1200)
)

sales <- make_id(sales, country, year)
sales
#>       .id country year revenue
#> 1 US|2023      US 2023    1000
#> 2 UK|2023      UK 2023     800
#> 3 US|2024      US 2024    1200
```

## Drift Detection

Track changes over time with snapshots:

``` r

# Commit a snapshot
users <- commit_keyed(users)
#> ✔ Snapshot committed: c2930fbe...

# Later, check for drift
check_drift(users)
#> 
#> ── Drift Report
#> ✔ No drift detected
#> Snapshot: c2930fbe... (2026-01-14 10:57)

# Clean up
clear_all_snapshots()
#> ! This will remove 1 snapshot(s) from cache.
#> ✔ Cleared 1 snapshot(s).
```

## What’s Next

- See [Row
  Identity](https://gcol33.github.io/keyed/articles/row-identity.md) for
  detailed ID tracking
- See [Drift
  Detection](https://gcol33.github.io/keyed/articles/drift-detection.md)
  for snapshot workflows
- See [joinspy](https://github.com/gcol33/joinspy) for enhanced join
  diagnostics
