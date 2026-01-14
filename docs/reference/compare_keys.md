# Compare key values between two data frames

Identifies keys that are new, removed, or common between two keyed data
frames. Does not compare values, only key membership.

## Usage

``` r
compare_keys(x, y, by = NULL)
```

## Arguments

- x:

  First keyed data frame.

- y:

  Second keyed data frame.

- by:

  Column(s) to compare. If NULL, uses the key from x.

## Value

A key comparison object.

## Examples

``` r
df1 <- key(data.frame(id = 1:3, x = 1:3), id)
df2 <- key(data.frame(id = 2:4, x = 2:4), id)
compare_keys(df1, df2)
```
