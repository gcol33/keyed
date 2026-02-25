# Assert row count within expected range

Checks that the number of rows is within an expected range. Useful for
sanity checks after filtering or joins.

## Usage

``` r
lock_nrow(.data, min = 1, max = Inf, expected = NULL, .strict = FALSE)
```

## Arguments

- .data:

  A data frame.

- min:

  Minimum expected rows (inclusive). Default 1.

- max:

  Maximum expected rows (inclusive). Default Inf.

- expected:

  Exact expected row count. If provided, overrides min/max.

- .strict:

  If `TRUE`, error on failure. If `FALSE` (default), warn.

## Value

Invisibly returns `.data` (for piping).

## Examples

``` r
df <- data.frame(id = 1:100)
lock_nrow(df, min = 50, max = 200)
lock_nrow(df, expected = 100)
```
