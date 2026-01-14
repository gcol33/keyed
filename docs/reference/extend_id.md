# Extend IDs to new rows

Adds IDs to rows where the ID column is NA, preserving existing IDs.
Useful after binding new data to an existing dataset with IDs.

## Usage

``` r
extend_id(.data, .id = ".id")
```

## Arguments

- .data:

  A data frame with an ID column (possibly with NAs).

- .id:

  Column name for IDs (default: ".id").

## Value

Data frame with IDs filled in for NA rows.

## Examples

``` r
# Original data with IDs
old <- add_id(data.frame(x = 1:3))

# New data without IDs
new <- data.frame(.id = NA_character_, x = 4:5)

# Combine and extend
combined <- dplyr::bind_rows(old, new)
extend_id(combined)
```
