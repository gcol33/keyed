# Stop watching a keyed data frame

Removes the watched attribute. Dplyr verbs will no longer auto-stamp.

## Usage

``` r
unwatch(.data)
```

## Arguments

- .data:

  A data frame.

## Value

`.data` without the watched attribute.

## See also

[`watch()`](https://gillescolling.com/keyed/reference/watch.md)

## Examples

``` r
df <- key(data.frame(id = 1:3, x = 1:3), id) |> watch()
df <- unwatch(df)
```
