# Bind data frames with ID handling

Binds data frames while properly handling ID columns. Checks for
overlapping IDs, combines the data, and fills in missing IDs.

## Usage

``` r
bind_id(..., .id = ".id")
```

## Arguments

- ...:

  Data frames to bind.

- .id:

  Column name for IDs (default: ".id").

## Value

Combined data frame with valid IDs for all rows.

## Details

This function:

1.  Checks if IDs overlap between datasets (warns if so)

2.  Binds rows using
    [`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html)

3.  Fills missing IDs using
    [`extend_id()`](https://gillescolling.com/keyed/reference/extend_id.md)

Use this instead of
[`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html)
when working with ID columns.

## Examples

``` r
df1 <- add_id(data.frame(x = 1:3))
df2 <- data.frame(x = 4:6)
combined <- bind_id(df1, df2)
```
