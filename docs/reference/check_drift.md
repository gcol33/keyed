# Check for drift from committed snapshot

Compares current data against its committed reference snapshot. Returns
diagnostic information about changes.

## Usage

``` r
check_drift(.data, reference = NULL)
```

## Arguments

- .data:

  A data frame with a snapshot reference.

- reference:

  Optional content hash to compare against. If NULL, uses the attached
  snapshot reference.

## Value

A drift report (class `keyed_drift_report`), or NULL if no snapshot
found.

## Examples

``` r
df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
df <- commit_keyed(df)

# Modify the data
df$x[1] <- "modified"
check_drift(df)
```
