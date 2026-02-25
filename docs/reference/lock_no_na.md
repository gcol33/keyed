# Assert that columns have no missing values

Checks that specified columns contain no NA values.

## Usage

``` r
lock_no_na(.data, ..., .strict = FALSE)
```

## Arguments

- .data:

  A data frame.

- ...:

  Column names (unquoted) to check. If empty, checks all columns.

- .strict:

  If `TRUE`, error on failure. If `FALSE` (default), warn.

## Value

Invisibly returns `.data` (for piping).

## Examples

``` r
df <- data.frame(id = 1:3, x = c("a", NA, "c"))
lock_no_na(df, id)
lock_no_na(df, x)  # warns
```
