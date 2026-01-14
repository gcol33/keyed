# Diagnose a join before executing

Analyzes join cardinality without performing the full join. Useful for
detecting many-to-many joins that would explode row count.

## Usage

``` r
diagnose_join(x, y, by = NULL, use_joinspy = TRUE)
```

## Arguments

- x:

  Left data frame.

- y:

  Right data frame.

- by:

  Join specification.

- use_joinspy:

  If TRUE (default), use joinspy for enhanced diagnostics when
  available. Set to FALSE to use built-in diagnostics only.

## Value

A list with cardinality information, or a JoinReport object if joinspy
is used.

## Details

If the joinspy package is installed, this function delegates to
`joinspy::join_spy()` for enhanced diagnostics including whitespace
detection, encoding issues, and detailed match analysis.

## See also

`joinspy::join_spy()` for enhanced diagnostics (if installed)

## Examples

``` r
x <- data.frame(id = c(1, 1, 2), a = 1:3)
y <- data.frame(id = c(1, 1, 2), b = 4:6)
diagnose_join(x, y, by = "id", use_joinspy = FALSE)
```
