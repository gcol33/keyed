# Check IDs are disjoint across datasets

Verifies that ID columns don't overlap between datasets. Useful before
binding datasets to ensure no ID collisions.

## Usage

``` r
check_id_disjoint(..., .id = ".id")
```

## Arguments

- ...:

  Data frames to check.

- .id:

  Column name for IDs (default: ".id").

## Value

Invisibly returns a list with:

- `disjoint`: TRUE if no overlaps found

- `overlaps`: character vector of overlapping IDs (if any)

## Examples

``` r
df1 <- add_id(data.frame(x = 1:3))
df2 <- add_id(data.frame(x = 4:6))
check_id_disjoint(df1, df2)
```
