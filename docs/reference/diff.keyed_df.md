# Diff two keyed data frames

Compares two data frames row-by-row using the key from `x` to align
rows. Identifies added, removed, and modified rows, with cell-level
detail for modifications.

## Usage

``` r
# S3 method for class 'keyed_df'
diff(x, y, ...)
```

## Arguments

- x:

  A keyed data frame (the "old" or "reference" state).

- y:

  A data frame (the "new" state). Must contain the key columns from `x`.

- ...:

  Ignored (present for S3 compatibility with
  [`base::diff()`](https://rdrr.io/r/base/diff.html)).

## Value

A `keyed_diff` object with fields:

- `key_cols`: character vector of key column names

- `n_removed`, `n_added`, `n_modified`, `n_unchanged`: counts

- `removed`: data frame of rows in `x` not in `y`

- `added`: data frame of rows in `y` not in `x`

- `changes`: named list of per-column change tibbles (each with key
  columns, `old`, and `new`)

- `cols_only_x`, `cols_only_y`: columns present in only one side

## Examples

``` r
old <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
new <- data.frame(id = 2:4, x = c("B", "c", "d"))
diff(old, new)
```
