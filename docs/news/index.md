# Changelog

## keyed 0.2.0

### New Features

- [`stamp()`](https://gillescolling.com/keyed/reference/stamp.md)
  replaces
  [`commit_keyed()`](https://gillescolling.com/keyed/reference/stamp.md)
  for snapshot creation.
  [`commit_keyed()`](https://gillescolling.com/keyed/reference/stamp.md)
  is deprecated with a lifecycle warning.

- [`diff()`](https://rdrr.io/r/base/diff.html) method for keyed data
  frames: cell-level comparison using key columns to align rows. Reports
  added, removed, and modified rows with per-column change detail.

- [`watch()`](https://gillescolling.com/keyed/reference/watch.md) /
  [`unwatch()`](https://gillescolling.com/keyed/reference/unwatch.md):
  Mark keyed data frames as “watched” so dplyr verbs auto-stamp before
  executing. Turns drift detection from a manual ceremony into an
  automatic safety net.

- [`check_drift()`](https://gillescolling.com/keyed/reference/check_drift.md)
  now returns cell-level reports. When both the snapshot and current
  data are keyed with the same key columns, the drift report includes a
  full `keyed_diff` with per-column change detail. Falls back to
  structural comparison (row count, columns) when keys differ or are
  lost.

- [`stamp()`](https://gillescolling.com/keyed/reference/stamp.md) gains
  a `.silent` parameter for suppressing cli output during auto-stamping.

- [`list_snapshots()`](https://gillescolling.com/keyed/reference/list_snapshots.md)
  gains a `size_mb` column showing memory usage per snapshot.

- [`compare_structure()`](https://gillescolling.com/keyed/reference/compare_structure.md),
  [`compare_keys()`](https://gillescolling.com/keyed/reference/compare_keys.md):
  structural comparison helpers.

### Breaking Changes

- Renamed
  [`commit_keyed()`](https://gillescolling.com/keyed/reference/stamp.md)
  to [`stamp()`](https://gillescolling.com/keyed/reference/stamp.md).
  The old name is soft-deprecated.

### Internal Changes

- Snapshot cache now stores full data frames (not just hashes), enabling
  cell-level drift comparison without re-reading source data.

- Cache reduced from 100 to 20 entries and adds a 100 MB soft memory
  cap. Eviction remains LRU-based but now considers both count and
  memory.

- All dplyr methods (`filter`, `mutate`, `select`, `arrange`, `rename`,
  `summarise`, `slice`, `distinct`, `group_by`, `ungroup`) now propagate
  snapshot references and watched state through transformations.

## keyed 0.1.1

### Breaking Changes

- Operations that break key uniqueness now **error** instead of warning.
  Previously, keyed would warn and silently remove the key. Now it stops
  with an error, requiring explicit
  [`unkey()`](https://gillescolling.com/keyed/reference/unkey.md) to
  proceed. This prevents silent data corruption.

### Improvements

- Added Codecov integration for test coverage tracking
- Improved README with problem-solution framing and Row UUIDs section
- Added CONTRIBUTING.md with contribution guidelines
- Expanded test suite to 90%+ coverage
- Fixed
  [`find_duplicates()`](https://gillescolling.com/keyed/reference/find_duplicates.md)
  to work with keyed data that has duplicates

## keyed 0.1.0

### Initial Release

#### Key Definition

- [`key()`](https://gillescolling.com/keyed/reference/key.md) /
  [`unkey()`](https://gillescolling.com/keyed/reference/unkey.md):
  Define and remove keys from data frames
- [`has_key()`](https://gillescolling.com/keyed/reference/has_key.md) /
  [`get_key_cols()`](https://gillescolling.com/keyed/reference/get_key_cols.md)
  /
  [`key_is_valid()`](https://gillescolling.com/keyed/reference/key_is_valid.md):
  Query key status
- Keys survive dplyr transformations (filter, mutate, arrange, etc.)

#### Assumption Checks

- [`lock_unique()`](https://gillescolling.com/keyed/reference/lock_unique.md):
  Verify column uniqueness
- [`lock_no_na()`](https://gillescolling.com/keyed/reference/lock_no_na.md):
  Check for missing values
- [`lock_complete()`](https://gillescolling.com/keyed/reference/lock_complete.md):
  Ensure expected values are present
- [`lock_coverage()`](https://gillescolling.com/keyed/reference/lock_coverage.md):
  Validate reference coverage
- [`lock_nrow()`](https://gillescolling.com/keyed/reference/lock_nrow.md):
  Check row count bounds

#### Join Diagnostics

- [`diagnose_join()`](https://gillescolling.com/keyed/reference/diagnose_join.md):
  Analyze join cardinality before executing
- Optional integration with joinspy for enhanced diagnostics

#### Row Identity

- [`add_id()`](https://gillescolling.com/keyed/reference/add_id.md) /
  [`remove_id()`](https://gillescolling.com/keyed/reference/remove_id.md):
  Add/remove stable UUIDs
- [`has_id()`](https://gillescolling.com/keyed/reference/has_id.md) /
  [`get_id()`](https://gillescolling.com/keyed/reference/get_id.md):
  Query ID status
- [`extend_id()`](https://gillescolling.com/keyed/reference/extend_id.md):
  Fill missing IDs after binding
- [`make_id()`](https://gillescolling.com/keyed/reference/make_id.md):
  Create composite IDs from columns
- [`bind_id()`](https://gillescolling.com/keyed/reference/bind_id.md):
  Combine data with ID handling
- [`check_id()`](https://gillescolling.com/keyed/reference/check_id.md)
  /
  [`check_id_disjoint()`](https://gillescolling.com/keyed/reference/check_id_disjoint.md):
  Validate ID integrity
- [`compare_ids()`](https://gillescolling.com/keyed/reference/compare_ids.md):
  Detect lost/gained rows

#### Drift Detection

- [`commit_keyed()`](https://gillescolling.com/keyed/reference/stamp.md):
  Commit reference snapshot
- [`check_drift()`](https://gillescolling.com/keyed/reference/check_drift.md):
  Detect changes from snapshot
- [`list_snapshots()`](https://gillescolling.com/keyed/reference/list_snapshots.md)
  /
  [`clear_snapshot()`](https://gillescolling.com/keyed/reference/clear_snapshot.md)
  /
  [`clear_all_snapshots()`](https://gillescolling.com/keyed/reference/clear_all_snapshots.md):
  Manage snapshots

#### Diagnostics

- [`key_status()`](https://gillescolling.com/keyed/reference/key_status.md):
  Quick status summary
- [`summary.keyed_df()`](https://gillescolling.com/keyed/reference/summary.keyed_df.md):
  Detailed summary method
- [`compare_structure()`](https://gillescolling.com/keyed/reference/compare_structure.md):
  Compare schema between data frames
- [`compare_keys()`](https://gillescolling.com/keyed/reference/compare_keys.md):
  Compare key values between datasets
- [`find_duplicates()`](https://gillescolling.com/keyed/reference/find_duplicates.md):
  Locate duplicate key values
