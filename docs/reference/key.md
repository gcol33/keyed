# Define a key for a data frame

Attaches key metadata to a data frame, marking which column(s) form the
unique identifier for rows. Keys are validated for uniqueness at
creation.

## Usage

``` r
key(.data, ..., .validate = TRUE, .strict = FALSE)

key(.data) <- value
```

## Arguments

- .data:

  A data frame or tibble.

- ...:

  Column names (unquoted) that form the key. Can be a single column or
  multiple columns for a composite key.

- .validate:

  If `TRUE` (default), check that the key is unique.

- .strict:

  If `TRUE`, error on non-unique keys. If `FALSE` (default), warn but
  still attach the key.

- value:

  Character vector of column names to use as key.

## Value

A keyed data frame (class `keyed_df`).

## Examples

``` r
df <- data.frame(id = 1:3, x = c("a", "b", "c"))
key(df, id)

# Composite key
df2 <- data.frame(country = c("US", "US", "UK"), year = c(2020, 2021, 2020), val = 1:3)
key(df2, country, year)
```
