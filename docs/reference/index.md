# Package index

## Key Definition

Define and manage keys

- [`key()`](https://gcol33.github.io/keyed/reference/key.md)
  [`` `key<-`() ``](https://gcol33.github.io/keyed/reference/key.md) :
  Define a key for a data frame
- [`unkey()`](https://gcol33.github.io/keyed/reference/unkey.md) :
  Remove key from a data frame
- [`has_key()`](https://gcol33.github.io/keyed/reference/has_key.md) :
  Check if data frame has a key
- [`get_key_cols()`](https://gcol33.github.io/keyed/reference/get_key_cols.md)
  : Get key column names
- [`key_is_valid()`](https://gcol33.github.io/keyed/reference/key_is_valid.md)
  : Check if the key is still valid
- [`bind_rows_keyed()`](https://gcol33.github.io/keyed/reference/bind_rows_keyed.md)
  : Bind rows of keyed data frames

## Assumption Checks

Validate data assumptions

- [`assume_unique()`](https://gcol33.github.io/keyed/reference/assume_unique.md)
  : Assert that columns are unique
- [`assume_no_na()`](https://gcol33.github.io/keyed/reference/assume_no_na.md)
  : Assert that columns have no missing values
- [`assume_complete()`](https://gcol33.github.io/keyed/reference/assume_complete.md)
  : Assert that data is complete (no missing values anywhere)
- [`assume_coverage()`](https://gcol33.github.io/keyed/reference/assume_coverage.md)
  : Assert minimum coverage of values
- [`assume_nrow()`](https://gcol33.github.io/keyed/reference/assume_nrow.md)
  : Assert row count within expected range

## Join Diagnostics

Analyze joins before executing

- [`diagnose_join()`](https://gcol33.github.io/keyed/reference/diagnose_join.md)
  : Diagnose a join before executing

## Row Identity

Stable UUIDs for lineage tracking

- [`add_id()`](https://gcol33.github.io/keyed/reference/add_id.md) : Add
  identity column
- [`has_id()`](https://gcol33.github.io/keyed/reference/has_id.md) :
  Check if data frame has IDs
- [`get_id()`](https://gcol33.github.io/keyed/reference/get_id.md) : Get
  ID column
- [`remove_id()`](https://gcol33.github.io/keyed/reference/remove_id.md)
  : Remove ID column
- [`extend_id()`](https://gcol33.github.io/keyed/reference/extend_id.md)
  : Extend IDs to new rows
- [`make_id()`](https://gcol33.github.io/keyed/reference/make_id.md) :
  Create ID from columns
- [`bind_id()`](https://gcol33.github.io/keyed/reference/bind_id.md) :
  Bind data frames with ID handling
- [`check_id()`](https://gcol33.github.io/keyed/reference/check_id.md) :
  Check ID integrity
- [`check_id_disjoint()`](https://gcol33.github.io/keyed/reference/check_id_disjoint.md)
  : Check IDs are disjoint across datasets
- [`compare_ids()`](https://gcol33.github.io/keyed/reference/compare_ids.md)
  : Compare IDs between data frames

## Drift Detection

Track changes over time

- [`commit_keyed()`](https://gcol33.github.io/keyed/reference/commit_keyed.md)
  : Commit a keyed data frame as reference
- [`check_drift()`](https://gcol33.github.io/keyed/reference/check_drift.md)
  : Check for drift from committed snapshot
- [`clear_snapshot()`](https://gcol33.github.io/keyed/reference/clear_snapshot.md)
  : Clear snapshot for a data frame
- [`list_snapshots()`](https://gcol33.github.io/keyed/reference/list_snapshots.md)
  : List all snapshots in cache
- [`clear_all_snapshots()`](https://gcol33.github.io/keyed/reference/clear_all_snapshots.md)
  : Clear all snapshots from cache

## Diagnostics

Inspect and compare data

- [`key_status()`](https://gcol33.github.io/keyed/reference/key_status.md)
  : Get key status summary
- [`compare_structure()`](https://gcol33.github.io/keyed/reference/compare_structure.md)
  : Compare structure of two data frames
- [`compare_keys()`](https://gcol33.github.io/keyed/reference/compare_keys.md)
  : Compare key values between two data frames
- [`find_duplicates()`](https://gcol33.github.io/keyed/reference/find_duplicates.md)
  : Find duplicate keys
- [`summary(`*`<keyed_df>`*`)`](https://gcol33.github.io/keyed/reference/summary.keyed_df.md)
  : Summary method for keyed data frames
