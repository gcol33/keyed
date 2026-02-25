# Assert minimum coverage of values

Checks that the fraction of non-NA values meets a threshold. Useful
after joins to verify expected coverage.

## Usage

``` r
lock_coverage(.data, threshold, ..., .strict = FALSE)
```

## Arguments

- .data:

  A data frame.

- threshold:

  Minimum fraction of non-NA values (0 to 1).

- ...:

  Column names (unquoted) to check. If empty, checks all columns.

- .strict:

  If `TRUE`, error on failure. If `FALSE` (default), warn.

## Value

Invisibly returns `.data` (for piping).

## Examples

``` r
df <- data.frame(id = 1:10, x = c(1:8, NA, NA))
lock_coverage(df, 0.8, x)
lock_coverage(df, 0.9, x)  # warns (only 80% coverage)
```
