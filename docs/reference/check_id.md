# Check ID integrity

Validates ID column for common issues: missing values, duplicates, and
suspicious formats.

## Usage

``` r
check_id(.data, .id = ".id")
```

## Arguments

- .data:

  A data frame with ID column.

- .id:

  Column name (default: ".id").

## Value

Invisibly returns a list with:

- `valid`: TRUE if no issues found

- `n_na`: count of NA values

- `n_duplicates`: count of duplicate IDs

- `format_ok`: TRUE if IDs look like proper UUIDs/hashes

## Examples

``` r
df <- add_id(data.frame(x = 1:3))
check_id(df)
```
