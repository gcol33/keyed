# Quick Start

## The Problem: Silent Data Corruption

You receive monthly customer exports from a CRM system. The data should
have unique `customer_id` values and complete `email` addresses. One
month, someone upstream changes the export logic. Now `customer_id` has
duplicates and some emails are missing.

**Without explicit checks, you won’t notice until something breaks
downstream**—wrong row counts after a join, duplicated invoices, failed
email campaigns.

``` r

# January export: clean data
january <- data.frame(
  customer_id = c(101, 102, 103, 104, 105),
  email = c("alice@example.com", "bob@example.com", "carol@example.com",
            "dave@example.com", "eve@example.com"),
  segment = c("premium", "basic", "premium", "basic", "premium")
)

# February export: corrupted upstream (duplicates + missing email)
february <- data.frame(
  customer_id = c(101, 102, 102, 104, 105),  # Note: 102 is duplicated

  email = c("alice@example.com", "bob@example.com", NA,
            "dave@example.com", "eve@example.com"),
  segment = c("premium", "basic", "basic", "basic", "premium")
)
```

The February data looks fine at a glance:

``` r

head(february)
#>   customer_id             email segment
#> 1         101 alice@example.com premium
#> 2         102   bob@example.com   basic
#> 3         102              <NA>   basic
#> 4         104  dave@example.com   basic
#> 5         105   eve@example.com premium
nrow(february)  # Same row count
#> [1] 5
```

But it will silently corrupt your analysis.

------------------------------------------------------------------------

## The Solution: Make Assumptions Explicit

**keyed** catches these issues by making your assumptions explicit:

``` r

# Define what you expect: customer_id is unique
january_keyed <- january |>
  key(customer_id) |>
  lock_no_na(email)

# This works - January data is clean
january_keyed
#> # A keyed tibble: 5 x 3
#> # Key:            customer_id
#>   customer_id email             segment
#>         <dbl> <chr>             <chr>  
#> 1         101 alice@example.com premium
#> 2         102 bob@example.com   basic  
#> 3         103 carol@example.com premium
#> 4         104 dave@example.com  basic  
#> 5         105 eve@example.com   premium
```

Now try the same with February’s corrupted data:

``` r

# This fails immediately - duplicates detected
february |>
  key(customer_id)
#> Warning: Key is not unique.
#> ℹ 1 duplicate key value(s) found.
#> ℹ Key columns: customer_id
#> # A keyed tibble: 5 x 3
#> # Key:            customer_id
#>   customer_id email             segment
#>         <dbl> <chr>             <chr>  
#> 1         101 alice@example.com premium
#> 2         102 bob@example.com   basic  
#> 3         102 NA                basic  
#> 4         104 dave@example.com  basic  
#> 5         105 eve@example.com   premium
```

The error catches the problem **at import time**, not downstream when
you’re debugging a mysterious row count mismatch.

------------------------------------------------------------------------

## Workflow 1: Monthly Data Validation

**Goal**: Validate each month’s export against expected constraints
before processing.

**Challenge**: Data quality varies month-to-month. Silent corruption
causes cascading errors.

**Strategy**: Define keys and assumptions once, apply consistently to
each import.

### Define validation function

``` r

validate_customer_export <- function(df) {
  df |>
    key(customer_id) |>
    lock_no_na(email) |>
    lock_nrow(min = 1)
}

# January: passes
january_clean <- validate_customer_export(january)
summary(january_clean)
#> 
#> ── Keyed Data Frame Summary
#> Dimensions: 5 rows x 3 columns
#> 
#> Key columns: customer_id
#> ✔ Key is unique
#> 
#> Row IDs: none
```

### Keys survive transformations

Once defined, keys persist through dplyr operations:

``` r

# Filter preserves key
premium_customers <- january_clean |>
  filter(segment == "premium")

has_key(premium_customers)
#> [1] TRUE
get_key_cols(premium_customers)
#> [1] "customer_id"

# Mutate preserves key
enriched <- january_clean |>
  mutate(domain = sub(".*@", "", email))

has_key(enriched)
#> [1] TRUE
```

### Strict enforcement

