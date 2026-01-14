# keyed

Explicit key assumptions for flat-file data workflows.

## Installation

```r
# install.packages("pak")
pak::pak("gcol33/keyed")
```

## Typical Workflow

```r
library(keyed)
library(dplyr)

# ─── 1. Load and key your data ───────────────────────────────────────────────

users <- read.csv("users.csv") |>
  key(user_id)

orders <- read.csv("orders.csv") |>
  key(order_id)

# keyed_df prints its key
users
#> keyed_df with key: user_id
#> # A tibble: 1,000 x 4
#>    user_id name       email              created_at
#>      <int> <chr>      <chr>              <date>
#>  1       1 Alice      alice@example.com  2024-01-15
#>  2       2 Bob        bob@example.com    2024-01-16
#> ...

# ─── 2. Check assumptions before operations ──────────────────────────────────

# Verify key is unique (it should be - we defined it)
assume_unique(users, user_id)

# Check for completeness before analysis
assume_no_na(users, email)

# ─── 3. Diagnose joins before running them ───────────────────────────────────

diagnose_join(users, orders, by = c("user_id" = "customer_id"))
#> ── Join Diagnosis ──
#> Cardinality: one-to-many
#> x: 1000 rows, unique
#> y: 5432 rows, 4432 duplicates

# For validated joins with cardinality enforcement, use joinspy
# joinspy::left_join_spy(), joinspy::join_strict(), etc.

# ─── 4. Key survives transformations ─────────────────────────────────────────

# filter, mutate, arrange preserve the key
active_users <- users |>
  filter(created_at > "2024-01-01") |>
  mutate(domain = sub(".*@", "", email))

has_key(active_users)
#> [1] TRUE

# Operations that break uniqueness drop the key with a warning
users |>
  mutate(user_id = 1)
#> Warning: Key modified and is no longer unique.

# ─── 5. Track drift over time (opt-in) ───────────────────────────────────────

# Commit a reference snapshot
users <- commit_keyed(users)
#> ✓ Snapshot committed: a5ab1a98...

# Later, after re-importing or transformations
users_updated <- read.csv("users.csv") |>
  key(user_id)

# Check what changed
check_drift(users_updated)
#> ── Drift Report ──
#> ⚠ Drift detected
#> Snapshot: a5ab1a98... (2024-03-15 10:30)
#> ℹ Row count: 1000 -> 1024 (+24)
#> ℹ Cell values modified

# ─── 6. Diagnostics ──────────────────────────────────────────────────────────

# Quick status check
key_status(users)
#> ── Key Status ──
#> Key: user_id
#> ✓ Key is valid and unique
#> Rows: 1000, Columns: 4

# Compare keys between datasets
compare_keys(users, users_updated)
#> ── Key Comparison ──
#> Comparing on: user_id
#>
#> x: 1000 unique keys
#> y: 1024 unique keys
#>
#> Common: 1000 (100% of x)
#> Only in x: 0
#> Only in y: 24

# Find problematic duplicates
orders_bad <- data.frame(
  order_id = c(1, 1, 2, 3, 3, 3),
  amount = c(100, 100, 200, 300, 300, 300)
)
find_duplicates(orders_bad, order_id)
#> # A tibble: 4 x 3
#>   order_id amount    .n
#>      <dbl>  <dbl> <int>
#> 1        1    100     2
#> 2        1    100     2
#> 3        3    300     3
#> 4        3    300     3
#> 5        3    300     3
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
