# Assert that columns are unique

Checks that the combination of specified columns has unique values. This
is a point-in-time assertion that either passes silently or fails.

## Usage

``` r
assume_unique(.data, ..., .strict = FALSE)
```

## Arguments

- .data:

  A data frame.

- ...:

  Column names (unquoted) to check for uniqueness.

- .strict:

  If `TRUE`, error on failure. If `FALSE` (default), warn.

## Value

Invisibly returns `.data` (for piping).

## Examples

``` r
df <- data.frame(id = 1:3, x = c("a", "b", "c"))
assume_unique(df, id)

# Fails with warning
df2 <- data.frame(id = c(1, 1, 2), x = c("a", "b", "c"))
assume_unique(df2, id)
```
