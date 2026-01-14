# Compare IDs between data frames

Compares IDs between two data frames to detect lost rows.

## Usage

``` r
compare_ids(before, after, .id = ".id")
```

## Arguments

- before:

  Data frame before transformation.

- after:

  Data frame after transformation.

- .id:

  Column name for IDs (default: ".id").

## Value

A list with:

- `lost`: IDs present in `before` but not `after`

- `gained`: IDs present in `after` but not `before`

- `preserved`: IDs present in both

## Examples

``` r
df1 <- add_id(data.frame(x = 1:5))
df2 <- df1[1:3, ]
compare_ids(df1, df2)
```
