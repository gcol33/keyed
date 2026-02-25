# Deprecated Functions — Removal Timeline

Current CRAN version: **0.1.3** Submitting to CRAN: **0.2.0**

## CRAN Policy

CRAN has **no explicit timeline** for removing deprecated functions. The
community convention is **at least 6 months** of soft-deprecation before
removal, longer for popular packages. The only hard rule is: changes
that break reverse dependencies must be coordinated with CRAN
maintainers in advance. Since keyed currently has zero reverse deps,
removal is at our discretion after a reasonable grace period.

Sources: - [CRAN Repository
Policy](https://cran.r-project.org/web/packages/policies.html) - [Posit
Community
discussion](https://forum.posit.co/t/when-can-i-remove-a-deprecated-function-from-a-package/9707) -
[R Packages (2e) — Lifecycle](https://r-pkgs.org/lifecycle.html)

## Deprecations (land with 0.2.0)

| Function | Replacement | Deprecated in | CRAN release | Earliest removal |
|----|----|----|----|----|
| [`commit_keyed()`](https://gillescolling.com/keyed/reference/stamp.md) | [`stamp()`](https://gillescolling.com/keyed/reference/stamp.md) | 0.2.0 | Pending | TBD + 6 months |

## Timeline

### `commit_keyed()` → `stamp()`

- **0.1.0–0.1.3** (CRAN):
  [`commit_keyed()`](https://gillescolling.com/keyed/reference/stamp.md)
  is the only snapshot function.
- **0.2.0** (internal): Soft-deprecated with
  [`lifecycle::deprecate_warn()`](https://lifecycle.r-lib.org/reference/deprecate_soft.html).
  Ships to CRAN with **0.2.0**. Users see a warning once per session
  pointing to
  [`stamp()`](https://gillescolling.com/keyed/reference/stamp.md).
- **~6 months after 0.2.0 CRAN acceptance**: Can escalate to
  `deprecate_stop()` or remove entirely.

**Current status:** 0.2.0 not yet on CRAN. Update this file with the
actual CRAN acceptance date once published, then start the countdown.

## Removal Checklist

When removing a deprecated function:

1.  Confirm soft-deprecated for 6+ months on CRAN
2.  Check reverse dependencies (`revdepcheck::revdep_check()`)
3.  Optionally escalate to `deprecate_stop()` for one release first
4.  Remove function from `R/` source
5.  Remove from NAMESPACE (happens automatically via roxygen)
6.  Delete any orphaned `.Rd` man page
7.  Update NEWS.md with “Removed” entry
8.  Run `R CMD check` to confirm clean removal
