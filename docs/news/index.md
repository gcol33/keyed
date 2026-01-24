# Changelog

## keyed 0.1.1

- Added Codecov integration for test coverage tracking
- Improved README with problem-solution framing in Quick Start
- Added CONTRIBUTING.md with contribution guidelines
- Expanded test suite to 90%+ coverage

## keyed 0.1.0

### Initial Release

#### Key Definition

- [`key()`](https://gcol33.github.io/keyed/reference/key.md) /
  [`unkey()`](https://gcol33.github.io/keyed/reference/unkey.md): Define
  and remove keys from data frames
- [`has_key()`](https://gcol33.github.io/keyed/reference/has_key.md) /
  [`get_key_cols()`](https://gcol33.github.io/keyed/reference/get_key_cols.md)
  /
  [`key_is_valid()`](https://gcol33.github.io/keyed/reference/key_is_valid.md):
  Query key status
- Keys survive dplyr transformations (filter, mutate, arrange, etc.)
- Graceful degradation with warnings when key uniqueness breaks

#### Assumption Checks

- [`assume_unique()`](https://gcol33.github.io/keyed/reference/assume_unique.md):
  Verify column uniqueness
- [`assume_no_na()`](https://gcol33.github.io/keyed/reference/assume_no_na.md):
  Check for missing values
- [`assume_complete()`](https://gcol33.github.io/keyed/reference/assume_complete.md):
  Ensure expected values are present
- [`assume_coverage()`](https://gcol33.github.io/keyed/reference/assume_coverage.md):
  Validate reference coverage
- [`assume_nrow()`](https://gcol33.github.io/keyed/reference/assume_nrow.md):
  Check row count bounds

#### Join Diagnostics

- [`diagnose_join()`](https://gcol33.github.io/keyed/reference/diagnose_join.md):
  Analyze join cardinality before executing
- Optional integration with joinspy for enhanced diagnostics

#### Row Identity

- [`add_id()`](https://gcol33.github.io/keyed/reference/add_id.md) /
  [`remove_id()`](https://gcol33.github.io/keyed/reference/remove_id.md):
  Add/remove stable UUIDs
- [`has_id()`](https://gcol33.github.io/keyed/reference/has_id.md) /
  [`get_id()`](https://gcol33.github.io/keyed/reference/get_id.md):
  Query ID status
- [`extend_id()`](https://gcol33.github.io/keyed/reference/extend_id.md):
  Fill missing IDs after binding
- [`make_id()`](https://gcol33.github.io/keyed/reference/make_id.md):
  Create composite IDs from columns
- [`bind_id()`](https://gcol33.github.io/keyed/reference/bind_id.md):
  Combine data with ID handling
- [`check_id()`](https://gcol33.github.io/keyed/reference/check_id.md) /
  [`check_id_disjoint()`](https://gcol33.github.io/keyed/reference/check_id_disjoint.md):
  Validate ID integrity
- [`compare_ids()`](https://gcol33.github.io/keyed/reference/compare_ids.md):
  Detect lost/gained rows

#### Drift Detection

- [`commit_keyed()`](https://gcol33.github.io/keyed/reference/commit_keyed.md):
  Commit reference snapshot
- [`check_drift()`](https://gcol33.github.io/keyed/reference/check_drift.md):
  Detect changes from snapshot
- [`list_snapshots()`](https://gcol33.github.io/keyed/reference/list_snapshots.md)
  /
  [`clear_snapshot()`](https://gcol33.github.io/keyed/reference/clear_snapshot.md)
  /
  [`clear_all_snapshots()`](https://gcol33.github.io/keyed/reference/clear_all_snapshots.md):
  Manage snapshots

#### Diagnostics

- [`key_status()`](https://gcol33.github.io/keyed/reference/key_status.md):
  Quick status summary
- [`summary.keyed_df()`](https://gcol33.github.io/keyed/reference/summary.keyed_df.md):
  Detailed summary method
- [`compare_structure()`](https://gcol33.github.io/keyed/reference/compare_structure.md):
  Compare schema between data frames
- [`compare_keys()`](https://gcol33.github.io/keyed/reference/compare_keys.md):
  Compare key values between datasets
- [`find_duplicates()`](https://gcol33.github.io/keyed/reference/find_duplicates.md):
  Locate duplicate key values
