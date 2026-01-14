# Create ID from columns

Creates an ID column by combining values from one or more columns.
Unlike [`add_id()`](https://gcol33.github.io/keyed/reference/add_id.md),
this produces deterministic IDs based on column values.

## Usage

``` r
make_id(.data, ..., .id = ".id", .sep = "|")
```

## Arguments

- .data:

  A data frame.

- ...:

  Columns to combine into the ID.

- .id:

  Column name for the ID (default: ".id").

- .sep:

  Separator between column values (default: "\|").

## Value

Data frame with ID column added.

## Examples

``` r
df <- data.frame(country = c("US", "UK", "US"), year = c(2020, 2020, 2021))
make_id(df, country, year)
#>   .id       country year
#> 1 US|2020  US      2020
#> 2 UK|2020  UK      2020
#> 3 US|2021  US      2021
```
