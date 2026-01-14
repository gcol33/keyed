# Bind rows of keyed data frames

Bind keyed data frames

## Usage

``` r
bind_keyed(..., .id = NULL)
```

## Arguments

- ...:

  Data frames to bind.

- .id:

  Optional column name to identify source.

## Value

A keyed data frame if key is preserved and unique, otherwise tibble.

## Details

Wrapper for
[`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html)
that attempts to preserve key metadata.
