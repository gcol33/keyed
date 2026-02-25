# keyed 0.2.0

## New Features

* `stamp()` replaces `commit_keyed()` for snapshot creation. `commit_keyed()`
  is deprecated with a lifecycle warning.

* `diff()` method for keyed data frames: cell-level comparison using key
  columns to align rows. Reports added, removed, and modified rows with
  per-column change detail.

* `watch()` / `unwatch()`: Mark keyed data frames as "watched" so dplyr verbs
  auto-stamp before executing. Turns drift detection from a manual ceremony
  into an automatic safety net.

* `check_drift()` now returns cell-level reports. When both the snapshot and
  current data are keyed with the same key columns, the drift report includes
  a full `keyed_diff` with per-column change detail. Falls back to structural
  comparison (row count, columns) when keys differ or are lost.

* `stamp()` gains a `.silent` parameter for suppressing cli output during
  auto-stamping.

* `list_snapshots()` gains a `size_mb` column showing memory usage per snapshot.

* `compare_structure()`, `compare_keys()`: structural comparison helpers.

## Breaking Changes

* Renamed `commit_keyed()` to `stamp()`. The old name is soft-deprecated.

## Internal Changes

* Snapshot cache now stores full data frames (not just hashes), enabling
  cell-level drift comparison without re-reading source data.

* Cache reduced from 100 to 20 entries and adds a 100 MB soft memory cap.
  Eviction remains LRU-based but now considers both count and memory.

* All dplyr methods (`filter`, `mutate`, `select`, `arrange`, `rename`,
  `summarise`, `slice`, `distinct`, `group_by`, `ungroup`) now propagate
  snapshot references and watched state through transformations.

# keyed 0.1.1

## Breaking Changes

* Operations that break key uniqueness now **error** instead of warning.
  Previously, keyed would warn and silently remove the key. Now it stops
  with an error, requiring explicit `unkey()` to proceed. This prevents
  silent data corruption.

## Improvements

* Added Codecov integration for test coverage tracking
* Improved README with problem-solution framing and Row UUIDs section
* Added CONTRIBUTING.md with contribution guidelines
* Expanded test suite to 90%+ coverage
* Fixed `find_duplicates()` to work with keyed data that has duplicates

# keyed 0.1.0

## Initial Release

### Key Definition

* `key()` / `unkey()`: Define and remove keys from data frames
* `has_key()` / `get_key_cols()` / `key_is_valid()`: Query key status
* Keys survive dplyr transformations (filter, mutate, arrange, etc.)

### Assumption Checks

* `lock_unique()`: Verify column uniqueness
* `lock_no_na()`: Check for missing values
* `lock_complete()`: Ensure expected values are present
* `lock_coverage()`: Validate reference coverage
* `lock_nrow()`: Check row count bounds

### Join Diagnostics

* `diagnose_join()`: Analyze join cardinality before executing
* Optional integration with joinspy for enhanced diagnostics

### Row Identity

* `add_id()` / `remove_id()`: Add/remove stable UUIDs
* `has_id()` / `get_id()`: Query ID status
* `extend_id()`: Fill missing IDs after binding
* `make_id()`: Create composite IDs from columns
* `bind_id()`: Combine data with ID handling
* `check_id()` / `check_id_disjoint()`: Validate ID integrity
* `compare_ids()`: Detect lost/gained rows

### Drift Detection

* `commit_keyed()`: Commit reference snapshot
* `check_drift()`: Detect changes from snapshot
* `list_snapshots()` / `clear_snapshot()` / `clear_all_snapshots()`: Manage snapshots

### Diagnostics

* `key_status()`: Quick status summary
* `summary.keyed_df()`: Detailed summary method
* `compare_structure()`: Compare schema between data frames
* `compare_keys()`: Compare key values between datasets
* `find_duplicates()`: Locate duplicate key values
