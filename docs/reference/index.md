# Package index

## Key Definition

Define and manage keys

- [`key()`](https://gillescolling.com/keyed/reference/key.md)
  [`` `key<-`() ``](https://gillescolling.com/keyed/reference/key.md) :
  Define a key for a data frame
- [`unkey()`](https://gillescolling.com/keyed/reference/unkey.md) :
  Remove key from a data frame
- [`has_key()`](https://gillescolling.com/keyed/reference/has_key.md) :
  Check if data frame has a key
- [`get_key_cols()`](https://gillescolling.com/keyed/reference/get_key_cols.md)
  : Get key column names
- [`key_is_valid()`](https://gillescolling.com/keyed/reference/key_is_valid.md)
  : Check if the key is still valid
- [`bind_keyed()`](https://gillescolling.com/keyed/reference/bind_keyed.md)
  : Bind rows of keyed data frames

## Assumption Checks

Validate data assumptions

- [`lock_unique()`](https://gillescolling.com/keyed/reference/lock_unique.md)
  : Assert that columns are unique
- [`lock_no_na()`](https://gillescolling.com/keyed/reference/lock_no_na.md)
  : Assert that columns have no missing values
- [`lock_complete()`](https://gillescolling.com/keyed/reference/lock_complete.md)
  : Assert that data is complete (no missing values anywhere)
- [`lock_coverage()`](https://gillescolling.com/keyed/reference/lock_coverage.md)
  : Assert minimum coverage of values
- [`lock_nrow()`](https://gillescolling.com/keyed/reference/lock_nrow.md)
  : Assert row count within expected range

## Join Diagnostics

Analyze joins before executing

- [`diagnose_join()`](https://gillescolling.com/keyed/reference/diagnose_join.md)
  : Diagnose a join before executing

## Row Identity

Stable UUIDs for lineage tracking

- [`add_id()`](https://gillescolling.com/keyed/reference/add_id.md) :
  Add identity column
- [`has_id()`](https://gillescolling.com/keyed/reference/has_id.md) :
  Check if data frame has IDs
- [`get_id()`](https://gillescolling.com/keyed/reference/get_id.md) :
  Get ID column
- [`remove_id()`](https://gillescolling.com/keyed/reference/remove_id.md)
  : Remove ID column
- [`extend_id()`](https://gillescolling.com/keyed/reference/extend_id.md)
  : Extend IDs to new rows
- [`make_id()`](https://gillescolling.com/keyed/reference/make_id.md) :
  Create ID from columns
- [`bind_id()`](https://gillescolling.com/keyed/reference/bind_id.md) :
  Bind data frames with ID handling
- [`check_id()`](https://gillescolling.com/keyed/reference/check_id.md)
  : Check ID integrity
- [`check_id_disjoint()`](https://gillescolling.com/keyed/reference/check_id_disjoint.md)
  : Check IDs are disjoint across datasets
- [`compare_ids()`](https://gillescolling.com/keyed/reference/compare_ids.md)
  : Compare IDs between data frames

## Drift Detection

Track changes over time

- [`stamp()`](https://gillescolling.com/keyed/reference/stamp.md)
  [`commit_keyed()`](https://gillescolling.com/keyed/reference/stamp.md)
  : Stamp a data frame as reference
- [`check_drift()`](https://gillescolling.com/keyed/reference/check_drift.md)
  : Check for drift from committed snapshot
- [`watch()`](https://gillescolling.com/keyed/reference/watch.md) :
  Watch a keyed data frame for automatic drift detection
- [`unwatch()`](https://gillescolling.com/keyed/reference/unwatch.md) :
  Stop watching a keyed data frame
- [`diff(`*`<keyed_df>`*`)`](https://gillescolling.com/keyed/reference/diff.keyed_df.md)
  : Diff two keyed data frames
- [`clear_snapshot()`](https://gillescolling.com/keyed/reference/clear_snapshot.md)
  : Clear snapshot for a data frame
- [`list_snapshots()`](https://gillescolling.com/keyed/reference/list_snapshots.md)
  : List all snapshots in cache
- [`clear_all_snapshots()`](https://gillescolling.com/keyed/reference/clear_all_snapshots.md)
  : Clear all snapshots from cache

## Diagnostics

Inspect and compare data

- [`key_status()`](https://gillescolling.com/keyed/reference/key_status.md)
  : Get key status summary
- [`compare_structure()`](https://gillescolling.com/keyed/reference/compare_structure.md)
  : Compare structure of two data frames
- [`compare_keys()`](https://gillescolling.com/keyed/reference/compare_keys.md)
  : Compare key values between two data frames
- [`find_duplicates()`](https://gillescolling.com/keyed/reference/find_duplicates.md)
  : Find duplicate keys
- [`summary(`*`<keyed_df>`*`)`](https://gillescolling.com/keyed/reference/summary.keyed_df.md)
  : Summary method for keyed data frames
