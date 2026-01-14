# Compare structure of two data frames

Compares the structural properties of two data frames without comparing
actual values. Useful for detecting schema drift.

## Usage

``` r
compare_structure(x, y)
```

## Arguments

- x:

  First data frame.

- y:

  Second data frame.

## Value

A structure comparison object.

## Examples

``` r
df1 <- data.frame(id = 1:3, x = c("a", "b", "c"))
df2 <- data.frame(id = 1:5, x = c("a", "b", "c", "d", "e"), y = 1:5)
compare_structure(df1, df2)
```
