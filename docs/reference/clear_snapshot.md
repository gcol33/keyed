# Clear snapshot for a data frame

Removes the snapshot reference from a data frame.

## Usage

``` r
clear_snapshot(.data, purge = FALSE)
```

## Arguments

- .data:

  A data frame.

- purge:

  If TRUE, also remove the snapshot from cache.

## Value

Data frame without snapshot reference.