If an operation breaks uniqueness, keyed errors and tells you to use
[`unkey()`](https://gillescolling.com/keyed/reference/unkey.md) first:

``` r

# This creates duplicates - keyed stops you
january_clean |>
  mutate(customer_id = 1)
#> Error in `mutate()`:
#> ! Key is no longer unique after transformation.
#> ℹ Use `unkey()` first if you intend to break uniqueness.
```

To proceed, you must explicitly acknowledge breaking the key:

``` r

january_clean |>
  unkey() |>
  mutate(customer_id = 1)
#> # A tibble: 5 × 3
#>   customer_id email             segment
#>         <dbl> <chr>             <chr>  
#> 1           1 alice@example.com premium
#> 2           1 bob@example.com   basic  
#> 3           1 carol@example.com premium
#> 4           1 dave@example.com  basic  
#> 5           1 eve@example.com   premium
```

------------------------------------------------------------------------

## Workflow 2: Safe Joins

**Goal**: Join customer data with orders without accidentally
duplicating rows.

**Challenge**: Join cardinality mistakes are common and hard to debug. A
“one-to-one” join that’s actually one-to-many silently inflates your
data.

**Strategy**: Use
[`diagnose_join()`](https://gillescolling.com/keyed/reference/diagnose_join.md)
to understand cardinality *before* joining.

### Create sample data

``` r

customers <- data.frame(
  customer_id = 1:5,
  name = c("Alice", "Bob", "Carol", "Dave", "Eve"),
  tier = c("gold", "silver", "gold", "bronze", "silver")
) |>
  key(customer_id)

orders <- data.frame(
  order_id = 1:8,
  customer_id = c(1, 1, 2, 3, 3, 3, 4, 5),
  amount = c(100, 150, 200, 50, 75, 125, 300, 80)
) |>
  key(order_id)
```

### Diagnose before joining

``` r

diagnose_join(customers, orders, by = "customer_id", use_joinspy = FALSE)
#> 
#> ── Join Diagnosis
#> Cardinality: one-to-many
#> x: 5 rows, unique
#> y: 8 rows, 3 duplicates
```

The diagnosis shows:

- **Cardinality is one-to-many**: Each customer can have multiple orders

- **Coverage**: Shows how many keys match vs. don’t match

Now you know what to expect. A `left_join()` will create 8 rows (one per
order), not 5 (one per customer).

### Compare key structures

``` r

compare_keys(customers, orders)
#> 
#> ── Key Comparison
#> Comparing on: customer_id
#> 
#> x: 5 unique keys
#> y: 5 unique keys
#> 
#> Common: 5 (100.0% of x)
#> Only in x: 0
#> Only in y: 0
```

This shows the join key exists in both tables but with different
uniqueness properties—essential information before joining.

------------------------------------------------------------------------

## Workflow 3: Row Identity Tracking

**Goal**: Track which original rows survive through a complex pipeline.

**Challenge**: After filtering, aggregating, and joining, you lose track
of which source rows contributed to your final data.

**Strategy**: Use
[`add_id()`](https://gillescolling.com/keyed/reference/add_id.md) to
attach stable identifiers that survive transformations.

### Add row IDs

``` r

# Add UUIDs to rows
customers_tracked <- customers |>
  add_id()

customers_tracked
#> # A keyed tibble: 5 x 4
#> # Key:            customer_id | .id
#>   .id                                  customer_id name  tier  
#>   <chr>                                      <int> <chr> <chr> 
#> 1 c97e636d-cd69-4e0a-801c-862fbe6f1171           1 Alice gold  
#> 2 0c4f2853-33fe-4e14-8bf7-f05b869df7ca           2 Bob   silver
#> 3 bdaad0a7-57e6-433c-afc7-27820f3508fb           3 Carol gold  
#> 4 74a24590-77bb-491f-a1a3-5fee028a6bc1           4 Dave  bronze
#> 5 6c51e048-048d-45ef-b6fe-73be4351b115           5 Eve   silver
```

### IDs survive transformations

``` r

# Filter: IDs persist
gold_customers <- customers_tracked |>
  filter(tier == "gold")

get_id(gold_customers)
#> [1] "c97e636d-cd69-4e0a-801c-862fbe6f1171"
#> [2] "bdaad0a7-57e6-433c-afc7-27820f3508fb"

# Compare with original
compare_ids(customers_tracked, gold_customers)
#> $lost
#> [1] "0c4f2853-33fe-4e14-8bf7-f05b869df7ca"
#> [2] "74a24590-77bb-491f-a1a3-5fee028a6bc1"
#> [3] "6c51e048-048d-45ef-b6fe-73be4351b115"
#> 
#> $gained
#> character(0)
#> 
#> $preserved
#> [1] "c97e636d-cd69-4e0a-801c-862fbe6f1171"
#> [2] "bdaad0a7-57e6-433c-afc7-27820f3508fb"
```

The comparison shows exactly which rows were lost (filtered out) and
which were preserved.

### Combining data with ID handling

When appending new data,
[`bind_id()`](https://gillescolling.com/keyed/reference/bind_id.md)
handles ID conflicts:

``` r

batch1 <- data.frame(x = 1:3) |> add_id()
batch2 <- data.frame(x = 4:6)  # No IDs yet

# bind_id assigns new IDs to batch2 and checks for conflicts
combined <- bind_id(batch1, batch2)
combined
#>                                    .id x
#> 1 4f0617c9-643f-47a9-9a4c-456f9558fb8d 1
#> 2 4fb77981-65fc-42b6-9fad-79ad75a362f6 2
#> 3 a8e3e7d6-001b-4713-9886-129665db919f 3
#> 4 433c314e-5149-469f-b960-eb1c5b9b29b6 4
#> 5 fbe68c09-82d0-454b-a2e0-fe7f7ff68694 5
#> 6 f6776c3f-480a-4e3e-b94c-9170208e4edb 6
```

------------------------------------------------------------------------

## Workflow 4: Drift Detection

**Goal**: Detect when data changes unexpectedly between pipeline runs.

**Challenge**: Reference data (lookup tables, dimension tables) changes
upstream without notice. Your pipeline silently uses stale assumptions.

**Strategy**: Commit snapshots with
[`stamp()`](https://gillescolling.com/keyed/reference/stamp.md) and
check for drift with
[`check_drift()`](https://gillescolling.com/keyed/reference/check_drift.md).

### Commit a reference snapshot

``` r

# Commit current state as reference
reference_data <- data.frame(
  region_id = c("US", "EU", "APAC"),
  tax_rate = c(0.08, 0.20, 0.10)
) |>
  key(region_id) |>
  stamp()
#> ✔ Snapshot committed: 76a76466...
```

### Check for drift

``` r

# No changes yet
check_drift(reference_data)
#> 
#> ── Drift Report
#> Snapshot: 76a76466... (2026-02-25 11:16)
#> ✔ No drift detected
```

### Detect changes

``` r

# Simulate upstream change: EU tax rate changed
modified_data <- reference_data
modified_data$tax_rate[2] <- 0.21

# Drift detected!
check_drift(modified_data)
#> 
#> ── Drift Report
#> Snapshot: 76a76466... (2026-02-25 11:16)
#> ! Drift detected
#> 
#> ── Value Diff
#> Key: region_id
#> 
#> ! Modified: 1 row(s)
#> tax_rate: 1 change(s)
#> Unchanged: 2 row(s)
```

The drift report shows exactly what changed, letting you decide whether
to accept the new data or investigate.

### Row-level diff

For detailed cell-level comparison, use
[`diff()`](https://rdrr.io/r/base/diff.html) on two keyed data frames:

``` r

old_rates <- key(data.frame(
  region_id = c("US", "EU", "APAC"),
  tax_rate  = c(0.08, 0.20, 0.10)
), region_id)

new_rates <- data.frame(
  region_id = c("US", "EU", "APAC", "LATAM"),
  tax_rate  = c(0.08, 0.21, 0.10, 0.15)
)

diff(old_rates, new_rates)
#> 
#> ── Value Diff
#> Key: region_id
#> 
#> ℹ Added: 1 row(s)
#> ! Modified: 1 row(s)
#> tax_rate: 1 change(s)
#> Unchanged: 2 row(s)
```

### Cleanup

``` r

# Remove snapshots when done
clear_all_snapshots()
#> ! This will remove 1 snapshot(s) from cache.
#> ✔ Cleared 1 snapshot(s).
```

------------------------------------------------------------------------

## Quick Reference

### Core Functions

| Function | Purpose |
|----|----|
| [`key()`](https://gillescolling.com/keyed/reference/key.md) | Define key columns (validates uniqueness) |
| [`unkey()`](https://gillescolling.com/keyed/reference/unkey.md) | Remove key |
| [`has_key()`](https://gillescolling.com/keyed/reference/has_key.md), [`get_key_cols()`](https://gillescolling.com/keyed/reference/get_key_cols.md) | Query key status |

### Assumption Checks

| Function | Validates |
|----|----|
| [`lock_unique()`](https://gillescolling.com/keyed/reference/lock_unique.md) | No duplicate values |
| [`lock_no_na()`](https://gillescolling.com/keyed/reference/lock_no_na.md) | No missing values |
| [`lock_complete()`](https://gillescolling.com/keyed/reference/lock_complete.md) | All expected values present |
| [`lock_coverage()`](https://gillescolling.com/keyed/reference/lock_coverage.md) | Reference values covered |
| [`lock_nrow()`](https://gillescolling.com/keyed/reference/lock_nrow.md) | Row count within bounds |

### Diagnostics

| Function | Purpose |
|----|----|
| [`diagnose_join()`](https://gillescolling.com/keyed/reference/diagnose_join.md) | Analyze join cardinality |
| [`compare_keys()`](https://gillescolling.com/keyed/reference/compare_keys.md) | Compare key structures |
| [`compare_ids()`](https://gillescolling.com/keyed/reference/compare_ids.md) | Compare row identities |
| [`find_duplicates()`](https://gillescolling.com/keyed/reference/find_duplicates.md) | Find duplicate key values |
| [`key_status()`](https://gillescolling.com/keyed/reference/key_status.md) | Quick status summary |

### Row Identity

| Function | Purpose |
|----|----|
| [`add_id()`](https://gillescolling.com/keyed/reference/add_id.md) | Add UUID to rows |
| [`get_id()`](https://gillescolling.com/keyed/reference/get_id.md) | Retrieve row IDs |
| [`bind_id()`](https://gillescolling.com/keyed/reference/bind_id.md) | Combine data with ID handling |
| [`make_id()`](https://gillescolling.com/keyed/reference/make_id.md) | Create deterministic IDs from columns |
| [`check_id()`](https://gillescolling.com/keyed/reference/check_id.md) | Validate ID integrity |

### Drift Detection

| Function | Purpose |
|----|----|
| [`stamp()`](https://gillescolling.com/keyed/reference/stamp.md) | Save reference snapshot |
| [`check_drift()`](https://gillescolling.com/keyed/reference/check_drift.md) | Compare against snapshot |
| [`diff()`](https://rdrr.io/r/base/diff.html) | Cell-level comparison of two data frames |
| [`list_snapshots()`](https://gillescolling.com/keyed/reference/list_snapshots.md) | View saved snapshots |
| [`clear_snapshot()`](https://gillescolling.com/keyed/reference/clear_snapshot.md) | Remove specific snapshot |

------------------------------------------------------------------------

## When to Use Something Else

keyed is designed for **flat-file workflows** without database
infrastructure. If you need:

| Need                 | Better Alternative        |
|----------------------|---------------------------|
| Enforced schema      | Database (SQLite, DuckDB) |
| Version history      | Git, git2r                |
| Full data validation | pointblank, validate      |
| Production pipelines | targets                   |

keyed fills a specific gap: lightweight key tracking for exploratory and
semi-structured workflows where heavier tools add friction.

------------------------------------------------------------------------

## See Also

- [Design
  Philosophy](https://gillescolling.com/keyed/articles/philosophy.md) -
  The reasoning behind keyed’s approach

- [Function
  Reference](https://gillescolling.com/keyed/reference/index.html) -
  Complete API documentation
