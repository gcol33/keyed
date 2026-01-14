# Find duplicate keys

Identifies rows with duplicate key values.

## Usage

``` r
find_duplicates(.data, ...)
```

## Arguments

- .data:

  A data frame.

- ...:

  Column names to check. If empty, uses the key columns.

## Value

Data frame containing only the rows with duplicate keys, with a `.n`
column showing the count.

## Examples

``` r
df <- data.frame(id = c(1, 1, 2, 3, 3, 3), x = letters[1:6])
find_duplicates(df, id)
```
