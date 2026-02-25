# CRAN Submission Comments

## Update

This is an update from 0.1.3 to 0.2.0. Key changes:

* New `watch()` / `unwatch()` for automatic drift detection: dplyr verbs
  auto-snapshot before executing on watched data frames
* `check_drift()` now returns cell-level diff reports (not just hash comparison)
* Snapshot cache stores full data frames with memory-aware eviction (20 entries,
  100 MB soft cap)
* All dplyr methods propagate snapshot and watched state

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

- Local: Windows 11, R 4.5.2
- GitHub Actions:
  - macOS-latest (R release)
  - windows-latest (R release)
  - ubuntu-latest (R devel, release, oldrel-1)

## Downstream dependencies

There are currently no downstream dependencies.
