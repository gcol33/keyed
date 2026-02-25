# Assert that data is complete (no missing values anywhere)

Checks that all columns have no NA values.

## Usage

``` r
lock_complete(.data, .strict = FALSE)
```

## Arguments

- .data:

  A data frame.

- .strict:

  If `TRUE`, error on failure. If `FALSE` (default), warn.

## Value

Invisibly returns `.data` (for piping).
