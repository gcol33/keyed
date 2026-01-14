# Get key status summary

Returns diagnostic information about a keyed data frame.

## Usage

``` r
key_status(.data)
```

## Arguments

- .data:

  A data frame.

## Value

A key status object with diagnostic information.

## Examples

``` r
df <- key(data.frame(id = 1:3, x = c("a", "b", "c")), id)
key_status(df)
```
