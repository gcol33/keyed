# Stamp a data frame as reference

Stores a snapshot of the current data state, including the full data
frame. This enables cell-level drift reports when used with
[`check_drift()`](https://gillescolling.com/keyed/reference/check_drift.md).

## Usage

``` r
stamp(.data, name = NULL, .silent = FALSE)

commit_keyed(.data, name = NULL)
```

## Arguments

- .data:

  A data frame (preferably keyed).

- name:

  Optional name for the snapshot. If NULL, derived from data.

- .silent:

  If `TRUE`, suppress cli output. Used internally by auto-stamping in
  [`watch()`](https://gillescolling.com/keyed/reference/watch.md)ed data
  frames.

## Value

Invisibly returns `.data` with snapshot metadata attached.

## Details

Snapshots are stored in memory for the session. They are keyed by
content hash, so identical data shares the same snapshot.

When data is
[`watch()`](https://gillescolling.com/keyed/reference/watch.md)ed, dplyr
verbs auto-stamp before executing, creating an automatic safety net for
drift detection.

## See also

[`watch()`](https://gillescolling.com/keyed/reference/watch.md) for
automatic stamping before dplyr verbs.

## Examples

``` r
df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
df <- stamp(df)

# Later, check for drift
df2 <- df
df2$x[1] <- "z"
check_drift(df2)
```
