# keyed

[![R-CMD-check](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gcol33/keyed/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/gcol33/keyed/graph/badge.svg)](https://app.codecov.io/gh/gcol33/keyed)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Lightweight Uniqueness Tracking for Flat-File Data**

Attach keys to data frames, validate uniqueness at creation, and get warnings when transformations break your assumptions. Designed for CSV-first workflows without databases.

## Quick Start

```r
library(keyed)

# Declare that user_id should be unique
users <- read.csv("users.csv") |>
  key(user_id)

# Keys survive dplyr transformations
active <- users |> filter(status == "active")
has_key(active)
#> [1] TRUE

# Warns if a transformation breaks uniqueness
users |> mutate(user_id = 1)
#> Warning: Column 'user_id' is no longer unique. Removing key.
```

## Statement of Need

Flat-file workflows (CSVs, Excel exports) lack database guarantees. Assumptions like "this column is unique" or "no NAs here" live in comments or your head, breaking silently when upstream data changes.

keyed makes these assumptions explicit:

- **Attach keys** that persist through transformations
- **Warn on violations** instead of failing silently or blocking
- **Diagnose joins** before row counts explode
- **Track row identity** with stable UUIDs
- **Detect drift** between data versions

## Installation

```r
# install.packages("pak")
pak::pak("gcol33/keyed")
```

## Features

### Keys and Assumptions

```r
key(data, col1, col2)           # Declare unique columns
assume_unique(data, col)        # Assert uniqueness
assume_no_na(data, col)         # Assert no missing values
assume_complete(data, col, expected = c("A", "B"))
assume_nrow(data, min = 100)    # Assert row count bounds
```

### Join Diagnostics

```r
diagnose_join(users, orders, by = "user_id")
#> Cardinality: one-to-many
#> x: 1000 rows, unique
#> y: 5432 rows, 4432 duplicates
```

### Row Identity

```r
data <- add_id(data)            # Attach UUIDs
get_id(filtered_data)           # Retrieve IDs after transformations
compare_ids(before, after)      # See what rows were lost/gained
```

### Drift Detection

```r
data <- commit_keyed(data)      # Save snapshot
check_drift(data)               # Compare against snapshot
#> Drift detected: 24 rows added, 3 cells modified
```

## When to Use Something Else

| Need | Better Tool |
|------|-------------|
| Enforced schema | SQLite, DuckDB |
| Full data validation | pointblank, validate |
| Production pipelines | targets |
| Version history | Git |

keyed is for exploratory and semi-structured workflows where heavier tools add friction.

## Documentation

- [Quick Start](https://gillescolling.com/keyed/articles/quickstart.html)
- [Design Philosophy](https://gillescolling.com/keyed/articles/philosophy.html)
- [Function Reference](https://gillescolling.com/keyed/reference/index.html)

## Support

> "Software is like sex: it's better when it's free." — Linus Torvalds

I'm a PhD student who builds R packages in my free time because I believe good tools should be free and open. I started these projects for my own work and figured others might find them useful too.

If this package saved you some time, buying me a coffee is a nice way to say thanks. It helps with my coffee addiction.

[![Buy Me A Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/gcol33)

## License

MIT (see the LICENSE.md file)
