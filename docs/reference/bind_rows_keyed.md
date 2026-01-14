# Bind rows of keyed data frames

Wrapper for dplyr::bind_rows that attempts to preserve key.

## Usage

``` r
bind_rows_keyed(..., .id = NULL)
```

## Arguments

- ...:

  Data frames to bind.

- .id:

  Optional column name to identify source.

## Value

A keyed data frame if key is preserved and unique, otherwise tibble.
