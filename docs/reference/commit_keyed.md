# Commit a keyed data frame as reference

Stores a hash-based snapshot of the current data state. Only one active
reference per data frame (identified by its content hash).

## Usage

``` r
commit_keyed(.data, name = NULL)
```

## Arguments

- .data:

  A data frame (preferably keyed).

- name:

  Optional name for the snapshot. If NULL, derived from data.

## Value

Invisibly returns `.data` with snapshot metadata attached.

## Details

The snapshot stores:

- Row count

- Column names and types

- Hash of key columns (if keyed)

- Hash of full content

Snapshots are stored in memory for the session. They are keyed by
content hash, so identical data shares the same snapshot.

## Examples

``` r
df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
df <- commit_keyed(df)

# Later, check for drift
df2 <- df
df2$x[1] <- "z"
check_drift(df2)
```
