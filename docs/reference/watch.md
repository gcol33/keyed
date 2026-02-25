# Watch a keyed data frame for automatic drift detection

Marks a keyed data frame as "watched". Watched data frames are
automatically stamped before each dplyr verb, so
[`check_drift()`](https://gillescolling.com/keyed/reference/check_drift.md)
always reports changes from the most recent transformation step.

## Usage

``` r
watch(.data)
```

## Arguments

- .data:

  A keyed data frame.

## Value

Invisibly returns `.data` with watched attribute set and a baseline
snapshot committed.

## See also

[`unwatch()`](https://gillescolling.com/keyed/reference/unwatch.md) to
stop watching,
[`stamp()`](https://gillescolling.com/keyed/reference/stamp.md) for
manual snapshots.

## Examples

``` r
df <- key(data.frame(id = 1:5, x = letters[1:5]), id) |> watch()
df2 <- df |> dplyr::filter(id > 2)
check_drift(df2)
```
