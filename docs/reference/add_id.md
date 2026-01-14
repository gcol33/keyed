# Add identity column

Adds a stable UUID column to each row. This is an opt-in feature for
tracking row lineage through transformations.

## Usage

``` r
add_id(.data, .id = ".id", .overwrite = FALSE)
```

## Arguments

- .data:

  A data frame.

- .id:

  Column name for the ID (default: ".id").

- .overwrite:

  If TRUE, overwrite existing ID column. If FALSE (default), error if
  column exists.

## Value

Data frame with ID column added.

## Details

IDs are generated using a hash of row content plus a random salt, making
them stable for identical rows within a session but unique across
different data frames.

If the uuid package is available, it will be used for true UUIDs.
Otherwise, a hash-based ID is generated.

## Examples

``` r
df <- data.frame(x = 1:3, y = c("a", "b", "c"))
df <- add_id(df)
df
```
