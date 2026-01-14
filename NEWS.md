# keyed 0.1.1

* Added Codecov integration for test coverage tracking
* Improved README with problem-solution framing in Quick Start
* Added CONTRIBUTING.md with contribution guidelines
* Expanded test suite to 90%+ coverage

# keyed 0.1.0

## Initial Release

### Key Definition

* `key()` / `unkey()`: Define and remove keys from data frames
* `has_key()` / `get_key_cols()` / `key_is_valid()`: Query key status
* Keys survive dplyr transformations (filter, mutate, arrange, etc.)
* Graceful degradation with warnings when key uniqueness breaks

### Assumption Checks

* `assume_unique()`: Verify column uniqueness
* `assume_no_na()`: Check for missing values
* `assume_complete()`: Ensure expected values are present
* `assume_coverage()`: Validate reference coverage
* `assume_nrow()`: Check row count bounds

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
